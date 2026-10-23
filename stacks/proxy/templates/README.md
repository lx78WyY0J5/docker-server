# Templates Traefik

Ce dossier contient les modèles de configuration **rendus au démarrage** du
conteneur Traefik par [`entrypoint.sh`](../entrypoint.sh). Les fichiers rendus
vivent dans `/etc/traefik/` (statique) et `/etc/traefik/dynamic/` (dynamique)
et ne doivent pas être modifiés dans le conteneur.

| Fichier | Rôle |
|---|---|
| [`traefik.yml.template`](traefik.yml.template) | configuration statique : entrypoints, providers, ACME |
| [`dynamic/dynamic.yml.template`](dynamic/dynamic.yml.template) | configuration dynamique : TLS, middlewares, routeurs, redirections |

## Placeholders

| Placeholder | Variable `.env` |
|---|---|
| `@@DOMAIN@@` | `DOMAIN` |
| `@@DOMAIN_REGEX@@` | `DOMAIN` avec les points échappés |
| `@@ACME_EMAIL@@` | `ACME_EMAIL` |
| `@@ACME_CA_SERVER@@` | `TRAEFIK_ACME_CA_SERVER` |
| `@@TRAEFIK_LOG_LEVEL@@` | `TRAEFIK_LOG_LEVEL` |
| `@@TRAEFIK_DASHBOARD_HOST@@` | `TRAEFIK_DASHBOARD_HOST` |
| `@@PROXY_NETWORK@@` | `PROXY_NETWORK` |

## Modifier un template

Les templates sont copiés dans l'image : un simple `restart` ne prend pas les
modifications. Reconstruire Traefik puis le recréer :

```sh
docker compose --env-file .env -f stacks/proxy/compose.yaml build traefik
docker compose --env-file .env -f stacks/proxy/compose.yaml up -d traefik
```

Les modifications de **labels** d'un autre service sont, elles, détectées par
le provider Docker sans reconstruction de Traefik.

## Documentation

- [Traefik](../../../docs/services/traefik.md)
- [Stack proxy](../README.md)
- Configuration statique : <https://doc.traefik.io/traefik/reference/static-configuration/file/>
- Configuration dynamique : <https://doc.traefik.io/traefik/reference/dynamic-configuration/file/>
