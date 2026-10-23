#!/bin/sh
set -eu

mkdir -p /var/lib/fail2ban /run/fail2ban

exec fail2ban-server -f -c /etc/fail2ban
