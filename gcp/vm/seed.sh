#!/usr/bin/env bash
# First-time database seed on VM
set -euo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$APP_DIR"

echo "Running migrations + seed..."
docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env exec backend \
  sh -c "npx prisma migrate deploy && npm run db:seed"

echo ""
echo "Seed complete!"
echo "  Admin: admin@skillplay.dev / Admin123!"
echo "  Demo:  demo@skillplay.dev / Demo1234!"
