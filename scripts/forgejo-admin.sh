#!/bin/sh
# =============================================================================
# Crée le compte administrateur Forgejo à partir de .env.
# Appelé automatiquement par `make up` et `make up-service SERVICE=forgejo`.
# Peut aussi être lancé manuellement : make forgejo-admin.
# =============================================================================
set -eu

cd "$(dirname "$0")/.."
ENV_FILE=${ENV_FILE:-.env}
[ -f "$ENV_FILE" ] || { echo "Erreur : $ENV_FILE introuvable. Lancer make init." >&2; exit 1; }

# Docker Compose résout les variables du .env (ex: FORGEJO_ADMIN_NAME=${DOMAIN_NAME}).
ENV_DUMP=$(docker compose --env-file "$ENV_FILE" config --environment)
get_env() {
    printf '%s\n' "$ENV_DUMP" | sed -n "s/^$1=//p" | tail -n 1
}

NAME=$(get_env FORGEJO_ADMIN_NAME)
EMAIL=$(get_env FORGEJO_ADMIN_EMAIL)
PASSWORD=$(get_env FORGEJO_ADMIN_PASSWORD)
[ -n "$NAME" ] || { echo "Erreur : FORGEJO_ADMIN_NAME est vide." >&2; exit 1; }
[ -n "$EMAIL" ] || { echo "Erreur : FORGEJO_ADMIN_EMAIL est vide." >&2; exit 1; }
[ -n "$PASSWORD" ] || { echo "Erreur : FORGEJO_ADMIN_PASSWORD est vide." >&2; exit 1; }
if [ "$NAME" = "admin" ]; then
    echo "Erreur : 'admin' est un nom réservé par Forgejo." >&2
    echo "Définir par exemple FORGEJO_ADMIN_NAME=username dans .env." >&2
    exit 1
fi

# Attend que Forgejo et sa base soient prêts (utile juste après make up-service).
USER_LIST=""
READY=0
tries=0
while [ "$tries" -lt 60 ]; do
    if USER_LIST=$(docker compose --env-file "$ENV_FILE" exec -T -u git forgejo \
            forgejo admin user list 2>/dev/null); then
        READY=1
        break
    fi
    tries=$((tries + 1))
    sleep 2
done
if [ "$READY" -ne 1 ]; then
    echo "Erreur : Forgejo n'est pas prêt (admin user list)." >&2
    echo "Vérifier : make ps-service SERVICE=forgejo" >&2
    exit 1
fi

# Ne recrée pas le compte s'il existe déjà (script idempotent).
EXISTING_ADMIN=$(printf '%s\n' "$USER_LIST" \
    | awk -v name="$NAME" 'NR > 1 && $2 == name { print $5 }')
if [ -n "$EXISTING_ADMIN" ]; then
    if [ "$EXISTING_ADMIN" = "true" ]; then
        echo "→ l'utilisateur Forgejo $NAME existe déjà (admin)"
        exit 0
    fi
    echo "Erreur : l'utilisateur Forgejo $NAME existe déjà mais n'est pas admin." >&2
    exit 1
fi

echo "→ création de l'utilisateur Forgejo $NAME"
docker compose --env-file "$ENV_FILE" exec -T -u git forgejo forgejo admin user create \
    --admin \
    --username "$NAME" \
    --email "$EMAIL" \
    --password "$PASSWORD" \
    --must-change-password=false
