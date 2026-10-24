#!/bin/sh
# Installation et démarrage de KeeWeb.
set -eu

TLD=${TLD:-.fr}
DOMAIN_NAME=${DOMAIN_NAME:-Altherneum}

cat > "$CONFIG_DIR/.env" <<EOF
SESSION_DOMAIN=${DOMAIN_NAME}.${TLD}