#!/bin/sh
# Téléchargement des plugins officiels dans /plugins.
# Les versions sont définies via les variables d'environnement (.env).
set -eu

PAPER_DIR=/plugins/paper
PAPER_CREATIF_DIR=/plugins/paper-creatif
VELOCITY_DIR=/plugins/velocity

mkdir -p "$PAPER_DIR" "$PAPER_CREATIF_DIR" "$VELOCITY_DIR"

# Retire les anciens JAR obsolètes (avec version pour éviter conflits)
rm -f "$VELOCITY_DIR"/Floodgate*.jar \
      "$VELOCITY_DIR"/Geyser*.jar \
      "$PAPER_DIR"/ViaVersion*.jar \
      "$PAPER_DIR"/ViaBackwards*.jar \
      "$PAPER_CREATIF_DIR"/Worldedit*.jar \
      "$PAPER_DIR"/WorldEdit*.jar \
      "$PAPER_DIR"/Plugin*.jar \

# Fonction pour vérifier si un fichier existe et télécharger s'il manque
fetch_if_needed() {
    local url=$1
    local target=$2

    echo "checking : $target"
    
    # Check if file exists (exact match by name)
    if [ -f "/tmp/$target.tmp" ]; then
        echo "✓ $target (déjà téléchargé)"
        return 0
    fi

    echo "→ Téléchargement de $target"
    curl -fsSL --retry 5 --retry-delay 2 -o "/tmp/$target.tmp" "$url"
    cp "/tmp/$target.tmp" "$target"
}

# Plugin maison (Paper).
fetch_if_needed \
    "https://github.com/Altherneum/plugin/releases/latest/download/plugin-1.0-fat.jar" \
    "$PAPER_DIR/Plugin.jar"

# ViaVersion
fetch_if_needed \
    "https://github.com/ViaVersion/ViaVersion/releases/download/${VIAVERSION_VERSION}/ViaVersion-${VIAVERSION_VERSION}.jar" \
    "$PAPER_DIR/ViaVersion-${VIAVERSION_VERSION}.jar"

# ViaBackwards
fetch_if_needed \
    "https://github.com/ViaVersion/ViaBackwards/releases/download/${VIABACKWARDS_VERSION}/ViaBackwards-${VIABACKWARDS_VERSION}.jar" \
    "$PAPER_DIR/ViaBackwards-${VIABACKWARDS_VERSION}.jar"

# WorldEdit (Paper 1.21.11) - uniquement sur le serveur créatif.
# Note: modrinth uses a fixed release ID, version is in filename only
fetch_if_needed \
    "https://cdn.modrinth.com/data/1u6JkXh5/versions/${WORLDEDIT_OPAQUE}/worldedit-bukkit-${WORLDEDIT_VERSION}.jar" \
    "$PAPER_CREATIF_DIR/Worldedit-${WORLDEDIT_VERSION}.jar"

# Geyser (Bedrock cross-play)
fetch_if_needed \
    "https://download.geysermc.org/v2/projects/geyser/versions/${GEYSER_VERSION}/builds/latest/downloads/velocity" \
    "$VELOCITY_DIR/Geyser-${GEYSER_VERSION}.jar"

# Floodgate (Bedrock cross-play)
fetch_if_needed \
    "https://download.geysermc.org/v2/projects/floodgate/versions/${FLOODGATE_VERSION}/builds/latest/downloads/velocity" \
    "$VELOCITY_DIR/Floodgate-${FLOODGATE_VERSION}.jar"

echo "Plugins prêts dans $PAPER_DIR, $PAPER_CREATIF_DIR et $VELOCITY_DIR"
