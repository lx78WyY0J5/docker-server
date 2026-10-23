# =============================================================================
# Velocity — proxy Minecraft officiel PaperMC.
# Docs : https://docs.papermc.io/velocity/
# API v3 (Fill) : https://fill.papermc.io/v3/projects/velocity
# =============================================================================
FROM eclipse-temurin:25-jre-alpine

ARG VELOCITY_VERSION=4.3.0
ARG VELOCITY_BUILD=44

RUN apk add --no-cache curl jq openssl \
    && VELOCITY_URL=$(curl -fsSL --retry 5 --retry-delay 2 \
        "https://fill.papermc.io/v3/projects/velocity/versions/${VELOCITY_VERSION}/builds/${VELOCITY_BUILD}" \
        | jq -er '.downloads["server:default"].url') \
    && curl -fsSL --retry 5 --retry-delay 2 -o /opt/velocity.jar "$VELOCITY_URL"

COPY entrypoint.sh /usr/local/bin/velocity-entrypoint
COPY config/ /opt/velocity/config/

RUN chmod +x /usr/local/bin/velocity-entrypoint

WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/velocity-entrypoint"]
