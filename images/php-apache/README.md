# Image php-apache

Image de base **Apache httpd + PHP** utilisée par les stacks
[`php-site`](../../stacks/web/php-site/README.md) et
[`Azuriom`](../../stacks/web/azuriom/README.md). Elle est taguée localement
`altherneum/php-apache:latest`.

## PHP « latest »

Le Dockerfile n'épingle aucune version majeure. Il utilise les **paquets
virtuels Alpine** :

```dockerfile
php
php-apache2
php-bcmath
php-curl
...
```

`apk` résout ces noms vers la version PHP par défaut du dépôt Alpine. Sur
Alpine 3.24, il s'agit actuellement de **PHP 8.5**. À chaque reconstruction
**sans cache** de l'image, les correctifs de cette version sont récupérés ;
lors d'un changement de version par défaut dans Alpine, l'image suit
automatiquement. `make build` force `--pull --no-cache` sur cette image pour
éviter de réutiliser une ancienne couche `apk`.

Conséquences :

- `/etc/php` est un lien stable créé dans l'image vers `/etc/php<version>` ;
  les configurations vont dans `/etc/php/conf.d/` ;
- sur PHP 8.5, **OPcache est compilé dans PHP** : aucun paquet OPcache séparé
  n'est publié pour cette version. Ne pas ajouter `php-opcache`, car `apk`
  sélectionnerait le paquet d'une version PHP antérieure et créerait un
  conflit ;
- pour **figer** une version, remplacer les paquets virtuels par les paquets
  versionnés (`php85-*`) et taguer l'image `:8.5` ; c'est un choix volontaire à
  documenter.

La contrainte `php` d'Azuriom 1.2.13 autorise PHP 8.5, mais une régression
d'application reste possible : tester l'installation après une montée de
version.

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Alpine 3.24, Apache, PHP et extensions communes |
| `apache/altherneum.conf` | réglages Apache globaux, logs stdout/stderr, `RemoteIP` |
| `php/99-altherneum.ini` | limites PHP et réglages OPcache |
| `entrypoint.sh` | injecte `TZ` dans `/etc/php/conf.d/99-timezone.ini` |

Le vhost de chaque application est fourni par sa propre stack (`apache.conf`).

## Construire

```sh
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
# ou, depuis la racine :
make build
```

## Ajouter une extension

Ajouter le paquet virtuel `php-<extension>` dans la liste du `Dockerfile`,
puis reconstruire l'image et la stack concernée. La liste des paquets est sur
<https://pkgs.alpinelinux.org/packages> (filtrer sur `php`).

```sh
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
docker compose --env-file .env -f stacks/web/php-site/compose.yaml up -d --build
```

## Documentation

- [Site PHP](../../docs/services/php-site.md)
- [Azuriom](../../docs/services/azuriom.md)
- [Installation Alpine](../../docs/02-installation.md)
- Apache sur Alpine : <https://wiki.alpinelinux.org/wiki/Apache_HTTP_Server>
- PHP avec Apache : <https://www.php.net/manual/fr/install.unix.apache2.php>
- Paquets Alpine : <https://pkgs.alpinelinux.org/packages>
