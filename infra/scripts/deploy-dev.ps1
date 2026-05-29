# Tracelet dev deploy — ap-northeast-1 (Tokyo)
#
# Prerequisites:
#   1. AWS CLI configured:  aws configure
#      or SSO:               aws configure sso
#   2. Terraform >= 1.5
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File infra/scripts/deploy-dev.ps1
#   powershell -ExecutionPolicy Bypass -File infra/scripts/deploy-dev.ps1 -PlanOnly

param(
    [switch]$PlanOnly,
    [switch]$SkipInit,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$EnvDir = Join-Path $Root "infra\terraform\environments\dev"

function Require-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing '$Name'. Install it and reopen the terminal.`n  Terraform: winget install Hashicorp.Terraform`n  AWS CLI:   winget install Amazon.AWSCLI"
    }
}

function Refresh-SessionPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Refresh-SessionPath
Require-Command terraform
Require-Command aws

Write-Host "Checking AWS credentials..." -ForegroundColor Cyan
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
Write-Host "  Account: $($identity.Account)"
Write-Host "  ARN:     $($identity.Arn)"

if (-not (Test-Path (Join-Path $EnvDir "terraform.tfvars"))) {
    Copy-Item (Join-Path $EnvDir "terraform.tfvars.example") (Join-Path $EnvDir "terraform.tfvars")
    Write-Host "Created terraform.tfvars from example." -ForegroundColor Yellow
}

Push-Location $EnvDir
try {
    if (-not $SkipInit) {
        Write-Host "`nterraform init..." -ForegroundColor Cyan
        terraform init
    }

    Write-Host "`nterraform plan..." -ForegroundColor Cyan
    terraform plan -out=tfplan

    if ($PlanOnly) {
        Write-Host "`nPlan saved to tfplan. Run without -PlanOnly to apply." -ForegroundColor Green
        return
    }

    Write-Host "`nterraform apply..." -ForegroundColor Cyan
    terraform apply tfplan

    Write-Host "`nOutputs:" -ForegroundColor Green
    terraform output
}
finally {
    Pop-Location
}

if (-not $PlanOnly -and -not $SkipTests) {
    Write-Host "`nRunning automated smoke tests..." -ForegroundColor Cyan
    & (Join-Path $Root "infra\scripts\smoke-test-dev.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke tests failed"
    }
}
elseif (-not $PlanOnly) {
    Write-Host "`nSkipped smoke tests (-SkipTests). Run: powershell -ExecutionPolicy Bypass -File infra/scripts/smoke-test-dev.ps1" -ForegroundColor Yellow
}
else {
    Write-Host "`nPlan only — skipped apply and smoke tests." -ForegroundColor Green
}
