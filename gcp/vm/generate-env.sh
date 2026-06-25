#!/usr/bin/env bash
# Generate secure secrets into gcp/vm/.env
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${DIR}/.env"

[[ -f "$ENV_FILE" ]] && cp "$ENV_FILE" "${ENV_FILE}.bak"

DB_PASS=$(openssl rand -hex 16)
JWT1=$(openssl rand -hex 32)
JWT2=$(openssl rand -hex 32)

cat > "$ENV_FILE" << EOF
POSTGRES_USER=skillplay
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_DB=skillplay

API_PORT=3000
CORS_ORIGIN=*

JWT_SECRET=${JWT1}
JWT_REFRESH_SECRET=${JWT2}

MOCK_PAYMENTS=true
FREE_PLAYS_PER_TOPIC=10
EOF

chmod 600 "$ENV_FILE"
echo "Created ${ENV_FILE} with random secrets"
