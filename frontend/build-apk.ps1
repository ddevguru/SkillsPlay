# Flutter APK build (Windows)
# Fixes: broken PATH in some terminals (missing System32 / git / PowerShell)
# Usage: .\build-apk.ps1

$ErrorActionPreference = "Stop"

# Essential Windows + Flutter paths (prepend — do NOT strip system paths)
$essential = @(
    "C:\Windows\System32"
    "C:\Windows"
    "C:\Windows\System32\Wbem"
    "C:\Windows\System32\WindowsPowerShell\v1.0"
    "C:\flutter\bin"
    "C:\Program Files\Git\cmd"
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
)

$rest = ($env:PATH -split ';' | Where-Object {
    $_ -and $_ -notmatch 'dart-sdk' -and ($essential -notcontains $_)
}) -join ';'

$env:PATH = ($essential + $rest) -join ';'

Write-Host "Flutter: $(Get-Command flutter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)" -ForegroundColor Cyan
flutter --version

Push-Location $PSScriptRoot

Write-Host "Cleaning..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "Building APK (API: http://35.200.216.188:3000)..." -ForegroundColor Cyan
flutter build apk --release

Pop-Location

Write-Host ""
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
