# =============================================================================
# Paper — serveur Minecraft officiel PaperMC.
# Docs : https://docs.papermc.io/paper/
# API v3 (Fill) : https://fill.papermc.io/v3/projects/paper
# =============================================================================
FROM eclipse-temurin:21-jre-alpine

ARG PAPER_VERSION=1.21.11
ARG PAPER_BUILD=132

RUN apk add --no-cache curl jq \
    && PAPER_URL=$(curl -fsSL --retry 5 --retry-delay 2 \
        "https://fill.papermc.io/v3/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}" \
        | jq -er '.downloads["server:default"].url') \
    && curl -fsSL --retry 5 --retry-delay 2 -o /opt/paper.jar "$PAPER_URL"

COPY entrypoint.sh /usr/local/bin/paper-entrypoint
COPY config/ /opt/paper/config/

RUN chmod +x /usr/local/bin/paper-entrypoint

WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/paper-entrypoint"]
