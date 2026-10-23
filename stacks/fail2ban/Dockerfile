# =============================================================================
# fail2ban sur Alpine, lecture des logs JSON de Traefik.
# Docs : https://github.com/fail2ban/fail2ban
# =============================================================================
FROM alpine:3.24

# Le paquet Alpine active une jail sshd qui échoue en conteneur (pas de
# /var/log/auth.log). Seules les jails Traefik de ce dépôt sont utilisées.
RUN apk add --no-cache fail2ban iptables ip6tables tzdata logrotate \
    && rm -f /etc/fail2ban/jail.d/alpine-ssh.conf

COPY fail2ban.local /etc/fail2ban/fail2ban.local
COPY jail.local /etc/fail2ban/jail.local
COPY filter.d/ /etc/fail2ban/filter.d/
COPY jail.d/ /etc/fail2ban/jail.d/
COPY logrotate.conf /etc/logrotate.d/traefik
COPY entrypoint.sh /usr/local/bin/fail2ban-entrypoint

RUN chmod +x /usr/local/bin/fail2ban-entrypoint

ENTRYPOINT ["/usr/local/bin/fail2ban-entrypoint"]
