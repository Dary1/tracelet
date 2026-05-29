# Ensures a confirmed Cognito user exists and returns an ID token for smoke tests.
# Requires IAM permission for cognito-idp:Admin* on the dev user pool.
#
# Dot-source from smoke-test-dev.ps1:
#   . (Join-Path $PSScriptRoot "lib\cognito-smoke-auth.ps1")

$script:TraceletSmokeDefaults = @{
    Email    = 'tracelet-smoke-test@tracelet.dev'
    Password = 'TraceletSmoke1'
}

function Get-TraceletSmokeCredentials {
    param(
        [string]$Email = $env:TRACELET_SMOKE_EMAIL,
        [string]$Password = $env:TRACELET_SMOKE_PASSWORD
    )

    if ([string]::IsNullOrWhiteSpace($Email)) {
        $Email = $script:TraceletSmokeDefaults.Email
    }
    if ([string]::IsNullOrWhiteSpace($Password)) {
        $Password = $script:TraceletSmokeDefaults.Password
    }

    return [PSCustomObject]@{
        Email    = $Email.Trim()
        Password = $Password
    }
}

function Invoke-AwsCli {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$AwsCommand
    )

    $output = & aws @AwsCommand 2>&1
    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = "aws exited with code $LASTEXITCODE"
        }
        throw $message
    }
    return $output
}

function Test-CognitoUserExists {
    param(
        [Parameter(Mandatory = $true)][string]$UserPoolId,
        [Parameter(Mandatory = $true)][string]$Region,
        [Parameter(Mandatory = $true)][string]$Email
    )

    aws cognito-idp admin-get-user `
        --user-pool-id $UserPoolId `
        --username $Email `
        --region $Region `
        --output json 2>$null | Out-Null

    return ($LASTEXITCODE -eq 0)
}

function Ensure-TraceletSmokeUser {
    param(
        [Parameter(Mandatory = $true)][string]$UserPoolId,
        [Parameter(Mandatory = $true)][string]$Region,
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$Password
    )

    if (-not (Test-CognitoUserExists -UserPoolId $UserPoolId -Region $Region -Email $Email)) {
        Invoke-AwsCli cognito-idp admin-create-user `
            --user-pool-id $UserPoolId `
            --username $Email `
            --user-attributes `
                "Name=email,Value=$Email" `
                "Name=email_verified,Value=true" `
            --message-action SUPPRESS `
            --region $Region `
            --output json | Out-Null
    }

    Invoke-AwsCli cognito-idp admin-set-user-password `
        --user-pool-id $UserPoolId `
        --username $Email `
        --password $Password `
        --permanent `
        --region $Region `
        --output json | Out-Null
}

function Get-TraceletSmokeIdToken {
    param(
        [Parameter(Mandatory = $true)][string]$UserPoolId,
        [Parameter(Mandatory = $true)][string]$ClientId,
        [Parameter(Mandatory = $true)][string]$Region,
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$Password
    )

    Ensure-TraceletSmokeUser `
        -UserPoolId $UserPoolId `
        -Region $Region `
        -Email $Email `
        -Password $Password

    $authJson = Invoke-AwsCli cognito-idp admin-initiate-auth `
        --user-pool-id $UserPoolId `
        --client-id $ClientId `
        --auth-flow ADMIN_NO_SRP_AUTH `
        --auth-parameters "USERNAME=$Email,PASSWORD=$Password" `
        --region $Region `
        --output json

    $auth = $authJson | ConvertFrom-Json
    $token = $auth.AuthenticationResult.IdToken
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw 'Cognito admin-initiate-auth did not return an IdToken'
    }

    return $token
}

function New-TraceletAuthHeaders {
    param(
        [Parameter(Mandatory = $true)][string]$IdToken,
        [switch]$IncludeContentType
    )

    $headers = @{
        Authorization = "Bearer $IdToken"
    }
    if ($IncludeContentType) {
        $headers['Content-Type'] = 'application/json'
    }
    return $headers
}

function Get-SqsApproximateMessageCount {
    param(
        [Parameter(Mandatory = $true)][string]$QueueUrl,
        [Parameter(Mandatory = $true)][string]$Region
    )

    $attrsJson = Invoke-AwsCli sqs get-queue-attributes `
        --queue-url $QueueUrl `
        --attribute-names ApproximateNumberOfMessages `
        --region $Region `
        --output json

    $attrs = $attrsJson | ConvertFrom-Json
    return [int]$attrs.Attributes.ApproximateNumberOfMessages
}
