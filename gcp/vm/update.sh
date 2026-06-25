#!/usr/bin/env bash
# Pull latest code and redeploy on VM
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/skillplay}"
cd "$APP_DIR"

git pull origin main 2>/dev/null || git pull 2>/dev/null || echo "No git remote — skipping pull"

docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env up -d --build

echo "Redeploy complete."
