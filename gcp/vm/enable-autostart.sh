#!/usr/bin/env bash
# VM reboot par backend AUTO start — ek baar chalao, phir SSH ki zaroorat nahi
# Usage: cd ~/SkillsPlay && bash gcp/vm/enable-autostart.sh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SERVICE_NAME="skillplay"
UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ ! -f "${APP_DIR}/gcp/vm/.env" ]]; then
  echo "Pehle: bash gcp/vm/generate-env.sh && bash gcp/vm/start.sh"
  exit 1
fi

echo "=== Enabling auto-start on boot ==="
echo "App dir: ${APP_DIR}"

# Docker khud boot par start ho
sudo systemctl enable docker

# Systemd service — VM restart par sab containers up
sudo tee "$UNIT_FILE" > /dev/null << EOF
[Unit]
Description=SkillPlay (Docker Compose)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env up -d
ExecStop=/usr/bin/docker compose -f docker-compose.vm.yml --env-file gcp/vm/.env stop
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"

echo ""
echo "Done! Ab VM restart hone par backend apne aap chalega."
echo ""
echo "Useful commands (SSH optional):"
echo "  sudo systemctl status ${SERVICE_NAME}"
echo "  sudo systemctl restart ${SERVICE_NAME}"
echo "  docker compose -f docker-compose.vm.yml ps"
