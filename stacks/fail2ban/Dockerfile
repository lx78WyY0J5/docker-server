# =============================================================================
# fail2ban sur Alpine, lecture des logs JSON de Traefik.
# Docs : https://github.com/fail2ban/fail2ban
# =============================================================================
FROM alpine:3.24

RUN apk add --no-cache fail2ban iptables ip6tables tzdata

COPY fail2ban.local /etc/fail2ban/fail2ban.local
COPY jail.local /etc/fail2ban/jail.local
COPY filter.d/ /etc/fail2ban/filter.d/
COPY jail.d/ /etc/fail2ban/jail.d/
COPY entrypoint.sh /usr/local/bin/fail2ban-entrypoint

RUN chmod +x /usr/local/bin/fail2ban-entrypoint

ENTRYPOINT ["/usr/local/bin/fail2ban-entrypoint"]
