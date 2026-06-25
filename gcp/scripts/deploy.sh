#!/usr/bin/env bash
# SkillPlay GCP — One-command deploy (Linux/macOS/Git Bash)
# Usage: ./deploy.sh YOUR_PROJECT_ID [region]

set -euo pipefail

PROJECT_ID="${1:?Usage: ./deploy.sh PROJECT_ID [region]}"
REGION="${2:-asia-south1}"
CORS_ORIGIN="${CORS_ORIGIN:-*}"
APP_NAME="skillplay"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== SkillPlay GCP Deploy ==="
echo "Project: $PROJECT_ID | Region: $REGION"

command -v gcloud >/dev/null || { echo "Install gcloud CLI"; exit 1; }
command -v terraform >/dev/null || { echo "Install Terraform"; exit 1; }

gcloud config set project "$PROJECT_ID"

gcloud services enable run.googleapis.com sqladmin.googleapis.com artifactregistry.googleapis.com \
  secretmanager.googleapis.com cloudbuild.googleapis.com iam.googleapis.com compute.googleapis.com

echo "--- Terraform: database & infra ---"
cd "$REPO_ROOT/gcp/terraform"

if [[ ! -f terraform.tfvars ]]; then
  cp terraform.tfvars.example terraform.tfvars
  sed -i.bak "s/your-gcp-project-id/$PROJECT_ID/" terraform.tfvars 2>/dev/null || \
    sed -i '' "s/your-gcp-project-id/$PROJECT_ID/" terraform.tfvars
fi

terraform init
terraform apply -var="project_id=$PROJECT_ID" -var="region=$REGION" -var="cors_origin=$CORS_ORIGIN" -auto-approve

CLOUDSQL=$(terraform output -raw cloud_sql_connection)

echo "--- Cloud Build: images & Cloud Run ---"
cd "$REPO_ROOT"
gcloud builds submit . \
  --config=gcp/cloudbuild.yaml \
  --substitutions="_REGION=$REGION,_REPO=${APP_NAME}-images,_APP_NAME=$APP_NAME,_CLOUDSQL_CONNECTION=$CLOUDSQL,_CORS_ORIGIN=$CORS_ORIGIN"

API_URL=$(gcloud run services describe "${APP_NAME}-api" --region="$REGION" --format='value(status.url)')

echo ""
echo "=== DEPLOY COMPLETE ==="
echo "API URL: $API_URL"
echo "Health:  $API_URL/health"
echo ""
echo "First-time seed:"
echo "  gcloud run jobs execute ${APP_NAME}-seed --region=$REGION --wait"
