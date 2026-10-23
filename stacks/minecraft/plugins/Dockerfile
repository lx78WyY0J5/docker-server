# =============================================================================
# Téléchargement des plugins Paper/Velocity officiels vers un volume partagé.
# Les serveurs copient les JAR dans leur propre dossier plugins.
# =============================================================================
FROM alpine:3.24

RUN apk add --no-cache curl ca-certificates

COPY fetch-plugins.sh /usr/local/bin/fetch-plugins.sh
RUN chmod +x /usr/local/bin/fetch-plugins.sh

VOLUME ["/plugins"]

ENTRYPOINT ["/usr/local/bin/fetch-plugins.sh"]
