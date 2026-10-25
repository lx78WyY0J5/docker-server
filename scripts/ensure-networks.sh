#!/bin/sh
# =============================================================================
# Crée les réseaux Docker externes déclarés dans .env.
# Les noms sont résolus comme le fait Docker Compose (DOMAIN_NAME, TLD, …).
# =============================================================================
set -eu

cd "$(dirname "$0")/.."
ENV_FILE=${ENV_FILE:-.env}

[ -f "$ENV_FILE" ] || {
    echo "Erreur : $ENV_FILE introuvable. Lancer make init." >&2
    exit 1
}

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "Erreur : Docker est introuvable ou inaccessible." >&2
    echo "  - vérifier que le service Docker tourne ;" >&2
    echo "  - vérifier que votre utilisateur est dans le groupe docker" >&2
    echo "    (se déconnecter/reconnecter après 'usermod -aG docker \$USER')." >&2
    exit 1
fi

# Docker Compose résout les variables du .env (ex: ${DOMAIN_NAME}_proxy).
ENV_DUMP=$(docker compose --env-file "$ENV_FILE" config --environment)

get_env() {
    printf '%s\n' "$ENV_DUMP" | sed -n "s/^$1=//p" | tail -n 1
}

DOMAIN_NAME=$(get_env DOMAIN_NAME)
[ -n "$DOMAIN_NAME" ] || {
    echo "Erreur : DOMAIN_NAME vide dans $ENV_FILE." >&2
    exit 1
}

PROXY_NETWORK=$(get_env PROXY_NETWORK)
PROXY_NETWORK=${PROXY_NETWORK:-${DOMAIN_NAME}_proxy}
DB_ADMIN_NETWORK=$(get_env DB_ADMIN_NETWORK)
DB_ADMIN_NETWORK=${DB_ADMIN_NETWORK:-${DOMAIN_NAME}_db_admin}
MINECRAFT_NETWORK=$(get_env MINECRAFT_NETWORK)
MINECRAFT_NETWORK=${MINECRAFT_NETWORK:-${DOMAIN_NAME}_minecraft_internal}

ensure_network() {
    name=$1
    shift
    if ! docker network inspect "$name" >/dev/null 2>&1; then
        docker network create "$@" "$name" >/dev/null
        echo "→ réseau Docker créé : $name"
    fi
}

ensure_network "$PROXY_NETWORK"
ensure_network "$DB_ADMIN_NETWORK" --internal
ensure_network "$MINECRAFT_NETWORK" --internal
