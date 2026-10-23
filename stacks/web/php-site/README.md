# Stack site PHP

Apache + PHP (version par défaut d'Alpine) + MariaDB dédiée au site PHP.

- `src/` : clone du dépôt [`website`](https://github.com/lx78WyY0J5/website),
  racine web `src/public` ; dossier ignoré par Git dans `docker-server` ;
- `db-php` : MariaDB 11.8, réseau interne + réseau db-admin (phpMyAdmin) ;
- données : volume `altherneum_db-php` ;
- `logs/` et `public/uploads/` sont les seuls dossiers rendus inscriptibles
  par l'entrypoint.

```sh
# à la racine : .env, secrets, clone du site et image de base
make init
make php-site-src
make up-service SERVICE=php-site
```

Pour mettre à jour le site : `git -C stacks/web/php-site/src pull --ff-only`.
Après un changement de domaine ou de secrets : `make php-site-env`, puis
`make restart-service SERVICE=php-site`.

Documentation : [`docs/services/php-site.md`](../../../docs/services/php-site.md).
