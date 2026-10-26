#!/bin/sh
# =============================================================================
# Crée le compte administrateur Forgejo à partir de .env.
# À lancer une seule fois, après `make up`.
# =============================================================================
set -eu

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "Erreur : .env introuvable. Lancer make init." >&2; exit 1; }
get_env() { sed -n "s/^$1=//p" .env | tail -n 1; }

NAME=$(get_env FORGEJO_ADMIN_NAME)
EMAIL=$(get_env FORGEJO_ADMIN_EMAIL)
PASSWORD=$(get_env FORGEJO_ADMIN_PASSWORD)
[ -n "$NAME" ] || { echo "Erreur : FORGEJO_ADMIN_NAME est vide." >&2; exit 1; }
if [ "$NAME" = "admin" ]; then
    echo "Erreur : 'admin' est un nom réservé par Forgejo." >&2
    echo "Définir par exemple FORGEJO_ADMIN_NAME=username dans .env." >&2
    exit 1
fi

echo "→ création de l'utilisateur Forgejo $NAME"
docker compose exec -T -u git forgejo forgejo admin user create \
    --admin \
    --username "$NAME" \
    --email "$EMAIL" \
    --password "$PASSWORD" \
    --must-change-password=false
