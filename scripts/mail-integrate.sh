#!/bin/sh
# =============================================================================
# Installe l'override Traefik dans l'installation mailcow officielle.
# =============================================================================
set -eu

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "Erreur : .env introuvable. Lancer make init." >&2; exit 1; }
get_env() { sed -n "s/^$1=//p" .env | tail -n 1; }

DOMAIN=$(get_env DOMAIN)
PROXY_NETWORK=$(get_env PROXY_NETWORK)
MAILCOW_DIR=${MAILCOW_DIR:-$(get_env MAILCOW_DIR)}
MAILCOW_DIR=${MAILCOW_DIR:-/opt/mailcow-dockerized}

[ -d "$MAILCOW_DIR" ] || { echo "Erreur : $MAILCOW_DIR introuvable. Voir docs/06-mailcow.md." >&2; exit 1; }
[ -f "$MAILCOW_DIR/docker-compose.yml" ] || { echo "Erreur : $MAILCOW_DIR ne contient pas docker-compose.yml." >&2; exit 1; }

DOMAIN_REGEX=$(printf '%s' "$DOMAIN" | sed 's/\./[.]/g')

sed \
    -e "s|@@DOMAIN_REGEX@@|$DOMAIN_REGEX|g" \
    -e "s|@@DOMAIN@@|$DOMAIN|g" \
    -e "s|@@PROXY_NETWORK@@|$PROXY_NETWORK|g" \
    stacks/mail/traefik.override.yaml.template \
    > "$MAILCOW_DIR/docker-compose.override.yml"

echo "→ override écrit dans $MAILCOW_DIR/docker-compose.override.yml"
echo "  Vérifier dans $MAILCOW_DIR/mailcow.conf :"
echo "    MAILCOW_HOSTNAME=mail.$DOMAIN"
echo "    ACME_DNS_CHALLENGE=y (DNS-01, pas de port 80)"
echo "    SKIP_LETS_ENCRYPT=n"
echo "  Puis : make mail-up"
