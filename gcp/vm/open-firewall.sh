#!/usr/bin/env bash
# GCP Firewall — port 3000 kholo (browser/APK ke liye)
# Apne LOCAL PC se chalao (gcloud installed hona chahiye), SSH par nahi
#
# Usage:
#   bash gcp/vm/open-firewall.sh
#   bash gcp/vm/open-firewall.sh YOUR_PROJECT_ID

set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
RULE_NAME="skillplay-allow-3000"

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  echo "Project ID set karo: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "Project: $PROJECT_ID"
echo "Creating firewall rule: $RULE_NAME (TCP 3000)..."

gcloud compute firewall-rules create "$RULE_NAME" \
  --project="$PROJECT_ID" \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:3000 \
  --source-ranges=0.0.0.0/0 \
  --description="SkillPlay API port 3000" \
  2>/dev/null || \
gcloud compute firewall-rules update "$RULE_NAME" \
  --project="$PROJECT_ID" \
  --rules=tcp:3000 \
  --source-ranges=0.0.0.0/0

echo ""
echo "Firewall rule ready."
echo "Test: http://35.200.216.188:3000/health"
echo ""
echo "Agar ab bhi timeout — VM par check karo:"
echo "  cd ~/SkillsPlay && docker compose -f docker-compose.vm.yml ps"
echo "  curl http://localhost:3000/health"
