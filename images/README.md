# Images de base

Ce dossier contient les **Dockerfiles des images communes** construites
localement. Elles ne contiennent pas de code applicatif : elles partent
d'images officielles et ajoutent uniquement la configuration partagée.

| Dossier | Rôle | Tag local |
|---|---|---|
| [`php-apache/`](php-apache/README.md) | Apache httpd + PHP pour `php-site` et Azuriom | `altherneum/php-apache:latest` |
| [`mariadb/`](mariadb/README.md) | MariaDB 11.8 + réglages communs | `altherneum/mariadb:11.8` |
| [`postgres/`](postgres/README.md) | PostgreSQL 18 pour Forgejo | `altherneum/postgres:18` |

L'ordre de construction est important : `make build` construit d'abord ces
images, puis les stacks qui les utilisent. Pour construire une seule image :

```sh
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
docker build -t altherneum/mariadb:11.8 images/mariadb
docker build -t altherneum/postgres:18 images/postgres
```

Les versions des logiciels sont documentées dans chaque sous-dossier. La
politique générale (images officielles, pas d'image communautaire) est décrite
dans l'[architecture](../docs/01-architecture.md) et le
[README principal](../README.md).
