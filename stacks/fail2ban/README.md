# Stack fail2ban

fail2ban lit les logs JSON de Traefik (volume `altherneum_traefik-logs`) et
bannit les IP via iptables sur l'hôte.

- `jail.local` : réglages communs (incremental bantime, réseau Docker ignoré,
  bannissement dans `DOCKER-USER`) ;
- `jail.d/` : un jail par famille de codes HTTP ;
- `filter.d/` : expressions régulières sur les champs `ClientHost` et
  `DownstreamStatus` des access logs Traefik ;
- `network_mode: host` + `NET_ADMIN` sont nécessaires pour iptables ; les
  règles visent `DOCKER-USER`, car les ports publiés par Docker passent par
  `FORWARD` et non par `INPUT`.

```sh
docker compose --env-file .env -f stacks/fail2ban/compose.yaml up -d --build
docker exec fail2ban fail2ban-client status
```

Documentation : [`docs/services/fail2ban.md`](../../docs/services/fail2ban.md).
