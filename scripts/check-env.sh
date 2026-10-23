#!/bin/sh
# Vérifie les variables indispensables avant `make up`.
# Ne lit que .env : aucun secret n'est affiché.
set -eu

cd "$(dirname "$0")/.."
ENV_FILE=${ENV_FILE:-.env}

if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : $ENV_FILE introuvable. Lancer make init." >&2
    exit 1
fi

get_env() {
    sed -n "s/^$1=//p" "$ENV_FILE" | tail -n 1
}

errors=0
fail() {
    printf 'Erreur : %s\n' "$*" >&2
    errors=$((errors + 1))
}
warn() {
    printf 'Attention : %s\n' "$*" >&2
}

require() {
    key=$1
    value=$(get_env "$key")
    case "$value" in
        ""|CHANGE_ME) fail "$key manquant ou encore égal à CHANGE_ME" ;;
    esac
}

# Variables réellement utilisées par Compose/les entrypoints.
for key in \
    DOMAIN ACME_EMAIL TZ \
    TRAEFIK_DASHBOARD_HOST TRAEFIK_DASHBOARD_USER TRAEFIK_DASHBOARD_PASSWORD \
    TRAEFIK_ACME_CA_SERVER TRAEFIK_LOG_LEVEL \
    PROXY_NETWORK DB_ADMIN_NETWORK MINECRAFT_NETWORK MAILCOW_DIR \
    PMA_ADMIN_USER PMA_ADMIN_PASSWORD PMA_HOSTS PMA_BLOWFISH_SECRET \
    PHP_DB_ROOT_PASSWORD PHP_DB_NAME PHP_DB_USER PHP_DB_PASSWORD \
    WEBSITE_ADMIN_PASSWORD \
    AZURIOM_VERSION AZURIOM_DB_ROOT_PASSWORD AZURIOM_DB_NAME AZURIOM_DB_USER \
    AZURIOM_DB_PASSWORD AZURIOM_APP_KEY AZURIOM_GAME AZURIOM_ADMIN_NAME \
    AZURIOM_ADMIN_EMAIL AZURIOM_ADMIN_PASSWORD AZURIOM_RESOURCE_PACK_URL \
    AZURIOM_MAIL_MAILER AZURIOM_MAIL_HOST AZURIOM_MAIL_PORT AZURIOM_MAIL_USERNAME \
    AZURIOM_MAIL_PASSWORD AZURIOM_MAIL_ENCRYPTION AZURIOM_MAIL_FROM_ADDRESS \
    FORGEJO_VERSION FORGEJO_DB_ROOT_PASSWORD FORGEJO_DB_NAME FORGEJO_DB_USER \
    FORGEJO_DB_PASSWORD FORGEJO_SECRET_KEY FORGEJO_INTERNAL_TOKEN \
    FORGEJO_LFS_JWT_SECRET FORGEJO_OAUTH2_JWT_SECRET FORGEJO_ADMIN_NAME \
    FORGEJO_ADMIN_EMAIL FORGEJO_ADMIN_PASSWORD FORGEJO_MAIL_ENABLED \
    FORGEJO_MAIL_HOST FORGEJO_MAIL_PORT FORGEJO_MAIL_USER FORGEJO_MAIL_PASSWORD \
    FORGEJO_MAIL_FROM CODE_SERVER_PASSWORD \
    KEEWEB_UI_USER KEEWEB_UI_PASSWORD KEEWEB_WEBDAV_USER KEEWEB_WEBDAV_PASSWORD \
    MINECRAFT_PORT MINECRAFT_LEVEL_NAME MINECRAFT_MAX_PLAYERS \
    MINECRAFT_MEMORY_HUB MINECRAFT_MEMORY_SURVIE MINECRAFT_MEMORY_CREATIF \
    MINECRAFT_MEMORY_ANARCHIE MINECRAFT_MEMORY_RPG MINECRAFT_MEMORY_SKYBLOCK \
    MINECRAFT_MEMORY_OPPRISON MINECRAFT_MEMORY_TEST VELOCITY_MEMORY \
    VELOCITY_SECRET VELOCITY_MOTD VELOCITY_ONLINE_MODE MINECRAFT_RCON_PASSWORD \
    DISCORD_BOT_NAME DISCORD_BOT_TOKEN
