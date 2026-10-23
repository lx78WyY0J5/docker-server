# phpMyAdmin

Interface d'administration des bases **MariaDB** (`db-php`, `db-azuriom`).
Image officielle `phpmyadmin:5.2.3`.
Docs : <https://docs.phpmyadmin.net/>,
image : <https://github.com/phpmyadmin/docker>.

## Composants

| Élément | Détail |
|---|---|
| `phpmyadmin` | image officielle, port 80 |
| réseau `proxy` | accès Traefik |
| réseau `db_admin` | accès aux bases MariaDB (`altherneum_db_admin`, interne) |
| middleware | `phpmyadmin-auth@file` (basic auth Traefik) |

Forgejo utilise PostgreSQL : il n'est **pas** visible dans phpMyAdmin (utiliser
`psql`, voir [`forgejo.md`](forgejo.md)).

## Accès

`https://phpmyadmin.altherneum.fr`

1. basic auth Traefik (`PMA_ADMIN_USER` / `PMA_ADMIN_PASSWORD`) ;
2. page de connexion phpMyAdmin : choisir le serveur (`db-php` ou
   `db-azuriom`) et utiliser un compte MySQL (par exemple `root` avec
   `PHP_DB_ROOT_PASSWORD` / `AZURIOM_DB_ROOT_PASSWORD`).

La double authentification est volontaire : même si phpMyAdmin est compromis,
la base n'est joignable que sur le réseau interne `db_admin`.

## Configuration

| Variable | Rôle |
|---|---|
| `PMA_HOSTS` | liste des serveurs proposés (`db-azuriom,db-php`) |
| `PMA_ABSOLUTE_URI` | URL publique (cookies/redirections en HTTPS) |
| `PMA_BLOWFISH_SECRET` | chiffrement des cookies de session |
| `UPLOAD_LIMIT` | taille maximale d'import (`64M`) |

Pour ajouter une future base MariaDB :

1. connecter le conteneur de base au réseau `altherneum_db_admin` ;
2. ajouter son nom à `PMA_HOSTS` dans `.env` ;
3. `make up`.

## Sécurité

- aucun port de base n'est publié sur l'hôte ;
- fail2ban surveille les échecs de basic auth (jail `traefik-401`) ;
- possibilité de restreindre par IP avec le middleware `ipAllowList` de
  Traefik si l'administration est réservée à certains réseaux.

## Dépannage

| Symptôme | Piste |
|---|---|
| « Impossible de se connecter au serveur » | la base n'est pas sur `altherneum_db_admin`, ou mauvais mot de passe |
| page blanche / boucle de connexion | `PMA_ABSOLUTE_URI` ne correspond pas au domaine appelé |
| « token mismatch » | cookies bloqués : vérifier `PMA_BLOWFISH_SECRET` et le HTTPS |
| base Forgejo introuvable | normal : PostgreSQL n'est pas géré par phpMyAdmin |
