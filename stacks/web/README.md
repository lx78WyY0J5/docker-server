# Applications web

Ce dossier regroupe les stacks HTTP exposées par Traefik. Elles partagent le
réseau `altherneum_proxy`, mais chaque application garde son `compose.yaml`,
son image et, si nécessaire, sa base dédiée.

| Dossier | Rôle | Documentation |
|---|---|---|
| [`meme/`](meme/README.md) | site statique de memes | [meme](../../docs/services/meme.md) |
| [`php-site/`](php-site/README.md) | futur site PHP + MariaDB `db-php` | [site PHP](../../docs/services/php-site.md) |
| [`azuriom/`](azuriom/README.md) | CMS Minecraft Azuriom + MariaDB `db-azuriom` | [Azuriom](../../docs/services/azuriom.md) |
| [`keeweb/`](keeweb/README.md) | KeeWeb + WebDAV pour le fichier `kdbx` | [KeeWeb](../../docs/services/keeweb.md) |
| [`phpmyadmin/`](phpmyadmin/README.md) | administration des bases MariaDB | [phpMyAdmin](../../docs/services/phpmyadmin.md) |

Les applications PHP utilisent l'image commune
[`images/php-apache`](../../images/php-apache/README.md), à construire avant
les stacks :

```sh
make build
docker compose --env-file .env -f stacks/web/php-site/compose.yaml up -d --build
```

Les domaines, redirections et certificats sont gérés par la stack
[`proxy`](../proxy/README.md). Voir aussi l'[index des stacks](../README.md) et
l'[architecture](../../docs/01-architecture.md).
