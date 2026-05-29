# Build Tracelet and install on connected handsets (no USB-debug setup here).
#
# Targets (edit if your device ids change):
#   d603551e02a0      — 23076RA4BR
#   STP0219C04001863   — MAR LX2J
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/build-install-devices.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/build-install-devices.ps1 -Debug
#   powershell -ExecutionPolicy Bypass -File scripts/build-install-devices.ps1 -SkipBuild

param(
    [switch]$Debug,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

$DeviceIds = @(
    'd603551e02a0',
    'STP0219C04001863'
)

function Refresh-SessionPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Require-Flutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "flutter not found on PATH"
    }
}

function Test-DeviceConnected($DeviceId) {
    $output = flutter devices 2>&1 | Out-String
    return $output -match [regex]::Escape($DeviceId)
}

Refresh-SessionPath
Require-Flutter
Push-Location $Root
try {
    Write-Host "Tracelet — build & install to $($DeviceIds.Count) devices" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($Debug) { 'debug' } else { 'release' })" -ForegroundColor DarkGray

    $missing = @()
    foreach ($id in $DeviceIds) {
        if (-not (Test-DeviceConnected $id)) {
            $missing += $id
        }
    }
    if ($missing.Count -gt 0) {
        throw "Device(s) not visible to Flutter: $($missing -join ', '). Run: flutter devices"
    }

    flutter pub get

    if (-not $SkipBuild) {
        if ($Debug) {
            Write-Host "`nBuilding debug APK..." -ForegroundColor Cyan
            flutter build apk --debug
        }
        else {
            Write-Host "`nBuilding release APK..." -ForegroundColor Cyan
            flutter build apk --release
        }
    }
    else {
        Write-Host "`nSkipping build (-SkipBuild)" -ForegroundColor DarkGray
    }

    $installArgs = @('install')
    if ($Debug) { $installArgs += '--debug' } else { $installArgs += '--release' }

    foreach ($id in $DeviceIds) {
        Write-Host "`nInstalling on $id ..." -ForegroundColor Cyan
        & flutter @installArgs -d $id
        if ($LASTEXITCODE -ne 0) {
            throw "flutter install failed for $id (exit $LASTEXITCODE)"
        }
        Write-Host "  OK $id" -ForegroundColor Green
    }

    Write-Host "`nInstalled on all devices." -ForegroundColor Green
}
finally {
    Pop-Location
}
