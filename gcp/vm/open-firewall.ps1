# GCP Firewall — port 3000 (Windows)
# Usage: .\open-firewall.ps1
#        .\open-firewall.ps1 -ProjectId "your-project-id"

param([string]$ProjectId = "")

if (-not $ProjectId) {
    $ProjectId = gcloud config get-value project 2>$null
}
if (-not $ProjectId) {
    Write-Error "gcloud project set karo: gcloud config set project YOUR_PROJECT_ID"
}

$RuleName = "skillplay-allow-3000"
Write-Host "Opening TCP 3000 on project: $ProjectId"

gcloud compute firewall-rules create $RuleName `
    --project=$ProjectId `
    --direction=INGRESS `
    --network=default `
    --action=ALLOW `
    --rules=tcp:3000 `
    --source-ranges=0.0.0.0/0 `
    --description="SkillPlay API" 2>$null

if ($LASTEXITCODE -ne 0) {
    gcloud compute firewall-rules update $RuleName `
        --project=$ProjectId `
        --rules=tcp:3000 `
        --source-ranges=0.0.0.0/0
}

Write-Host ""
Write-Host "Test browser: http://35.200.216.188:3000/health" -ForegroundColor Green
