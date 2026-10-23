#!/bin/sh
# =============================================================================
# Crée le compte administrateur Forgejo à partir de .env.
# À lancer une seule fois, après `make up`.
# =============================================================================
set -eu

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "Erreur : .env introuvable. Lancer make init." >&2; exit 1; }
get_env() { sed -n "s/^$1=//p" .env | tail -n 1; }

echo "→ création de l'utilisateur Forgejo $(get_env FORGEJO_ADMIN_NAME)"
docker compose exec -T -u git forgejo forgejo admin user create \
    --admin \
    --username "$(get_env FORGEJO_ADMIN_NAME)" \
    --email "$(get_env FORGEJO_ADMIN_EMAIL)" \
    --password "$(get_env FORGEJO_ADMIN_PASSWORD)" \
    --must-change-password=false
