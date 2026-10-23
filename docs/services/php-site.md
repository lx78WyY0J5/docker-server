# Site PHP

Futur site PHP d'Altherneum (`php.altherneum.fr`, `phpdoc.altherneum.fr`) avec
sa base MariaDB dédiée `db-php`.

## Composants

| Élément | Détail |
|---|---|
| `php-site` | image `altherneum/php-apache:latest` (Alpine + Apache + PHP par défaut Alpine, actuellement 8.5) |
| `src/` | code du site, monté en **lecture seule** dans `/var/www/html` |
| `db-php` | MariaDB 11.8, volume `altherneum_db-php` |
| réseau interne | `altherneum_php_internal` (app ↔ base) |
| réseau db_admin | permet à phpMyAdmin d'administrer la base |

Le code n'est pas embarqué dans l'image (bind mount) : modifier `src/` suffit,
aucun rebuild n'est nécessaire.

## Variables d'environnement du conteneur

| Variable | Source |
|---|---|
| `DB_HOST` | `db-php` |
| `DB_NAME` | `PHP_DB_NAME` |
| `DB_USER` | `PHP_DB_USER` |
| `DB_PASSWORD` | `PHP_DB_PASSWORD` |

Exemple d'utilisation dans `src/index.php` :

```php
$pdo = new PDO(
    sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', getenv('DB_HOST'), getenv('DB_NAME')),
    getenv('DB_USER'),
    getenv('DB_PASSWORD')
);
```

## Exploitation

```sh
docker compose up -d --build php-site

# console SQL (identifiants lus dans le conteneur)
docker compose exec db-php sh -c \
    'exec mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"'

# logs Apache/PHP
docker compose logs -f php-site
```

## Ajouter des extensions PHP

Les extensions sont installées dans l'image de base
`images/php-apache/Dockerfile` avec les paquets virtuels `php-…` (liste
officielle Alpine : <https://pkgs.alpinelinux.org/packages>). Alpine résout
ces noms vers la version PHP par défaut (actuellement 8.5) : ne pas coder une
version en dur dans le Dockerfile. Ajouter le paquet, puis :

```sh
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
docker compose up -d --build php-site
```

OPcache est compilé dans PHP 8.5 : aucun paquet séparé n'est publié pour cette
version. Les réglages `opcache.*` de
`images/php-apache/php/99-altherneum.ini` restent actifs.

Variables PHP globales : `images/php-apache/php/99-altherneum.ini` ; le
fuseau horaire est injecté au démarrage depuis `TZ`.

## Activer HTTPS / redirections

Le vhost écoute en HTTP : Traefik gère le HTTPS. `AllowOverride All` est actif,
donc un `.htaccess` dans `src/` fonctionne (doc :
<https://httpd.apache.org/docs/2.4/howto/htaccess.html>).

## Migration depuis l'ancien `phpdoc`

Copier les fichiers de l'ancien `/var/www/phpdoc` dans `src/`, puis adapter les
identifiants MySQL aux variables `DB_*`. Si l'ancienne application utilisait
d'autres extensions PHP, les ajouter à l'image de base.
