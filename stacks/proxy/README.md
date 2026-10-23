# Stack proxy

Traefik est l'unique point d'entrée HTTP/HTTPS et Minecraft TCP.

- `Dockerfile` : image officielle `traefik:3.7.16` + entrypoint de rendu ;
- `entrypoint.sh` : remplace les placeholders `@@...@@` ;
- `templates/traefik.yml.template` : configuration statique ;
- `templates/dynamic/dynamic.yml.template` : TLS, auth, redirections ;
- `auth/` : fichiers htpasswd générés par `make init` (non commités).

```sh
docker compose --env-file .env -f stacks/proxy/compose.yaml up -d --build
```

Documentation : [`docs/services/traefik.md`](../../docs/services/traefik.md).
