#!/bin/sh
# Prépare Velocity puis le lance.
set -eu

: "${VELOCITY_SECRET:?VELOCITY_SECRET manquant}"

: "${DOMAIN:?DOMAIN manquant}"
MEMORY=${VELOCITY_MEMORY:-512M}
MOTD=${VELOCITY_MOTD:-"<#09add3>${DOMAIN}"}
ONLINE_MODE=${VELOCITY_ONLINE_MODE:-true}

# Échappe une valeur destinée à une chaîne entre guillemets (TOML ou YAML) :
# les backslashes et guillemets sont protégés, et un MOTD multiligne (par
# exemple « <#09add3>domaine\ndiscord.domaine » dans .env, où Compose convertit
# \n en vrai saut de ligne) devient la séquence \n comprise par TOML/YAML.
escape_config() {
    printf '%s' "$1" \
        | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
        | awk 'BEGIN { ORS="" } { if (NR > 1) printf "\\n"; print }'
}

# Échappe les caractères spéciaux d'un remplacement sed (délimiteur, & et
# backslash) pour insérer la valeur sans que sed l'interprète.
escape_sed() {
    printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

DOMAIN_SAFE=$(escape_sed "$(escape_config "$DOMAIN")")
MOTD_SAFE=$(escape_sed "$(escape_config "$MOTD")")

if [ "$ONLINE_MODE" != "true" ] && [ "$ONLINE_MODE" != "false" ]; then
    echo "Erreur : VELOCITY_ONLINE_MODE doit valoir true ou false." >&2
    exit 1
fi

mkdir -p /data/plugins

# Migration des anciens dossiers (casse incorrecte) vers les noms attendus
# par Geyser-Velocity et Floodgate.
if [ -d /data/plugins/Geyser ] && [ ! -e /data/plugins/Geyser-Velocity ]; then
    mv /data/plugins/Geyser /data/plugins/Geyser-Velocity
fi
if [ -d /data/plugins/Floodgate ] && [ ! -e /data/plugins/floodgate ]; then
    mv /data/plugins/Floodgate /data/plugins/floodgate
fi

GEYSER_DIR=/data/plugins/Geyser-Velocity
FLOODGATE_DIR=/data/plugins/floodgate
mkdir -p "$GEYSER_DIR" "$FLOODGATE_DIR"

printf '%s' "$VELOCITY_SECRET" > /data/forwarding.secret
chmod 600 /data/forwarding.secret

sed -e "s|__DOMAIN__|${DOMAIN_SAFE}|g" \
    -e "s|__MOTD__|${MOTD_SAFE}|g" \
    -e "s|__ONLINE_MODE__|${ONLINE_MODE}|g" \
    /opt/velocity/config/velocity.toml.template > /data/velocity.toml

if [ ! -f /data/server-icon.png ]; then
    cp /opt/velocity/config/server-icon.png /data/server-icon.png
fi

# Config Geyser (Bedrock) — copie si absente.
if [ ! -f "$GEYSER_DIR/config.yml" ]; then
    sed -e "s|__DOMAIN__|${DOMAIN_SAFE}|g" \
        -e "s|__MOTD__|${MOTD_SAFE}|g" \
        /opt/velocity/config/geyser.yml.template > "$GEYSER_DIR/config.yml"
fi

# Config Floodgate (Bedrock) — copie si absente.
if [ ! -f "$FLOODGATE_DIR/config.yml" ]; then
    cp /opt/velocity/config/floodgate.yml.template "$FLOODGATE_DIR/config.yml"
fi

# Floodgate attend une clé AES-128 brute dans key.pem. La générer ici évite
# que Geyser démarre avant Floodgate au tout premier lancement.
if [ ! -s "$FLOODGATE_DIR/key.pem" ]; then
    dd if=/dev/urandom of="$FLOODGATE_DIR/key.pem" bs=16 count=1 2>/dev/null
    chmod 600 "$FLOODGATE_DIR/key.pem"
fi
# Geyser lit la clé dans plugins/floodgate/ s'il détecte Floodgate, sinon dans
# son propre dossier. On copie la même clé aux deux endroits pour ne dépendre
# ni de l'ordre de chargement des plugins ni du résultat de la détection.
cp -f "$FLOODGATE_DIR/key.pem" "$GEYSER_DIR/key.pem"
chmod 600 "$GEYSER_DIR/key.pem"

# Nettoyage des anciens noms versionnés pour éviter deux JAR du même plugin.
rm -f /data/plugins/Geyser*.jar \
      /data/plugins/geyser*.jar \
      /data/plugins/Floodgate*.jar \
      /data/plugins/floodgate*.jar
if [ -d /opt/plugins/velocity ]; then
    find /opt/plugins/velocity -maxdepth 1 -name '*.jar' -exec cp -f {} /data/plugins/ \;
fi

exec java \
    -Xms"${MEMORY}" -Xmx"${MEMORY}" \
    -XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:+ParallelRefProcEnabled \
    -XX:+AlwaysPreTouch -XX:MaxInlineLevel=15 \
    -jar /opt/velocity.jar
