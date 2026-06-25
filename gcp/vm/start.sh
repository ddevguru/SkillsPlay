#!/usr/bin/env bash
# Start / rebuild all services on VM
set -euo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$APP_DIR"

echo "Working directory: $APP_DIR"

if [[ ! -f gcp/vm/.env ]]; then
  echo "Missing gcp/vm/.env — run: bash gcp/vm/generate-env.sh"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source gcp/vm/.env
set +a

echo "=== Building & starting SkillPlay ==="
docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env up -d --build

echo "Waiting for backend health..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:${API_PORT:-3000}/health" &>/dev/null; then
    echo "Backend is healthy!"
    break
  fi
  sleep 3
done

echo ""
echo "=== Status ==="
docker compose -f docker-compose.vm.yml ps

echo ""
echo "API: http://$(curl -sf ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):${API_PORT:-3000}/health"

echo ""
echo ">>> Ek baar auto-start enable karo (reboot par khud chalega):"
echo "    bash gcp/vm/enable-autostart.sh"
