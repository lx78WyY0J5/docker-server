# Image postgres

Wrapper de l'image officielle **PostgreSQL 18** utilisée par la base
`db-forgejo`. Le Dockerfile ne fait qu'activer l'encodage UTF-8 à
l'initialisation (`POSTGRES_INITDB_ARGS`).

## Utilisation

- [`db-forgejo`](../../stacks/forgejo/README.md) stocke les données de Forgejo
  (comptes, tickets, wiki, etc.) ;
- la base vit dans le volume `altherneum_db-forgejo` et n'est pas publiée sur
  l'hôte ;
- elle est sauvegardée par un `pg_dump` dans `make backup`, pas par une archive
  brute du volume.

## Construire

```sh
docker build -t altherneum/postgres:18 images/postgres
# ou, depuis la racine :
make build
```

## Documentation

- [Forgejo](../../docs/services/forgejo.md)
- [Sauvegarde / restauration](../../docs/05-backup-restore.md)
- Image officielle : <https://hub.docker.com/_/postgres>
- PostgreSQL : <https://www.postgresql.org/docs/>
