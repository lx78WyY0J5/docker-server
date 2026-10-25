# phpMyAdmin

**Rôle :** interface web pour administrer les bases MariaDB.

**Conteneur :** `phpmyadmin`  
**Adresse :** `https://phpmyadmin.<DOMAIN_NAME><TLD>`  
**Exemple :** `https://phpmyadmin.altherneum.fr`

## Authentification en deux étapes

1. **Protection HTTP Basic** par Traefik :

| Variable `.env` | Utilisation |
|---|---|
| `PMA_ADMIN_USER` | Identifiant Basic (par défaut `admin`) |
| `PMA_ADMIN_PASSWORD` | Mot de passe Basic, généré par `make init` |

2. **Connexion à la base** dans phpMyAdmin : utilisez un compte MariaDB.

| Base | Compte | Variables `.env` |
|---|---|---|
| Site PHP | root | `PHP_DB_ROOT_PASSWORD` |
| Site PHP | utilisateur | `PHP_DB_USER` / `PHP_DB_PASSWORD` |
| Azuriom | root | `AZURIOM_DB_ROOT_PASSWORD` |
| Azuriom | utilisateur | `AZURIOM_DB_USER` / `AZURIOM_DB_PASSWORD` |

`db-forgejo` est une base PostgreSQL : elle n'est pas accessible via
phpMyAdmin.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `PMA_ADMIN_USER` | Identifiant de la protection HTTP |
| `PMA_ADMIN_PASSWORD` | Mot de passe de la protection HTTP |
| `PMA_HOSTS` | Hôtes MariaDB proposés (`db-azuriom,db-php`) |
| `PMA_BLOWFISH_SECRET` | Secret interne de phpMyAdmin, généré |

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=phpmyadmin
sudo make ps-service SERVICE=phpmyadmin
sudo make logs-service SERVICE=phpmyadmin
sudo make stop SERVICE=phpmyadmin
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=phpmyadmin
```

phpMyAdmin ne stocke pas de données : aucun volume n'est supprimé. Les bases
restent intactes.

## Sécurité

- phpMyAdmin est accessible depuis Internet, protégé par le mot de passe Basic
  **et** par les comptes de base.
- Utilisez un mot de passe fort pour `PMA_ADMIN_PASSWORD`.
- Si vous n'en avez pas besoin, arrêtez-le :

```sh
sudo make stop SERVICE=phpmyadmin
```

- Ne supprimez pas `db_admin` : c'est le réseau interne qui relie phpMyAdmin
  aux bases.

## Dépannage

- **Erreur `mysqli::real_connect()`** : vérifiez `PMA_HOSTS`, que la base est
  démarrée et que `DB_ADMIN_NETWORK` existe.
- **Connexion refusée** : le compte ou le mot de passe ne correspond pas à
  celui enregistré dans la base.
- **401** : mauvais `PMA_ADMIN_USER` / `PMA_ADMIN_PASSWORD`. Relancez
  `sudo make init` après modification de `.env`.
