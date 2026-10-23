# Stack site PHP

Apache + PHP (version par défaut d'Alpine) + MariaDB dédiée au futur site PHP.

- `src/` : code de l'application (monté en lecture seule) ;
- `db-php` : MariaDB 11.8, réseau interne + réseau db-admin (phpMyAdmin) ;
- données : volume `altherneum_db-php`.

```sh
# image de base requise (ou `make build` à la racine)
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
docker compose --env-file .env -f stacks/web/php-site/compose.yaml up -d --build
```

Documentation : [`docs/services/php-site.md`](../../../docs/services/php-site.md).
