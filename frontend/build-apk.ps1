# Flutter APK build — GCP VM IP se connect (domain ki zaroorat nahi)
# Usage: .\build-apk.ps1
#    ya: .\build-apk.ps1 -ApiIp "35.200.216.188"

param(
    [string]$ApiIp = "35.200.216.188",
    [int]$ApiPort = 3000
)

$ApiUrl = "http://${ApiIp}:${ApiPort}"

Write-Host "Building APK with API: $ApiUrl" -ForegroundColor Cyan

Push-Location $PSScriptRoot

flutter pub get
flutter build apk --release `
    --dart-define=API_URL=$ApiUrl `
    --dart-define=WS_URL=$ApiUrl

Pop-Location

Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  frontend\build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""
Write-Host "Pehle phone browser se test karo: $ApiUrl/health"
