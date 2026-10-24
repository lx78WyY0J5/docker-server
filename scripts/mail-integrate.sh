#!/bin/sh
# Intègre un override Traefik dans MAILCOW_DIR pour que les mail ne soit pas envoyés depuis le mailcow.

if [ ! -d "$(dirname "$0")" ]; then
    echo "Error : scripts/mail-integrate.sh doit être appelé depuis ./scripts/" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Get the domain from .env
DOMAIN_NAME=$(get_env DOMAIN_NAME) || echo "localhost"
TLD=$(get_env TLD) || echo ".fr"

# Generate Traefik override YAML
cat > "$(dirname "$ENV_FILE")/mail-overrides.yml" <<EOF
include:
  - $ENV_FILE
EOF

echo "→ mail-integrate.sh : override generated (domain: ${DOMAIN_NAME}${TLD})"
