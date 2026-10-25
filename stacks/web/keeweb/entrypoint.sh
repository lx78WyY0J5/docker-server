#!/bin/sh
# Génère la configuration KeeWeb puis démarre Apache.
set -eu

: "${DOMAIN:?DOMAIN manquant}"

CONFIG_DIR=/usr/local/apache2/htdocs
DATA_DIR=/var/www/webdav
TEMPLATE=/opt/keeweb/config.json.template

mkdir -p "$CONFIG_DIR" "$DATA_DIR"
chown -R www-data:www-data "$DATA_DIR"

# Échappe les caractères spéciaux sed présents dans le domaine.
DOMAIN_SED=$(printf '%s' "$DOMAIN" | sed 's/[\\&|]/\\&/g')
sed "s|@@DOMAIN@@|${DOMAIN_SED}|g" "$TEMPLATE" > "$CONFIG_DIR/config.json"

exec "$@"
