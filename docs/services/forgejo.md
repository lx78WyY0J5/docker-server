# Forgejo

**Rôle :** forge Git auto-hébergée (dépôts, utilisateurs, issues, wiki).

**Conteneurs :** `forgejo`, `db-forgejo`  
**Adresse :** `https://git.<DOMAIN_NAME><TLD>`  
**Alias :** `https://repo.<domaine>` et `https://forgejo.<domaine>`  
**Exemple :** `https://git.supername.fr`

## Mot de passe

| Variable `.env` | Utilisation |
|---|---|
| `FORGEJO_ADMIN_NAME` | Identifiant admin |
| `FORGEJO_ADMIN_EMAIL` | E-mail admin |
| `FORGEJO_ADMIN_PASSWORD` | Mot de passe admin |
| `FORGEJO_DB_USER` / `FORGEJO_DB_PASSWORD` | Compte PostgreSQL (superutilisateur de l'image) |

> `FORGEJO_DB_ROOT_PASSWORD` existe dans `.env.example` mais n'est pas utilisé
> par la configuration actuelle de `db-forgejo`. Vous pouvez l'ignorer.

Le compte admin n'est **pas** créé automatiquement par le conteneur. Après le
premier démarrage, lancez une seule fois :

```sh
sudo make forgejo-admin
```

Cette commande lit `FORGEJO_ADMIN_*` dans `.env`. Le nom `admin` est réservé par
Forgejo : utilisez un autre nom, par exemple `monprojet`.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `FORGEJO_VERSION` | Version de Forgejo |
| `FORGEJO_DB_NAME` | Nom de la base |
| `FORGEJO_DB_USER` | Utilisateur de la base |
| `FORGEJO_DB_PASSWORD` | Mot de passe de la base |
| `FORGEJO_SECRET_KEY` | Secret applicatif, généré |
| `FORGEJO_INTERNAL_TOKEN` | Jeton interne, généré |
| `FORGEJO_LFS_JWT_SECRET` | Secret LFS, généré |
| `FORGEJO_OAUTH2_JWT_SECRET` | Secret OAuth2, généré |
| `FORGEJO_ADMIN_NAME` | Identifiant admin |
| `FORGEJO_ADMIN_EMAIL` | E-mail admin |
| `FORGEJO_ADMIN_PASSWORD` | Mot de passe admin |
| `FORGEJO_MAIL_*` | Configuration e-mail (optionnelle) |

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=forgejo
sudo make ps-service SERVICE=forgejo
sudo make logs-service SERVICE=forgejo
sudo make forgejo-admin
sudo make stop SERVICE=forgejo
```

`db-forgejo` démarre automatiquement avec Forgejo.

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=forgejo
sudo CONFIRM=yes make clean-service SERVICE=db-forgejo
```

Cela supprime les dépôts, les comptes et la base. **Sauvegardez avant.**

## Comportement actuel

- Les inscriptions publiques sont désactivées : l'admin crée les comptes.
- SSH est désactivé : utilisez HTTPS pour cloner et pousser.
- LFS est activé.
- Le compte admin doit être créé avec `make forgejo-admin`.

## E-mail

Désactivé par défaut (`FORGEJO_MAIL_ENABLED=false`). Une fois mailcow prêt :

```dotenv
FORGEJO_MAIL_ENABLED=true
FORGEJO_MAIL_HOST=mail.monprojet.com
FORGEJO_MAIL_PORT=587
FORGEJO_MAIL_USER=git@monprojet.com
FORGEJO_MAIL_PASSWORD=...
FORGEJO_MAIL_FROM=git@monprojet.com
```

Le mot de passe `FORGEJO_MAIL_PASSWORD` est généré par `make init`. Créez la
boîte `git@` dans mailcow avec le même mot de passe.

## Sauvegarde

`make backup` sauvegarde :

- la base via un dump PostgreSQL `db-forgejo` ;
- le volume `forgejo-data` (dépôts, comptes, configuration).

## Dépannage

- **Impossible de se connecter** : lancez `sudo make forgejo-admin` et vérifiez
  `FORGEJO_ADMIN_*`.
- **Nom admin refusé** : `admin` est réservé, choisissez un autre nom.
- **Erreur de base** : vérifiez `FORGEJO_DB_*` et que `db-forgejo` est
  `healthy`.
- **Clone SSH impossible** : SSH est désactivé, utilisez l'URL HTTPS.
