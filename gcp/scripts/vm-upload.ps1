# Upload code to GCP VM and run install (from your Windows PC)
# Usage: .\vm-upload.ps1 -VmName skillplay-vm -Zone asia-south1-a

param(
    [Parameter(Mandatory = $true)]
    [string]$VmName,

    [string]$Zone = "asia-south1-a",
    [string]$RemotePath = "/opt/skillplay",
    [switch]$RunInstall
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

Write-Host "=== Upload SkillPlay to GCP VM ===" -ForegroundColor Cyan
Write-Host "VM: $VmName | Zone: $Zone"

# Create remote dir
gcloud compute ssh $VmName --zone=$Zone --command="sudo mkdir -p $RemotePath && sudo chown `$USER:`$USER $RemotePath"

# Upload (exclude heavy folders)
Write-Host "Uploading files (this may take a few minutes)..."
gcloud compute scp --recurse `
    "$RepoRoot\backend" `
    "$RepoRoot\sandbox" `
    "$RepoRoot\gcp" `
    "$RepoRoot\docker-compose.vm.yml" `
    "${VmName}:${RemotePath}/" `
    --zone=$Zone

Write-Host "Upload done." -ForegroundColor Green

if ($RunInstall) {
    Write-Host "Running install + start + seed on VM..."
    gcloud compute ssh $VmName --zone=$Zone --command="
        cd $RemotePath &&
        chmod +x gcp/vm/*.sh &&
        bash gcp/vm/install.sh &&
        bash gcp/vm/start.sh &&
        bash gcp/vm/seed.sh
    "
}

$Ip = gcloud compute instances describe $VmName --zone=$Zone --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "VM IP:  $Ip"
Write-Host "Health: http://${Ip}:3000/health"
Write-Host ""
Write-Host "SSH: gcloud compute ssh $VmName --zone=$Zone"
Write-Host "Then: cd $RemotePath && docker compose -f docker-compose.vm.yml ps"
