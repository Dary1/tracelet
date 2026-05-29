# Run all automated tests (no human interaction).
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/run-all-tests.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/run-all-tests.ps1 -SkipAws
#   powershell -ExecutionPolicy Bypass -File scripts/run-all-tests.ps1 -AwsOnly

param(
    [switch]$SkipAws,
    [switch]$AwsOnly
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$InfraScripts = Join-Path $Root "infra\scripts"

function Refresh-SessionPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Invoke-Step($Name, [scriptblock]$Block) {
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Refresh-SessionPath
Push-Location $Root
try {
    if (-not $AwsOnly) {
        Invoke-Step "Flutter unit tests" {
            flutter test
        }

        Invoke-Step "System trace validation" {
            dart run tool/validate_system_traces.dart
        }

        Invoke-Step "System trace diff check" {
            dart run tool/check_system_traces_diff.dart
        }
    }

    if (-not $SkipAws) {
        Invoke-Step "AWS dev smoke tests" {
            & (Join-Path $InfraScripts "smoke-test-dev.ps1")
        }

        Invoke-Step "AWS bottle SQS round-trip (test queue)" {
            & (Join-Path $InfraScripts "bottle-sqs-test.ps1")
        }
    }
    else {
        Write-Host "`nSkipping AWS smoke tests (-SkipAws)" -ForegroundColor DarkGray
    }
}
finally {
    Pop-Location
}

Write-Host "`nAll requested tests passed." -ForegroundColor Green
