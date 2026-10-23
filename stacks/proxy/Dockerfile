# =============================================================================
# Traefik officiel + rendu des templates de configuration.
# Docs : https://doc.traefik.io/traefik/
# =============================================================================
FROM traefik:3.7.16

COPY entrypoint.sh /entrypoint.sh
COPY templates /etc/traefik/templates

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
