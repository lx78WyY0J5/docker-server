# =============================================================================
# Paper - serveur Minecraft officiel PaperMC.
# Docs : https://docs.papermc.io/paper/
# API v3 (Fill) : https://fill.papermc.io/v3/projects/paper
# =============================================================================
FROM eclipse-temurin:25-jre-alpine

ARG PAPER_VERSION=1.21.11
ARG PAPER_BUILD=132
ENV PAPER_VERSION=${PAPER_VERSION}
ENV PAPER_BUILD=${PAPER_BUILD}

RUN apk add --no-cache curl jq unzip \
    && PAPER_URL=$(curl -fsSL --retry 5 --retry-delay 2 \
        "https://fill.papermc.io/v3/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}" \
        | jq -er '.downloads["server:default"].url') \
    && curl -fsSL --retry 5 --retry-delay 2 -o /opt/paper.jar "$PAPER_URL" \
    # Pré-télécharge le jar Mojang et le jar patché : le cache garantit le
    # démarrage même si Mojang est lent ou momentanément inaccessible.
    && mkdir -p /opt/paper-cache \
    && cd /opt/paper-cache \
    && timeout 300 java -jar /opt/paper.jar --version

COPY entrypoint.sh /usr/local/bin/paper-entrypoint
COPY config/ /opt/paper/config/
# Mondes initiaux (Spawn.zip) copiés depuis l'ancien dépôt « server ».
# L'entrypoint choisit la carte correspondant à SERVER_NAME.
COPY maps/ /opt/maps/

RUN chmod +x /usr/local/bin/paper-entrypoint

WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/paper-entrypoint"]
