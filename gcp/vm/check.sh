#!/usr/bin/env bash
# VM par backend chal raha hai ya nahi — quick diagnose
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$APP_DIR"

echo "=== SkillPlay VM Health Check ==="

echo ""
echo "1. Docker containers:"
docker compose -f docker-compose.vm.yml ps 2>/dev/null || echo "   docker compose not running — run: bash gcp/vm/start.sh"

echo ""
echo "2. Local health (VM ke andar):"
if curl -sf http://localhost:3000/health; then
  echo ""
  echo "   OK — backend VM par chal raha hai"
else
  echo "   FAIL — backend nahi chal raha"
  echo "   Fix: bash gcp/vm/start.sh"
  exit 1
fi

echo ""
echo "3. External IP:"
EXT=$(curl -4 -sf ifconfig.me 2>/dev/null || echo "unknown")
echo "   $EXT"
echo "   Browser test: http://${EXT}:3000/health"
echo ""
echo "4. Agar browser timeout — GCP Firewall port 3000 kholo:"
echo "   Apne PC se: bash gcp/vm/open-firewall.sh"
