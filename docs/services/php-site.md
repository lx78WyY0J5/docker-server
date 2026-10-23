# Site PHP

Site PHP d'Altherneum (`php.altherneum.fr`, `phpdoc.altherneum.fr`) avec sa
base MariaDB dédiée `db-php`.

Le code n'est plus le petit `src/index.php` de démonstration : le dépôt
[`lx78WyY0J5/website`](https://github.com/lx78WyY0J5/website) est cloné dans
`stacks/web/php-site/src` et servi depuis son dossier `public/`.

## Composants

| Élément | Détail |
|---|---|
| `php-site` | image `altherneum/php-apache:latest` (Alpine + Apache + PHP par défaut Alpine, actuellement 8.5) |
| `src/` | clone du dépôt `website`, monté dans `/var/www/html` ; racine web : `/var/www/html/public` |
| `db-php` | MariaDB 11.8, volume `altherneum_db-php` |
| réseau interne | `altherneum_php_internal` (app ↔ base) |
| réseau db_admin | permet à phpMyAdmin d'administrer la base |

`stacks/web/php-site/src/` est ignoré par Git dans `docker-server` : le site a
son propre dépôt. Un `git pull` dans ce dossier met le site à jour, sans
reconstruire l'image.

## Installation du site

```sh
# 1. Secrets locaux (dont WEBSITE_ADMIN_PASSWORD)
make init

# 2. Clone du dépôt website + génération de src/.env
make php-site-src

# 3. Démarrage de php-site et de sa base uniquement
make up-service SERVICE=php-site
```

`make up` et `make up-service SERVICE=php-site` clonent automatiquement le
dépôt s'il n'est pas encore présent. Le clone est fait en `--depth 1` sur la
branche définie par `PHP_SITE_REPO_REF` (par défaut `main`).

Variables utiles dans `.env` :

| Variable | Rôle |
|---|---|
| `PHP_SITE_REPO_URL` | URL du dépôt website |
| `PHP_SITE_REPO_REF` | branche/tag à cloner |
| `WEBSITE_ADMIN_USERNAME` | compte administrateur créé dans la base |
| `WEBSITE_ADMIN_PASSWORD` | mot de passe de ce compte (généré par `make init`) |
| `WEBSITE_ADMIN_DISCORD_USER_ID` | optionnel, ID Discord admin |
| `WEBSITE_DISCORD_CLIENT_ID` / `_SECRET` | optionnel, OAuth Discord |
| `WEBSITE_DISCORD_REDIRECT_URI` | vide = `https://php.<DOMAIN>/discord/callback` |
| `WEBSITE_AUTO_INIT` | `true` = crée les tables au premier démarrage |

Après un changement de `DOMAIN`, de mot de passe base ou des variables
`WEBSITE_*`, régénérer le fichier du site :

```sh
make php-site-env
```

Puis recréer le conteneur :

```sh
make restart-service SERVICE=php-site
```

Le fichier `stacks/web/php-site/src/.env` est généré par le Makefile et reste
hors de la racine web. Il ne doit pas être commité dans le dépôt website.

## Base de données et premier démarrage

L'entrypoint attend que `db-php` soit sain (via Compose), vérifie la table
`users` et exécute le script d'initialisation du site si elle manque. Le
fichier `create-db.php` est bloqué côté Apache : il n'est utilisable qu'en CLI
par l'entrypoint.

Pour initialiser manuellement une base vide :

```sh
docker compose exec php-site php /usr/local/bin/php-site-init-db
docker compose exec php-site php /usr/local/bin/php-site-db-ready
```

Le compte admin est celui de `WEBSITE_ADMIN_USERNAME` /
`WEBSITE_ADMIN_PASSWORD`. Le site utilise aussi les dossiers suivants, rendus
accessibles en écriture par l'entrypoint :

- `stacks/web/php-site/src/logs/` ;
- `stacks/web/php-site/src/public/uploads/`.

Le reste du code reste la propriété de l'utilisateur qui a cloné le dépôt :
l'entrypoint ne fait pas de `chown` récursif sur toute la racine web.

## Exploitation

```sh
docker compose up -d --build php-site

# console SQL (identifiants lus dans le conteneur)
docker compose exec db-php sh -c \
    'exec mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"'

# logs Apache/PHP
docker compose logs -f php-site
```

Vérification rapide sans passer par le DNS public :

```sh
curl -sS -o /dev/null -w '%{http_code}\n' \
  "http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' php-site)/"
# 200 (ou 302 selon la page)
```

## Mettre à jour le site

```sh
git -C stacks/web/php-site/src pull --ff-only
# PHP est relu automatiquement (OPcache revalidate_freq=2).
# Redémarrer seulement si l'entrypoint ou l'image a changé :
make restart-service SERVICE=php-site
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
donc un `.htaccess` dans `public/` fonctionne (doc :
<https://httpd.apache.org/docs/2.4/howto/htaccess.html>).

## Migration depuis l'ancien `phpdoc`

Le dépôt website remplace l'ancien site. Si des données existaient dans
l'ancienne base `phpdoc`, les migrer vers `db-php` avant de changer le DNS.
Le schéma est créé par le site ; les identifiants MySQL sont lus depuis
`src/.env`, généré à partir de `PHP_DB_*`.
