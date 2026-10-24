#!/bin/sh
# Rend les templates (placeholders @@...@@) puis lance Traefik.
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME manquant}"
TLD=${TLD:-fr}
DOMAIN="${DOMAIN_NAME}.${TLD}"
ACME_EMAIL=${ACME_EMAIL:-admin@altherneum.fr}
PROXY_NETWORK=${PROXY_NETWORK:-altherneum_proxy}

DOMAIN_REGEX=$(printf '%s' "$DOMAIN" | sed 's/\./[.]/g')

render() {
    source=$1
    target=$2
    sed \
        -e "s|@@DOMAIN_REGEX@@|$DOMAIN_REGEX|g" \
        -e "s|@@DOMAIN@@|$DOMAIN|g" \
        -e "s|@@ACME_EMAIL@@|$ACME_EMAIL|g" \
        -e "s|@@ACME_CA_SERVER@@|$ACME_CA_SERVER|g" \
        -e "s|@@TRAEFIK_LOG_LEVEL@@|$TRAEFIK_LOG_LEVEL|g" \
        -e "s|@@TRAEFIK_DASHBOARD_HOST@@|$TRAEFIK_DASHBOARD_HOST|g" \
        -e "s|@@PROXY_NETWORK@@|$PROXY_NETWORK|g" \
        "$source" > "$target"
}

mkdir -p /etc/traefik/dynamic /acme /var/log/traefik
touch /var/log/traefik/access.log

render /etc/traefik/templates/traefik.yml.template /etc/traefik/traefik.yml
render /etc/traefik/templates/dynamic/dynamic.yml.template /etc/traefik/dynamic/dynamic.yml

# Le fichier ACME contient la clé privée du compte Let's Encrypt.
chmod 600 /acme/acme.json 2>/dev/null || true

exec traefik --configFile=/etc/traefik/traefik.yml