do
    require "$key"
done

DOMAIN=$(get_env DOMAIN)
case "$DOMAIN" in
    *://*|*/*|*' '*) fail "DOMAIN doit être un nom d'hôte sans http://, slash ni espace" ;;
esac

case "$(get_env ACME_EMAIL)" in
    *@*.*) ;;
    *) fail "ACME_EMAIL ne ressemble pas à une adresse e-mail" ;;
esac

case "$(get_env TRAEFIK_DASHBOARD_HOST)" in
    "$DOMAIN"|*."$DOMAIN") ;;
    *) warn "TRAEFIK_DASHBOARD_HOST n'est pas sous $DOMAIN (vérifier DNS/certificat)" ;;
esac

for key in AZURIOM_MAIL_HOST FORGEJO_MAIL_HOST; do
    value=$(get_env "$key")
    case "$value" in
        "$DOMAIN"|*."$DOMAIN") ;;
        *) warn "$key ($value) n'est pas sous $DOMAIN" ;;
    esac
done

case "$(get_env MINECRAFT_PORT)" in
    *[!0-9]*) fail "MINECRAFT_PORT doit être numérique" ;;
esac

GAME=$(get_env AZURIOM_GAME)
ONLINE=$(get_env VELOCITY_ONLINE_MODE)
case "$GAME" in
    mc-online|mc-offline) ;;
    *) fail "AZURIOM_GAME doit valoir mc-online ou mc-offline" ;;
esac
case "$ONLINE" in
    true|false) ;;
    *) fail "VELOCITY_ONLINE_MODE doit valoir true ou false" ;;
esac
case "$GAME:$ONLINE" in
    mc-online:true|mc-offline:false) ;;
    *) fail "AZURIOM_GAME=$GAME et VELOCITY_ONLINE_MODE=$ONLINE sont incohérents" ;;
esac

ADMIN_ID=$(printf '%s' "$(get_env AZURIOM_ADMIN_GAME_ID)" | tr -d '-' | tr 'A-F' 'a-f')
if [ "$GAME" = "mc-online" ]; then
    case "$ADMIN_ID" in
        ""|*[!0-9a-f]*) fail "AZURIOM_ADMIN_GAME_ID doit être un UUID hexadécimal (mode mc-online)" ;;
        *) [ "${#ADMIN_ID}" -eq 32 ] || fail "AZURIOM_ADMIN_GAME_ID doit contenir 32 caractères hexadécimaux" ;;
    esac
else
    [ -z "$ADMIN_ID" ] || warn "AZURIOM_ADMIN_GAME_ID est ignoré en mode mc-offline"
fi

case "$(get_env AZURIOM_APP_KEY)" in
    base64:*) ;;
    *) warn "AZURIOM_APP_KEY ne commence pas par base64: (vérifier make init)" ;;
esac

PMA_SECRET=$(get_env PMA_BLOWFISH_SECRET)
[ "${#PMA_SECRET}" -eq 32 ] || warn "PMA_BLOWFISH_SECRET ne fait pas 32 caractères"
VELOCITY_SECRET=$(get_env VELOCITY_SECRET)
[ "${#VELOCITY_SECRET}" -ge 32 ] || warn "VELOCITY_SECRET semble trop court"

# Réseaux externes créés par make init. Sans eux, le premier make up échoue.
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    for key in PROXY_NETWORK DB_ADMIN_NETWORK MINECRAFT_NETWORK; do
        net=$(get_env "$key")
        if [ -z "$net" ] || ! docker network inspect "$net" >/dev/null 2>&1; then
            fail "réseau Docker '$net' absent (lancer make init)"
        fi
    done
else
    fail "Docker inaccessible : service arrêté ou utilisateur hors du groupe docker (newgrp docker ou reconnexion)"
fi

if [ "$errors" -ne 0 ]; then
    echo >&2
    echo "$errors erreur(s) : corriger .env puis relancer make check-env." >&2
    exit 1
fi

echo "Configuration .env valide pour un démarrage complet."
