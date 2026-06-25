#!/usr/bin/env bash
# Run ONCE on GCP VM via SSH — installs Docker and prepares SkillPlay
# Usage: curl ... | bash   OR   bash gcp/vm/install.sh
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/skillplay}"
REPO_URL="${REPO_URL:-}"

echo "=== SkillPlay VM Install ==="

# ── 1. System packages ──
if command -v apt-get &>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq git curl openssl
elif command -v yum &>/dev/null; then
  sudo yum install -y git curl openssl
fi

# ── 2. Docker ──
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
fi

# docker compose plugin
if ! docker compose version &>/dev/null; then
  echo "Docker Compose plugin missing — install Docker CE latest"
  exit 1
fi

# ── 3. App code ──
if [[ -n "$REPO_URL" ]]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown "$USER:$USER" "$APP_DIR"
  if [[ -d "$APP_DIR/.git" ]]; then
    cd "$APP_DIR" && git pull
  else
    git clone "$REPO_URL" "$APP_DIR"
  fi
else
  # Code already uploaded / cloned manually
  APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
  echo "Using existing code at: $APP_DIR"
fi

cd "$APP_DIR"

# ── 4. Environment secrets ──
if [[ ! -f gcp/vm/.env ]]; then
  bash gcp/vm/generate-env.sh
  echo ""
  echo ">>> Edit gcp/vm/.env if you need custom CORS_ORIGIN <<<"
fi

# ── 5. Firewall hint (GCP) ──
echo ""
echo "GCP Firewall: allow TCP port 3000 (or 80 if using nginx)"
echo "  gcloud compute firewall-rules create skillplay-api --allow=tcp:3000 --target-tags=skillplay"

echo ""
echo "=== Install done. Next: bash gcp/vm/start.sh ==="
