#!/bin/sh
set -eu

# /etc/php est un lien stable créé dans l'image vers /etc/php<version>.
PHP_CONF_DIR=/etc/php/conf.d
if [ ! -d "$PHP_CONF_DIR" ]; then
    PHP_CONF_DIR=$(ls -d /etc/php[0-9]*/conf.d 2>/dev/null | sort | tail -n1)
fi
[ -n "$PHP_CONF_DIR" ] && [ -d "$PHP_CONF_DIR" ] || {
    echo "Erreur : répertoire de configuration PHP introuvable." >&2
    exit 1
}

# Le fuseau horaire vient de .env (TZ).
printf 'date.timezone = %s\n' "${TZ:-UTC}" > "$PHP_CONF_DIR/99-timezone.ini"

# Les volumes nommés sont créés root ; Apache tourne sous l'utilisateur apache.
# Sur un bind mount en lecture seule, l'échec est ignoré.
chown -R apache:apache /var/www/html 2>/dev/null || true

exec "$@"
