# Stack phpMyAdmin

phpMyAdmin 5.2.3, accessible uniquement derrière l'auth HTTP de Traefik et le
réseau `altherneum_db_admin`.

- un seul phpMyAdmin pour toutes les bases, choix du serveur à la connexion ;
- `db-azuriom` et `db-php` sont disponibles via `PMA_HOSTS` ;
- l'authentification HTTP est définie dans
  `stacks/proxy/auth/phpmyadmin.htpasswd` (généré par `make init`).

```sh
docker compose --env-file .env -f stacks/web/phpmyadmin/compose.yaml up -d --build
```

Documentation : [`docs/services/phpmyadmin.md`](../../../docs/services/phpmyadmin.md).
