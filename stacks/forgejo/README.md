# Stack Forgejo

Forgejo 16.0.6 avec PostgreSQL 18 dédié.

- les dépôts et la configuration vivent dans `altherneum_forgejo-data` ;
- la base vit dans `altherneum_db-forgejo` et est dumpée par `make backup` ;
- création du compte admin : `make forgejo-admin` ;
- SSH désactivé (Git uniquement en HTTPS via Traefik).

```sh
docker compose --env-file .env -f stacks/forgejo/compose.yaml up -d --build
make forgejo-admin
```

Documentation : [`docs/services/forgejo.md`](../../docs/services/forgejo.md).
