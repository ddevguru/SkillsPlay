# SkillPlay GCP — One-command deploy (PowerShell)
# Usage: .\deploy.ps1 -ProjectId "your-project-id"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Region = "asia-south1",
    [string]$CorsOrigin = "*",
    [switch]$SkipTerraform,
    [switch]$RunSeed
)

$ErrorActionPreference = "Stop"
$AppName = "skillplay"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

Write-Host "=== SkillPlay GCP Deploy ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectId | Region: $Region"

# 1. Check tools
foreach ($cmd in @("gcloud", "terraform")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd not found. Install Google Cloud SDK + Terraform first."
    }
}

# 2. Set project
gcloud config set project $ProjectId

# 3. Enable billing check
Write-Host "Enabling required APIs..."
gcloud services enable run.googleapis.com sqladmin.googleapis.com artifactregistry.googleapis.com `
    secretmanager.googleapis.com cloudbuild.googleapis.com iam.googleapis.com compute.googleapis.com `
    --project=$ProjectId

# 4. Terraform — creates Cloud SQL, database, secrets, Cloud Run skeleton
if (-not $SkipTerraform) {
    Write-Host "`n--- Terraform: Creating database & infrastructure ---" -ForegroundColor Yellow
    $TfDir = Join-Path $RepoRoot "gcp\terraform"
    Push-Location $TfDir

    if (-not (Test-Path "terraform.tfvars")) {
        Copy-Item "terraform.tfvars.example" "terraform.tfvars"
        (Get-Content "terraform.tfvars") -replace 'your-gcp-project-id', $ProjectId | Set-Content "terraform.tfvars"
        (Get-Content "terraform.tfvars") -replace 'asia-south1', $Region | Set-Content "terraform.tfvars"
        Write-Host "Created terraform.tfvars — edit cors_origin if needed"
    }

    terraform init
    terraform apply -var="project_id=$ProjectId" -var="region=$Region" -var="cors_origin=$CorsOrigin" -auto-approve

    $CloudSql = terraform output -raw cloud_sql_connection
    $SandboxUrl = terraform output -raw sandbox_url
    Pop-Location
} else {
    $CloudSql = gcloud sql instances list --format="value(connectionName)" --filter="name:$AppName-pg" --limit=1
    $SandboxUrl = gcloud run services describe "$AppName-sandbox" --region=$Region --format="value(status.url)" 2>$null
}

# 5. Cloud Build — build Docker images & deploy to Cloud Run
Write-Host "`n--- Cloud Build: Building & deploying containers ---" -ForegroundColor Yellow
Push-Location $RepoRoot

gcloud builds submit . `
    --config=gcp/cloudbuild.yaml `
    --substitutions="_REGION=$Region,_REPO=${AppName}-images,_APP_NAME=$AppName,_CLOUDSQL_CONNECTION=$CloudSql,_CORS_ORIGIN=$CorsOrigin"

Pop-Location

# 6. Get final URLs
$ApiUrl = gcloud run services describe "$AppName-api" --region=$Region --format="value(status.url)"
$SandboxFinal = gcloud run services describe "$AppName-sandbox" --region=$Region --format="value(status.url)"

Write-Host "`n=== DEPLOY COMPLETE ===" -ForegroundColor Green
Write-Host "API URL:     $ApiUrl"
Write-Host "Sandbox URL: $SandboxFinal (private — backend only)"
Write-Host "Health:      $ApiUrl/health"

# 7. Optional seed
if ($RunSeed) {
    Write-Host "`n--- Running database seed job ---" -ForegroundColor Yellow
    gcloud run jobs execute "$AppName-seed" --region=$Region --wait
    Write-Host "Seed complete. Admin: admin@skillplay.dev / Admin123!"
}

Write-Host "`nFlutter app:"
Write-Host "flutter run --dart-define=API_URL=$ApiUrl --dart-define=WS_URL=$ApiUrl"
Write-Host "`nAdmin panel (.env): VITE_API_URL=$ApiUrl"
