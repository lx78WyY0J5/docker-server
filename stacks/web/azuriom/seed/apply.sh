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
DOMAIN_NAME=${DOMAIN_NAME:-localhost}
TLD=${TLD:-}
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

manifest_version() {
    [ -f "$1" ] || return 0

    php -r '
        $data = json_decode(file_get_contents($argv[1]), true);
        echo is_array($data) ? ($data["version"] ?? "") : "";
    ' "$1" 2>/dev/null || true
}

# Installe ou met à jour une extension du volume à partir de l'image.
# Les extensions ne sont plus suivies par l'image une fois copiées : sans
# cette synchronisation, une ancienne version resterait indéfiniment dans le
# volume après une mise à jour du Dockerfile.
sync_extension() {
    source_dir=$1
    destination_dir=$2
    manifest=$3
    label=$4

    source_version=$(manifest_version "$source_dir/$manifest")

    if [ ! -d "$destination_dir" ]; then
        echo "→ installation de ${label} ${source_version}"
        cp -a "$source_dir" "$destination_dir"
        return 0
    fi

    installed_version=$(manifest_version "$destination_dir/$manifest")

    if [ -n "$source_version" ] && [ "$installed_version" != "$source_version" ]; then
        echo "→ mise à jour de ${label} ${installed_version:-inconnue} → ${source_version}"
        rm -rf "$destination_dir"
        cp -a "$source_dir" "$destination_dir"
    fi
}

copy_extensions() {
    mkdir -p "$WEBROOT/plugins" "$WEBROOT/resources/themes"

    if [ -d "$SEED_DIR/extensions/plugins/shop" ]; then
        sync_extension \
            "$SEED_DIR/extensions/plugins/shop" \
            "$WEBROOT/plugins/shop" \
            plugin.json \
            "du plugin Shop"
    fi

    # Les anciennes versions de Prism ne sont pas compatibles avec
    # Bootstrap 5/Azuriom 1.2 (icônes, couleurs et pied de page).
    if [ -d "$SEED_DIR/extensions/themes/prism" ]; then
        sync_extension \
            "$SEED_DIR/extensions/themes/prism" \
            "$WEBROOT/resources/themes/prism" \
            theme.json \
            "du thème Prism"
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

echo "→ sed du DNS et TLD des données Azuriom"
# Remplacer les variables env par leurs valeurs réelles avant copie
# Inclut settings.sql, social_links.sql et import.php
sed -i "s/\${DOMAIN_NAME}/$DOMAIN_NAME/g; s/\${TLD}/$TLD/g" "$SEED_DIR"/database/*.sql

echo "→ import des données Azuriom"
php "$SEED_DIR/import.php" "$SEED_DIR/database"

cd "$WEBROOT"
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true
php artisan route:clear >/dev/null 2>&1 || true
php artisan view:clear >/dev/null 2>&1 || true
