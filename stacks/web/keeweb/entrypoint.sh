#!/bin/sh
# Installation et démarrage de KeeWeb.
set -eu

: "${DOMAIN:?DOMAIN manquant}"

cat > "$CONFIG_DIR/.env" <<EOF
SESSION_DOMAIN=${DOMAIN}