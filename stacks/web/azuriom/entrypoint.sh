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
CACHE_PREFIX=

MAIL_MAILER=${MAIL_MAILER:-log}
MAIL_SCHEME=${MAIL_SCHEME_VALUE}
MAIL_HOST=${MAIL_HOST:-127.0.0.1}
MAIL_PORT=${MAIL_PORT:-587}
MAIL_USERNAME=${MAIL_USERNAME:-null}
MAIL_PASSWORD=${MAIL_PASSWORD:-null}
MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-tls}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-noreply@localhost}
MAIL_FROM_NAME="Azuriom"
EOF

ln -sf "$ENV_FILE" /var/www/html/.env

echo "→ attente de la base de données"
tries=0
until php -r '
$dsn = "mysql:host=" . getenv("DB_HOST") . ";port=" . (getenv("DB_PORT") ?: "3306");
new PDO($dsn, getenv("DB_USERNAME"), getenv("DB_PASSWORD"));
' 2>/dev/null; do
    tries=$((tries + 1))
    if [ "$tries" -gt 60 ]; then
        echo "Erreur : base de données indisponible." >&2
        exit 1
    fi
    sleep 2
done

# En mc-online, l'admin doit être lié à son UUID Minecraft pour pouvoir se
# connecter via Microsoft. L'UUID est appliqué de façon idempotente.
ensure_admin_game_id() {
    [ -n "$ADMIN_GAME_ID" ] || return 0
    AZURIOM_ADMIN_GAME_ID_NORMALIZED="$ADMIN_GAME_ID" php -r '
        $pdo = new PDO(
            "mysql:host=" . getenv("DB_HOST") . ";port=" . (getenv("DB_PORT") ?: "3306") . ";dbname=" . getenv("DB_DATABASE"),
            getenv("DB_USERNAME"),
            getenv("DB_PASSWORD")
        );
        $email = getenv("AZURIOM_ADMIN_EMAIL");
        $stmt = $pdo->prepare("
            SELECT u.id
            FROM users u
            JOIN roles r ON r.id = u.role_id
            WHERE u.email = ?
              AND
              r.is_admin = 1
        ");
        $stmt->execute([$email]);
        if ($stmt->fetchColumn() === false) {
            fwrite(STDERR, "Attention : aucun compte admin avec le courriel {$email} ; AZURIOM_ADMIN_GAME_ID ignoré.\n");
            exit(0);
        }
        $gameId = getenv("AZURIOM_ADMIN_GAME_ID_NORMALIZED");
        $stmt = $pdo->prepare("
            SELECT id FROM users
            WHERE game_id = ?
              AND
              (email IS NULL OR email <> ?)
        ");
        $stmt->execute([$gameId, $email]);
        if ($stmt->fetchColumn() !== false) {
            fwrite(STDERR, "Attention : UUID Minecraft déjà utilisé par un autre compte ; AZURIOM_ADMIN_GAME_ID ignoré.\n");
            exit(0);
        }
        try {
            $update = $pdo->prepare("UPDATE users SET game_id = ? WHERE email = ?");
            $update->execute([$gameId, $email]);
        } catch (PDOException $e) {
            fwrite(STDERR, "Attention : impossible de lier le compte admin : {$e->getMessage()}\n");
        }
    '
}

if [ ! -f "$CONFIG_DIR/.installed" ]; then
    echo "→ première installation Azuriom"
    php artisan migrate --force --seed
    php artisan storage:link --relative || true
    # Créer l'admin uniquement sur une base vierge (migration/reprise sûre).
    if php -r '
        $pdo = new PDO(
            "mysql:host=" . getenv("DB_HOST") . ";port=" . (getenv("DB_PORT") ?: "3306") . ";dbname=" . getenv("DB_DATABASE"),
            getenv("DB_USERNAME"),
            getenv("DB_PASSWORD")
        );
        exit((int) $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn() === 0 ? 0 : 1);
    '; then
        if [ "$GAME_VALUE" = "mc-online" ] && [ -z "$ADMIN_GAME_ID" ]; then
            echo "Erreur : AZURIOM_GAME=mc-online exige AZURIOM_ADMIN_GAME_ID." >&2
            echo "Renseigner l'UUID Minecraft (sans tirets) du compte admin dans .env." >&2
            exit 1
        fi
        php artisan user:create \
            --admin \
            --name="${AZURIOM_ADMIN_NAME}" \
            --email="${AZURIOM_ADMIN_EMAIL}" \
            --password="${AZURIOM_ADMIN_PASSWORD}"
    else
        echo "→ des comptes existent déjà, création de l'admin ignorée"
    fi
    ensure_admin_game_id
    date -u +%Y-%m-%dT%H:%M:%SZ > "$CONFIG_DIR/.installed"
else
    php artisan migrate --force
    php artisan storage:link --relative || true
    ensure_admin_game_id
fi

# Le pack est téléchargé dans le volume Azuriom puis exposé par
# /storage/zip/resourcePack.zip. La copie temporaire évite de laisser un
# fichier tronqué si le téléchargement échoue.
RESOURCE_PACK_FILE=/var/www/html/storage/app/public/zip/resourcePack.zip
if [ -n "${AZURIOM_RESOURCE_PACK_URL:-}" ]; then
    echo "→ téléchargement du resource pack"
    RESOURCE_PACK_TMP="${RESOURCE_PACK_FILE}.tmp"
    if curl -fL --retry 3 --retry-delay 2 -o "$RESOURCE_PACK_TMP" \
        "$AZURIOM_RESOURCE_PACK_URL"; then
        mv "$RESOURCE_PACK_TMP" "$RESOURCE_PACK_FILE"
    else
        rm -f "$RESOURCE_PACK_TMP"
        echo "Attention : resource pack non téléchargé." >&2
    fi
fi

php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true
php artisan route:clear >/dev/null 2>&1 || true
php artisan view:clear >/dev/null 2>&1 || true

chown -R apache:apache \
    /var/www/html/storage \
    /var/www/html/bootstrap/cache \
    /var/www/html/plugins \
    /var/www/html/themes \
    2>/dev/null || true

exec "$@"
