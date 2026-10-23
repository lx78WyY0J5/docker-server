# Image mariadb

Wrapper de l'image officielle **MariaDB 11.8** pour les bases des projets PHP.
Le seul ajout est le fichier de configuration commun
[`conf.d/99-altherneum.cnf`](conf.d/99-altherneum.cnf).

Réglages apportés :

- `utf8mb4` / `utf8mb4_unicode_ci` par défaut ;
- `skip-name-resolve` (pas de résolution DNS inverse) ;
- `max_connections = 100` ;
- `innodb_buffer_pool_size = 128M` (valeur de départ, à ajuster selon la RAM).

## Utilisation

L'image est utilisée par :

- [`db-php`](../../stacks/web/php-site/README.md) pour le site PHP ;
- [`db-azuriom`](../../stacks/web/azuriom/README.md) pour Azuriom.

Chaque base a son propre volume `altherneum_db-*`, n'est pas publiée sur
l'hôte et rejoint le réseau interne du projet. Seules les bases MariaDB sont
visibles dans [phpMyAdmin](../../docs/services/phpmyadmin.md) via le réseau
`altherneum_db_admin`.

## Construire

```sh
docker build -t altherneum/mariadb:11.8 images/mariadb
# ou, depuis la racine :
make build
```

## Documentation

- [Site PHP](../../docs/services/php-site.md)
- [Azuriom](../../docs/services/azuriom.md)
- [phpMyAdmin](../../docs/services/phpmyadmin.md)
- [Sauvegarde / restauration](../../docs/05-backup-restore.md)
- MariaDB dans Docker : <https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/>
