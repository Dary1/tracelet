# Bottle SQS round-trip test using the isolated test queue (not the manual dev queue).
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File infra/scripts/bottle-sqs-test.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$EnvDir = Join-Path $Root "infra\terraform\environments\dev"

function Require-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing '$Name'."
    }
}

function New-TestHeaders {
    param(
        [Parameter(Mandatory = $true)][string]$GuestUserId,
        [switch]$IncludeContentType
    )

    $headers = @{
        'x-user-id' = $GuestUserId
        'x-tracelet-test-queue' = 'true'
    }
    if ($IncludeContentType) {
        $headers['Content-Type'] = 'application/json'
    }
    return $headers
}

function Compare-TracePoints($Sent, $Received) {
    if ($null -eq $Sent -or $null -eq $Received) {
        throw "Missing points payload"
    }
    if ($Sent.Count -ne $Received.Count) {
        throw "Point count mismatch (sent=$($Sent.Count) received=$($Received.Count))"
    }
    for ($i = 0; $i -lt $Sent.Count; $i++) {
        $s = $Sent[$i]
        $r = $Received[$i]
        if ([math]::Abs($s.x - $r.x) -gt 0.001) {
            throw "Point $i x mismatch (sent=$($s.x) received=$($r.x))"
        }
        if ([math]::Abs($s.y - $r.y) -gt 0.001) {
            throw "Point $i y mismatch (sent=$($s.y) received=$($r.y))"
        }
        if ($s.t -ne $r.t) {
            throw "Point $i t mismatch (sent=$($s.t) received=$($r.t))"
        }
    }
}

Require-Command terraform

Push-Location $EnvDir
try {
    $httpUrl = (terraform output -raw http_api_url).TrimEnd("/")
    $testQueueUrl = terraform output -raw bottle_test_queue_url
}
finally {
    Pop-Location
}

$senderId = [Guid]::NewGuid().ToString()
$receiverId = [Guid]::NewGuid().ToString()
$sentPoints = @(
    @{ x = 0.21; y = 0.31; t = 0 },
    @{ x = 0.41; y = 0.51; t = 50 },
    @{ x = 0.61; y = 0.71; t = 100 }
)

Write-Host "Bottle SQS round-trip test (test queue)" -ForegroundColor White
Write-Host "Sender:   $senderId" -ForegroundColor DarkGray
Write-Host "Receiver: $receiverId" -ForegroundColor DarkGray
Write-Host "Test queue: $testQueueUrl" -ForegroundColor DarkGray

Write-Host "`n[Deposit trace to test queue]" -ForegroundColor Cyan
$depositHeaders = New-TestHeaders -GuestUserId $senderId -IncludeContentType
$depositBody = @{
    payload = @{
        points = $sentPoints
    }
} | ConvertTo-Json -Depth 6

$depositResponse = Invoke-WebRequest -Uri "$httpUrl/bottles" -Method Post `
    -Headers $depositHeaders -Body $depositBody -UseBasicParsing
if ($depositResponse.StatusCode -ne 202) {
    throw "Expected 202 on deposit, got $($depositResponse.StatusCode)"
}

Write-Host "  PASS" -ForegroundColor Green

Write-Host "`n[Pull trace from test queue]" -ForegroundColor Cyan
$pullHeaders = New-TestHeaders -GuestUserId $receiverId -IncludeContentType
$pullResponse = Invoke-WebRequest -Uri "$httpUrl/bottles/pull" -Method Post `
    -Headers $pullHeaders -Body "{}" -UseBasicParsing
if ($pullResponse.StatusCode -ne 200) {
    throw "Expected 200 on pull, got $($pullResponse.StatusCode)"
}

$pullJson = $pullResponse.Content | ConvertFrom-Json
if ($pullJson.message -eq "No bottles available") {
    throw "Expected a bottle payload, got empty test queue"
}
if ($pullJson.senderUserId -ne $senderId) {
    throw "Expected sender $senderId, got $($pullJson.senderUserId)"
}

Compare-TracePoints -Sent $sentPoints -Received $pullJson.payload.points
Write-Host "  PASS (trace points match)" -ForegroundColor Green

Write-Host "`nBottle SQS round-trip test passed." -ForegroundColor Green
