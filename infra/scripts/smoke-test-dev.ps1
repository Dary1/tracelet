# Smoke tests for tracelet dev stack (run after deploy-dev.ps1)
#
# Guest API calls use x-user-id (matches the mobile app's default guest mode).
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File infra/scripts/smoke-test-dev.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$EnvDir = Join-Path $Root "infra\terraform\environments\dev"

. (Join-Path $PSScriptRoot "lib\cognito-smoke-auth.ps1")

function Require-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing '$Name'."
    }
}

function Refresh-SessionPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function New-GuestHeaders {
    param(
        [Parameter(Mandatory = $true)][string]$GuestUserId,
        [switch]$IncludeContentType
    )

    $headers = @{ 'x-user-id' = $GuestUserId }
    if ($IncludeContentType) {
        $headers['Content-Type'] = 'application/json'
    }
    return $headers
}

Refresh-SessionPath
Require-Command terraform
Require-Command aws

Push-Location $EnvDir
try {
    $httpUrl = (terraform output -raw http_api_url).TrimEnd("/")
    $wsUrl = terraform output -raw websocket_api_url
    $queueUrl = terraform output -raw bottle_queue_url
    $testQueueUrl = (terraform output -raw bottle_test_queue_url).Trim()
    $tables = terraform output -json dynamodb_table_names | ConvertFrom-Json
    $region = terraform output -raw aws_region
    $poolId = terraform output -raw cognito_user_pool_id
    $clientId = terraform output -raw cognito_user_pool_client_id
}
finally {
    Pop-Location
}

$guestUserId = [Guid]::NewGuid().ToString()
$passed = 0
$failed = 0

function Test-Step($Name, [scriptblock]$Block) {
    Write-Host "`n[$Name]" -ForegroundColor Cyan
    try {
        & $Block
        Write-Host "  PASS" -ForegroundColor Green
        $script:passed++
    }
    catch {
        Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "Tracelet dev smoke tests (region: $region)" -ForegroundColor White
Write-Host "Guest user: $guestUserId" -ForegroundColor DarkGray

Test-Step "AWS credentials valid" {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($identity.Account)) {
        throw "Could not resolve AWS account"
    }
}

Test-Step "GET /settings as guest (x-user-id)" {
    $headers = New-GuestHeaders -GuestUserId $guestUserId
    $response = Invoke-WebRequest -Uri "$httpUrl/settings" -Method Get `
        -Headers $headers -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        throw "Expected 200, got $($response.StatusCode)"
    }
    $json = $response.Content | ConvertFrom-Json
    if ($null -eq $json.defaultPenColor) {
        throw "Response missing defaultPenColor"
    }
}

Test-Step "PUT /settings stores defaultPenColor for guest" {
    $headers = New-GuestHeaders -GuestUserId $guestUserId -IncludeContentType
    $body = @{ defaultPenColor = "#34C759"; muted = $false } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$httpUrl/settings" -Method Put `
        -Headers $headers -Body $body -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        throw "Expected 200, got $($response.StatusCode)"
    }
    $json = $response.Content | ConvertFrom-Json
    if ($json.defaultPenColor -ne "#34C759") {
        throw "Expected #34C759, got $($json.defaultPenColor)"
    }
}

Test-Step "POST /bottles deposits to SQS as guest" {
    $before = Get-SqsApproximateMessageCount -QueueUrl $queueUrl -Region $region
    $marker = [Guid]::NewGuid().ToString()
    $headers = New-GuestHeaders -GuestUserId $guestUserId -IncludeContentType
    $body = @{
        payload = @{
            smokeMarker = $marker
            points = @(
                @{ x = 0.1; y = 0.2; t = 0 }
            )
        }
    } | ConvertTo-Json -Depth 6

    $response = Invoke-WebRequest -Uri "$httpUrl/bottles" -Method Post `
        -Headers $headers -Body $body -UseBasicParsing
    if ($response.StatusCode -ne 202) {
        throw "Expected 202, got $($response.StatusCode)"
    }

    $after = Get-SqsApproximateMessageCount -QueueUrl $queueUrl -Region $region
    if ($after -le $before) {
        throw "Expected SQS message count to increase (before=$before after=$after)"
    }
}

Test-Step "POST /bottles/pull returns a bottle" {
    $headers = New-GuestHeaders -GuestUserId $guestUserId -IncludeContentType
    $response = Invoke-WebRequest -Uri "$httpUrl/bottles/pull" -Method Post `
        -Headers $headers -Body "{}" -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        throw "Expected 200, got $($response.StatusCode)"
    }
    $json = $response.Content | ConvertFrom-Json
    if ($json.message -eq "No bottles available") {
        throw "Expected a bottle payload, got empty ocean"
    }
    if ($null -eq $json.payload) {
        throw "Pull response missing payload"
    }
}

Test-Step "Cognito admin auth still works (social sign-in infra)" {
    $creds = Get-TraceletSmokeCredentials
    $token = Get-TraceletSmokeIdToken `
        -UserPoolId $poolId `
        -ClientId $clientId `
        -Region $region `
        -Email $creds.Email `
        -Password $creds.Password
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "Missing IdToken from admin auth"
    }
}

Test-Step "Google identity provider configured in Cognito" {
    $providers = aws cognito-idp list-identity-providers `
        --user-pool-id $poolId `
        --region $region `
        --output json | ConvertFrom-Json
    $google = $providers.Providers | Where-Object { $_.ProviderName -eq "Google" }
    if ($null -eq $google) {
        throw "Google provider not found in Cognito user pool"
    }
}

Test-Step "DynamoDB users table readable" {
    $null = aws dynamodb describe-table --table-name $tables.users --region $region --output json | ConvertFrom-Json
}

Test-Step "SQS bottle queue exists" {
    $attrs = aws sqs get-queue-attributes --queue-url $queueUrl --attribute-names All --region $region --output json | ConvertFrom-Json
    if ($attrs.Attributes.FifoQueue -ne "true") {
        throw "Expected FIFO queue"
    }
    if ($attrs.Attributes.MessageRetentionPeriod -ne "86400") {
        throw "Expected 86400s retention, got $($attrs.Attributes.MessageRetentionPeriod)"
    }
}

Test-Step "SQS bottle test queue exists" {
    if ([string]::IsNullOrWhiteSpace($testQueueUrl)) {
        throw "Missing bottle_test_queue_url output"
    }
    $attrs = aws sqs get-queue-attributes --queue-url $testQueueUrl --attribute-names All --region $region --output json | ConvertFrom-Json
    if ($attrs.Attributes.FifoQueue -ne "true") {
        throw "Expected FIFO test queue"
    }
}

Test-Step "Cognito user pool reachable" {
    $pool = aws cognito-idp describe-user-pool --user-pool-id $poolId --region $region --output json | ConvertFrom-Json
    if ($pool.UserPool.Id -ne $poolId) {
        throw "Unexpected pool id: $($pool.UserPool.Id)"
    }
}

Test-Step "WebSocket API reachable (HTTP upgrade probe)" {
    $probe = $wsUrl -replace "^wss://", "https://"
    try {
        Invoke-WebRequest -Uri $probe -Method Get -UseBasicParsing -TimeoutSec 10 | Out-Null
    }
    catch {
        if ($_.Exception.Response -eq $null) {
            throw $_
        }
    }
}

Write-Host "`n--- Results: $passed passed, $failed failed ---" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 }
