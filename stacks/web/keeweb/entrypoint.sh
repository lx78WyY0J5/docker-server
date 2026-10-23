#!/bin/sh
set -eu

: "${DOMAIN:?DOMAIN manquant}"

mkdir -p /var/www/webdav
chown -R www-data:www-data /var/www/webdav

sed "s|@@DOMAIN@@|${DOMAIN}|g" \
    /opt/keeweb/config.json.template \
    > /usr/local/apache2/htdocs/config.json
chown www-data:www-data /usr/local/apache2/htdocs/config.json

exec "$@"
