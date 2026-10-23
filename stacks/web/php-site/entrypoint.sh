#!/bin/sh
# =============================================================================
# Entrypoint du site PHP.
# Le code est monté depuis stacks/web/php-site/src : on ne chown pas toute
# l'arborescence (cela modifierait les fichiers de l'hôte). Seuls les dossiers
# dans lesquels PHP écrit sont ajustés.
# =============================================================================
set -eu

PHP_CONF_DIR=/etc/php/conf.d
if [ ! -d "$PHP_CONF_DIR" ]; then
    PHP_CONF_DIR=$(ls -d /etc/php[0-9]*/conf.d 2>/dev/null | sort | tail -n1)
fi

if [ -n "$PHP_CONF_DIR" ] && [ -d "$PHP_CONF_DIR" ]; then
    printf 'date.timezone = %s\n' "${TZ:-UTC}" > "$PHP_CONF_DIR/99-timezone.ini"
fi

mkdir -p /var/www/html/logs /var/www/html/public/uploads
chown -R apache:apache /var/www/html/logs /var/www/html/public/uploads 2>/dev/null || true

# .env est hors de la racine web, mais Apache doit pouvoir le lire.
if [ -f /var/www/html/.env ]; then
    chmod 0644 /var/www/html/.env 2>/dev/null || true
fi

# Initialise le schéma au premier démarrage (ou après une base vide).
if [ "${WEBSITE_AUTO_INIT:-true}" = "true" ] && [ -f /var/www/html/.env ]; then
    if ! php /usr/local/bin/php-site-db-ready; then
        echo "→ initialisation de la base du site PHP"
        php /usr/local/bin/php-site-init-db || true
        if ! php /usr/local/bin/php-site-db-ready; then
            echo "Attention : la base du site PHP n'a pas pu être initialisée." >&2
            echo "Vérifier DB_HOST/db-php et les identifiants PHP_DB_* dans .env." >&2
        fi
    fi
fi

exec "$@"
