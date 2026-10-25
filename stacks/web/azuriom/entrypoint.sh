#!/bin/sh
# Installation et démarrage d'Azuriom.
# Le premier démarrage applique les migrations, les seeders et crée l'admin.
set -eu

CONFIG_DIR=/var/www/config
ENV_FILE="$CONFIG_DIR/.env"
mkdir -p "$CONFIG_DIR" /var/www/html/storage/app/public/zip

GAME_VALUE=${AZURIOM_GAME:-mc-online}
ADMIN_GAME_ID=$(printf '%s' "${AZURIOM_ADMIN_GAME_ID:-}" | tr -d '-' | tr 'A-F' 'a-f')

if [ "$GAME_VALUE" != "mc-online" ] && [ "$GAME_VALUE" != "mc-offline" ]; then
    echo "Erreur : AZURIOM_GAME doit être mc-online ou mc-offline." >&2
    exit 1
fi

if [ "$GAME_VALUE" = "mc-offline" ]; then
    if [ -n "$ADMIN_GAME_ID" ]; then
        echo "Attention : AZURIOM_ADMIN_GAME_ID est ignoré en mode mc-offline." >&2
    fi
    ADMIN_GAME_ID=""
fi

if [ -n "$ADMIN_GAME_ID" ]; then
    if [ -n "$(printf '%s' "$ADMIN_GAME_ID" | tr -d '0-9a-f')" ]; then
        echo "Erreur : AZURIOM_ADMIN_GAME_ID doit être un UUID hexadécimal." >&2
        exit 1
    fi
    if [ "${#ADMIN_GAME_ID}" -ne 32 ]; then
        echo "Erreur : AZURIOM_ADMIN_GAME_ID doit contenir 32 caractères (UUID sans tirets)." >&2
        exit 1
    fi
fi

if [ ! -f "$CONFIG_DIR/.installed" ] && [ "$GAME_VALUE" = "mc-online" ] && [ -z "$ADMIN_GAME_ID" ]; then
    echo "Erreur : AZURIOM_GAME=mc-online exige AZURIOM_ADMIN_GAME_ID." >&2
    echo "Renseigner l'UUID Minecraft (sans tirets) du compte admin dans .env." >&2
    exit 1
fi

APP_KEY_VALUE=""
if [ -f "$ENV_FILE" ]; then
    APP_KEY_VALUE=$(sed -n 's/^APP_KEY=//p' "$ENV_FILE" | head -n 1)
fi
if [ -z "$APP_KEY_VALUE" ]; then
    APP_KEY_VALUE=${APP_KEY:-}
fi
if [ -z "$APP_KEY_VALUE" ]; then
    APP_KEY_VALUE="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
fi

MAIL_SCHEME_VALUE=smtp
if [ "${MAIL_ENCRYPTION:-tls}" = "ssl" ]; then
    MAIL_SCHEME_VALUE=smtps
fi

cat > "$ENV_FILE" <<EOF
APP_NAME=Azuriom
APP_ENV=production
APP_KEY=${APP_KEY_VALUE}
APP_DEBUG=false
APP_TIMEZONE=${TZ:-Europe/Paris}
APP_URL=${APP_URL}
APP_LOCALE=fr
APP_MAINTENANCE_DRIVER=file

AZURIOM_GAME=${GAME_VALUE}
MICROSOFT_CLIENT_ID=${MICROSOFT_CLIENT_ID:-}
MICROSOFT_CLIENT_SECRET=${MICROSOFT_CLIENT_SECRET:-}
BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_LEVEL=warning

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=${DOMAIN}

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
CACHE_STORE=file
CACHE_DRIVER=file