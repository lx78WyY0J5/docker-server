#!/bin/sh
# Télécharge les plugins officiels dans /plugins.
# Les versions sont volontairement lisibles ici : mettre à jour ce fichier
# puis relancer la stack Minecraft.
set -eu

PAPER_DIR=/plugins/paper
# Plugins réservés au serveur créatif, copiés uniquement par ce serveur.
PAPER_CREATIF_DIR=/plugins/paper-creatif
VELOCITY_DIR=/plugins/velocity
mkdir -p "$PAPER_DIR" "$PAPER_CREATIF_DIR" "$VELOCITY_DIR"

# Retire les anciens JAR obsolètes d'une installation précédente.
# Les motifs couvrent aussi les noms versionnés utilisés par d'anciennes
# versions du dépôt (Geyser-Velocity.jar, ViaVersion-x.y.z.jar, etc.).
rm -f "$PAPER_DIR"/floodgate*.jar \
      "$PAPER_DIR"/Floodgate*.jar \
      "$PAPER_DIR"/geyser*.jar \
      "$PAPER_DIR"/Geyser*.jar \
      "$PAPER_DIR"/ViaVersion-*.jar \
      "$PAPER_DIR"/ViaBackwards-*.jar \
      "$PAPER_DIR"/worldedit-bukkit-*.jar \
      "$PAPER_DIR"/WorldEdit.jar \
      "$VELOCITY_DIR"/floodgate*.jar \
      "$VELOCITY_DIR"/Floodgate*.jar \
      "$VELOCITY_DIR"/geyser*.jar \
      "$VELOCITY_DIR"/Geyser*.jar

fetch() {
    url=$1
    target=$2
    echo "→ $(basename "$target")"
    curl -fsSL --retry 5 --retry-delay 2 -o "$target.tmp" "$url"
    mv "$target.tmp" "$target"
}

# Plugin maison (Paper).
fetch \
    "https://github.com/Altherneum/plugin/releases/latest/download/plugin-1.0-fat.jar" \
    "$PAPER_DIR/altherneum-plugin.jar"

# Compatibilité des clients récents/anciens (Paper 1.21.11).
fetch \
    "https://github.com/ViaVersion/ViaVersion/releases/download/5.12.1/ViaVersion-5.12.1.jar" \
    "$PAPER_DIR/ViaVersion.jar"
fetch \
    "https://github.com/ViaVersion/ViaBackwards/releases/download/5.12.1/ViaBackwards-5.12.1.jar" \
    "$PAPER_DIR/ViaBackwards.jar"

# WorldEdit (Paper 1.21.11) - uniquement sur le serveur créatif.
fetch \
    "https://cdn.modrinth.com/data/1u6JkXh5/versions/YFnqiUlL/worldedit-bukkit-7.4.6.jar" \
    "$PAPER_CREATIF_DIR/WorldEdit.jar"

# Geyser / Floodgate (Bedrock cross-play) - Velocity.
# Floodgate n'est installé que sur le proxy : c'est le mode officiel recommandé
# lorsque les serveurs Paper n'utilisent pas l'API Floodgate.
# Nécessite : ports 19132/tcp, 19132/udp et 19133/udp publiés + config
# Geyser/Floodgate (key.pem, config.yml).
fetch \
    "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/velocity" \
    "$VELOCITY_DIR/Geyser.jar"
fetch \
    "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity" \
    "$VELOCITY_DIR/Floodgate.jar"

echo "Plugins prêts dans $PAPER_DIR, $PAPER_CREATIF_DIR et $VELOCITY_DIR"