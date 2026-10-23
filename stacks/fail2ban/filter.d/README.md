# Filtres fail2ban

Un fichier par famille de requêtes surveillée dans les **logs JSON de
Traefik** (volume `altherneum_traefik-logs`). Les filtres extraient l'IP
cliente (`ClientHost`) puis le code (`DownstreamStatus`) ou le chemin
(`RequestPath`), et alimentent les jails correspondants dans
[`../jail.d/`](../jail.d/).

| Filtre | Code surveillé |
|---|---|
| `traefik-400.conf` | 400 |
| `traefik-401.conf` | 401 (échecs d'authentification) |
| `traefik-403.conf` | 403 |
| `traefik-404.conf` | 404 (scan d'URL) |
| `traefik-405.conf` | 405 |
| `traefik-env.conf` | tentatives sur `.env` et fichiers sensibles |
| `traefik-wp.conf` | scans WordPress |

## Ajouter un filtre

1. copier un filtre existant et adapter `failregex` au champ JSON concerné ;
2. créer le jail correspondant dans `../jail.d/` ;
3. redémarrer fail2ban et vérifier la syntaxe :

```sh
docker compose --env-file .env -f stacks/fail2ban/compose.yaml up -d --build fail2ban
docker exec fail2ban fail2ban-client status
```

La syntaxe des expressions est celle de fail2ban :
<https://fail2ban.readthedocs.io/en/latest/filters.html>. Voir aussi
[fail2ban](../../../docs/services/fail2ban.md) et le
[README de la stack](../README.md).
