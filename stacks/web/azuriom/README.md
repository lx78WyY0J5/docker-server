# Stack Azuriom

CMS Minecraft officiel Azuriom 1.2.13, avec MariaDB dédiée.

- image construite depuis la release officielle épinglée ;
- installation automatique au premier démarrage : migrations, seeders, admin ;
- connexion Microsoft (`mc-online`) : l'admin est lié à son UUID Minecraft via
  `AZURIOM_ADMIN_GAME_ID` ;
- `.env` persistant dans le volume `altherneum_azuriom-config` ;
- MariaDB sur réseau interne + réseau db-admin (phpMyAdmin) ;
- réseau Minecraft pour les pings/RCON depuis Azuriom.

```sh
# image de base requise (ou `make build` à la racine)
docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache
docker compose --env-file .env -f stacks/web/azuriom/compose.yaml up -d --build
```

Documentation : [`docs/services/azuriom.md`](../../../docs/services/azuriom.md).
