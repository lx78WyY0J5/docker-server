#!/bin/sh
set -eu

mkdir -p /var/lib/fail2ban /run/fail2ban /var/log/traefik
# Le volume de logs est partagé avec Traefik. Le créer ici évite que fail2ban
# refuse de démarrer s'il est lancé avant Traefik.
touch /var/log/traefik/access.log

# Traefik écrit l'access log dans un volume : sans rotation il peut remplir le
# disque. copytruncate garde le même inode pour que fail2ban continue de lire.
logrotate -s /var/lib/fail2ban/logrotate.status /etc/logrotate.d/traefik 2>/dev/null || true
(
    while :; do
        sleep 3600
        logrotate -s /var/lib/fail2ban/logrotate.status /etc/logrotate.d/traefik 2>/dev/null || true
    done
) &

exec fail2ban-server -f -c /etc/fail2ban
