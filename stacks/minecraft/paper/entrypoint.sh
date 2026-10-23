#!/bin/sh
# Prépare un serveur Paper derrière Velocity puis le lance.
set -eu

: "${SERVER_NAME:?SERVER_NAME manquant}"
: "${VELOCITY_SECRET:?VELOCITY_SECRET manquant}"
: "${MINECRAFT_RCON_PASSWORD:?MINECRAFT_RCON_PASSWORD manquant}"

MEMORY=${MEMORY:-1G}
SERVER_PORT=${SERVER_PORT:-25565}
RCON_PORT=${RCON_PORT:-25575}
LEVEL_NAME=${LEVEL_NAME:-Spawn}
MAX_PLAYERS=${MAX_PLAYERS:-20}
DOMAIN=${DOMAIN:-altherneum.fr}
SERVER_MOTD=${SERVER_MOTD:-"${SERVER_NAME}.${DOMAIN}"}
ONLINE_MODE=${VELOCITY_ONLINE_MODE:-true}

case "$ONLINE_MODE" in
    true|false) ;;
    *)
        echo "Erreur : VELOCITY_ONLINE_MODE doit valoir true ou false." >&2
        exit 1
        ;;
esac

mkdir -p /data/config /data/plugins /data/cache

# Le build a pré-téléchargé le jar Mojang et le jar Paper patché. On les copie
# dans le volume avant le premier démarrage ; le réseau egress ne sert qu'aux
# vérifications de plugins et aux appels Mojang, jamais au trafic joueur.
mkdir -p "/data/versions/${PAPER_VERSION}"
[ -f "/data/cache/mojang_${PAPER_VERSION}.jar" ] \
    || cp "/opt/paper-cache/cache/mojang_${PAPER_VERSION}.jar" /data/cache/
[ -f "/data/versions/${PAPER_VERSION}/paper-${PAPER_VERSION}.jar" ] \
    || cp "/opt/paper-cache/versions/${PAPER_VERSION}/paper-${PAPER_VERSION}.jar" \
        "/data/versions/${PAPER_VERSION}/"

printf 'eula=true\n' > /data/eula.txt

# Configuration Paper : le secret Velocity est réinjecté à chaque démarrage.
if [ ! -f /data/config/paper-global.yml ]; then
    cp /opt/paper/config/paper-global.yml /data/config/paper-global.yml
fi
sed -i "s|^    secret: .*|    secret: '${VELOCITY_SECRET}'|" /data/config/paper-global.yml
sed -i "/^  velocity:/,/^[^ ]/ s|^    online-mode: .*|    online-mode: ${ONLINE_MODE}|" /data/config/paper-global.yml
# Les pseudos Bedrock (préfixe Floodgate) ne respectent pas la regex Java.
sed -i "s|^  perform-username-validation: .*|  perform-username-validation: false|" /data/config/paper-global.yml

if [ ! -f /data/config/paper-world-defaults.yml ]; then
    cp /opt/paper/config/paper-world-defaults.yml /data/config/paper-world-defaults.yml
fi
if [ ! -f /data/ops.json ]; then
    cp /opt/paper/config/ops.json /data/ops.json
fi
if [ ! -f /data/server-icon.png ]; then
    cp /opt/paper/config/server-icon.png /data/server-icon.png
fi

# Plugins partagés, mis à jour par le service mc-plugins.
# Nettoyage des anciens noms/plugins Paper (Geyser/Floodgate sont proxy-only).
rm -f /data/plugins/geyser*.jar \
      /data/plugins/Geyser*.jar \
      /data/plugins/floodgate*.jar \
      /data/plugins/Floodgate*.jar \
      /data/plugins/ViaVersion-*.jar \
      /data/plugins/ViaBackwards-*.jar \
      /data/plugins/worldedit-bukkit-*.jar
if [ -d /opt/plugins/paper ]; then
    find /opt/plugins/paper -maxdepth 1 -name '*.jar' -exec cp -f {} /data/plugins/ \;
fi

cat > /data/server.properties <<EOF
enable-jmx-monitoring=false
rcon.port=${RCON_PORT}
gamemode=survival
enable-command-block=false
enable-query=false
generator-settings={}
enforce-secure-profile=false
level-name=${LEVEL_NAME}
motd=${SERVER_MOTD}
pvp=true
generate-structures=true
max-chained-neighbor-updates=1000000
difficulty=easy
network-compression-threshold=256
max-tick-time=60000
require-resource-pack=false
use-native-transport=true
max-players=${MAX_PLAYERS}
online-mode=false
enable-status=true
allow-flight=false
broadcast-rcon-to-ops=true
view-distance=8
server-ip=0.0.0.0
allow-nether=true
server-port=${SERVER_PORT}
enable-rcon=true
sync-chunk-writes=false
op-permission-level=4
prevent-proxy-connections=false
hide-online-players=false
resource-pack=https://minecraft.${DOMAIN}/storage/zip/resourcePack.zip
entity-broadcast-range-percentage=100
simulation-distance=6
rcon.password=${MINECRAFT_RCON_PASSWORD}
player-idle-timeout=0
debug=false
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
spawn-npcs=true
previews-chat=false
spawn-animals=true
function-permission-level=2
level-type=minecraft\:normal
text-filtering-config=
spawn-monsters=true
enforce-whitelist=false
spawn-protection=0
resource-pack-sha1=
max-world-size=29999984
EOF

exec java \
    -Xms"${MEMORY}" -Xmx"${MEMORY}" \
    -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
    -Dterminal.jline=false -Dterminal.ansi=true \
    -jar /opt/paper.jar --nogui
