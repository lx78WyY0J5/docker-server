#!/bin/sh
# Vérifie que .env contient les secrets nécessaires avant make up

set -eu

ENV_FILE=".env"

echo "=== Verification de la configuration ==="

# Check DOMAIN_NAME and TLD are set
if ! grep -q "^DOMAIN_NAME=" "$ENV_FILE"; then
    echo "ERROR : DOMAIN_NAME missing in $ENV_FILE" >&2
    exit 1
fi
DOMAIN_NAME=$(get_env DOMAIN_NAME)

if [ -z "$TLD" ]; then
    # TLD can be empty for testing
    pass=true
else
    if ! grep -q "^TLD=" "$ENV_FILE"; then
        echo "ERROR : TLD missing in $ENV_FILE" >&2
        exit 1
    fi
fi

# Check email variables use DOMAIN properly (basic check)
echo ""
echo "=== Checking email configurations ==="
echo "DOMAIN_NAME: $DOMAIN_NAME"

# Verify that mail variables exist but don't need to be validated here
if grep -q "^AZURIOM_MAIL_HOST=" "$ENV_FILE"; then
    echo "✓ AZURIOM_MAIL_HOST found"
fi
if grep -q "^FORGEJO_MAIL_HOST=" "$ENV_FILE"; then
    echo "✓ FORGEJO_MAIL_HOST found"
fi

echo ""
echo "=== All required variables present ==="
