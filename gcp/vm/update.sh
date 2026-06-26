#!/usr/bin/env bash
# Pull latest code and redeploy on VM
set -euo pipefail

if [ -d "$HOME/SkillsPlay" ]; then
  APP_DIR="$HOME/SkillsPlay"
elif [ -d "/opt/skillplay" ]; then
  APP_DIR="/opt/skillplay"
else
  APP_DIR="${APP_DIR:-$HOME/SkillsPlay}"
fi

cd "$APP_DIR"
echo "Deploying from: $APP_DIR"

git pull origin main 2>/dev/null || git pull 2>/dev/null || echo "No git remote — skipping pull"

docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env up -d --build

echo "Running migrations..."
docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env exec -T backend \
  sh -c "npx prisma migrate deploy" 2>/dev/null || true

echo "Redeploy complete. Test: curl http://localhost:3000/health"
