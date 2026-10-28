#!/bin/sh
# Applique les données de démonstration Azuriom.
#
#   azuriom-seed               installe les extensions fournies, copie les
#                              images/vues puis importe les fichiers SQL
#   azuriom-seed --assets-only copie les images/vues, synchronise le thème et
#                              recrée les liens vers les assets des extensions
#
# Le mode complet est lancé au premier démarrage du conteneur. Il est aussi
# disponible manuellement via « make azuriom-seed ».
set -eu

WEBROOT=${AZURIOM_WEBROOT:-/var/www/html}
SEED_DIR=${AZURIOM_SEED_DIR:-/opt/azuriom-seed}
MODE=${1:-}

copy_missing() {
    source_dir=$1
    destination_dir=$2

    for source in "$source_dir"/*; do
        [ -e "$source" ] || continue
        destination="$destination_dir/$(basename "$source")"
        [ -e "$destination" ] || cp -a "$source" "$destination_dir/"
    done
}

copy_assets() {
    mkdir -p \
        "$WEBROOT/storage/app/public/img" \
        "$WEBROOT/storage/app/public/packages" \
        "$WEBROOT/resources/views/custom"

    copy_missing "$SEED_DIR/public/img" "$WEBROOT/storage/app/public/img"
    copy_missing "$SEED_DIR/public/packages" "$WEBROOT/storage/app/public/packages"
    cp -a "$SEED_DIR/views/custom/." "$WEBROOT/resources/views/custom/"
}

extension_version() {
    [ -f "$1/theme.json" ] || return 0

    php -r '
        $data = json_decode(file_get_contents($argv[1]), true);
        echo is_array($data) ? ($data["version"] ?? "") : "";
    ' "$1/theme.json" 2>/dev/null || true
}

copy_extensions() {
    mkdir -p "$WEBROOT/plugins" "$WEBROOT/resources/themes"

    if [ -d "$SEED_DIR/extensions/plugins/shop" ] \
        && [ ! -d "$WEBROOT/plugins/shop" ]; then
        echo "→ installation du plugin Shop"
        cp -a "$SEED_DIR/extensions/plugins/shop" "$WEBROOT/plugins/shop"
    fi

    if [ -d "$SEED_DIR/extensions/themes/prism" ]; then
        theme_source="$SEED_DIR/extensions/themes/prism"
        theme_destination="$WEBROOT/resources/themes/prism"
        theme_version=$(extension_version "$theme_source")

        if [ ! -d "$theme_destination" ]; then
            echo "→ installation du thème Prism ${theme_version}"
            cp -a "$theme_source" "$theme_destination"
        else
            installed_version=$(extension_version "$theme_destination")

            # Les anciennes versions de Prism ne sont pas compatibles avec
            # Bootstrap 5/Azuriom 1.2 (icônes, couleurs et pied de page).
            if [ -n "$theme_version" ] \
                && [ "$installed_version" != "$theme_version" ]; then
                echo "→ mise à jour du thème Prism ${installed_version:-inconnue} → ${theme_version}"
                rm -rf "$theme_destination"
                cp -a "$theme_source" "$theme_destination"
            fi
        fi
    fi

    chown -R apache:apache \
        "$WEBROOT/plugins/shop" \
        "$WEBROOT/resources/themes/prism" \
        2>/dev/null || true
}

ensure_asset_links() {
    mkdir -p "$WEBROOT/public/assets/themes" "$WEBROOT/public/assets/plugins"

    if [ -d "$WEBROOT/resources/themes/prism/assets" ]; then
        ln -sfn ../../../resources/themes/prism/assets \
            "$WEBROOT/public/assets/themes/prism"
    fi

    if [ -d "$WEBROOT/plugins/shop/assets" ]; then
        ln -sfn ../../../plugins/shop/assets \
            "$WEBROOT/public/assets/plugins/shop"
    fi
}

enable_shop() {
    [ -d "$WEBROOT/plugins/shop" ] || return 0

    plugins_json="$WEBROOT/plugins/plugins.json"
    if [ -f "$plugins_json" ] && grep -q '"shop"' "$plugins_json"; then
        return 0
    fi

    echo "→ activation du plugin Shop"
    if ! (cd "$WEBROOT" && php artisan plugin:enable shop); then
        echo "Attention : activation du plugin Shop impossible ; les tables de la boutique ne seront pas importées." >&2
    fi
}

if [ "$MODE" = "--assets-only" ]; then
    copy_assets
    copy_extensions
    ensure_asset_links
    exit 0
fi

copy_assets
copy_extensions
ensure_asset_links
enable_shop

echo "→ import des données Azuriom"
php "$SEED_DIR/import.php" "$SEED_DIR/database"

cd "$WEBROOT"
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true
php artisan route:clear >/dev/null 2>&1 || true
php artisan view:clear >/dev/null 2>&1 || true
