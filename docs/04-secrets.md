# Secrets et comptes

## Règle de base

Tous les secrets vivent dans **`.env`**, à la racine du dépôt, avec les
permissions `600`. Ce fichier n'est **jamais** commité (voir `.gitignore`).
`.env.example` sert de modèle documenté.

```sh
ls -l .env          # -rw------- 
```

Conserver une copie de `.env` dans KeeWeb (`https://keeweb.altherneum.fr`) :
sans ce fichier, `AZURIOM_APP_KEY`, `FORGEJO_SECRET_KEY` ou
`VELOCITY_SECRET` ne peuvent plus être régénérés à l'identique.

## Ce que `make init` génère

`scripts/init.sh` remplit uniquement les valeurs vides ou égales à
`CHANGE_ME` : relancer `make init` ne détruit jamais un secret existant.

| Variable | Usage |
|---|---|
| `TRAEFIK_DASHBOARD_PASSWORD` | basic auth du dashboard Traefik |
| `PMA_ADMIN_PASSWORD` | basic auth phpMyAdmin |
| `PHP_DB_ROOT_PASSWORD`, `PHP_DB_PASSWORD` | MariaDB du site PHP |
| `AZURIOM_DB_ROOT_PASSWORD`, `AZURIOM_DB_PASSWORD` | MariaDB d'Azuriom |
| `AZURIOM_APP_KEY` | clé Laravel d'Azuriom (chiffrement) |
| `AZURIOM_ADMIN_PASSWORD` | mot de passe du compte admin créé en CLI (non utilisé pour la connexion web en `mc-online`) |
| `AZURIOM_MAIL_PASSWORD` | compte SMTP `noreply@` (mailcow) |
| `FORGEJO_DB_ROOT_PASSWORD`, `FORGEJO_DB_PASSWORD` | PostgreSQL de Forgejo |
| `FORGEJO_SECRET_KEY`, `FORGEJO_INTERNAL_TOKEN`, `FORGEJO_LFS_JWT_SECRET`, `FORGEJO_OAUTH2_JWT_SECRET` | sécurité Forgejo |
| `FORGEJO_ADMIN_PASSWORD` | compte admin Forgejo |
| `FORGEJO_MAIL_PASSWORD` | compte SMTP `git@` (mailcow) |
| `CODE_SERVER_PASSWORD` | mot de passe code-server |
| `KEEWEB_UI_PASSWORD` | basic auth KeeWeb |
| `KEEWEB_WEBDAV_PASSWORD` | basic auth WebDAV (sync du kdbx) |
| `PMA_BLOWFISH_SECRET` | cookie de chiffrement phpMyAdmin |
| `VELOCITY_SECRET` | forwarding Velocity ↔ Paper |
| `MINECRAFT_RCON_PASSWORD` | RCON des serveurs Paper |

Les mots de passe d'`htpasswd` sont ensuite écrits dans :

- `stacks/proxy/auth/dashboard.htpasswd` et `phpmyadmin.htpasswd` ;
- `stacks/web/keeweb/auth/keeweb.htpasswd` et `webdav.htpasswd`.

Ces fichiers sont ignorés par Git et montés en lecture seule dans les
conteneurs concernés.

## À renseigner manuellement

| Variable | Où l'obtenir |
|---|---|
| `DISCORD_BOT_TOKEN` | <https://discord.com/developers/applications> → Bot → Reset Token |
| `ACME_EMAIL` | adresse de contact Let's Encrypt |
| `AZURIOM_ADMIN_GAME_ID` | UUID Minecraft de l'admin : `curl -s https://api.mojang.com/users/profiles/minecraft/<pseudo>` |
| `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET` | application Microsoft Entra ID (optionnel ; vide = relais OAuth Azuriom) |
| `MAILCOW_DIR` | chemin de l'installation mailcow (défaut `/opt/mailcow-dockerized`) |

`AZURIOM_MAIL_PASSWORD` et `FORGEJO_MAIL_PASSWORD` sont déjà générés par
`make init`. Si mailcow est utilisé, créer les boîtes `noreply@` et `git@`
avec ces valeurs (elles ne sont pas créées automatiquement).

mailcow stocke ses propres secrets dans `mailcow.conf` et `data/conf/`, pas
dans ce `.env`.

## Vérification avant démarrage

```sh
make check-env
```

Le script contrôle les variables obligatoires, le format de l'UUID admin, la
cohérence `AZURIOM_GAME`/`VELOCITY_ONLINE_MODE` et les hôtes dérivés du
domaine. `make up` exécute ce contrôle avant de démarrer les conteneurs.

## Rotation

### Mot de passe simple (compte applicatif)

1. changer la valeur dans `.env` ;
2. pour `TRAEFIK_DASHBOARD_PASSWORD`, `PMA_ADMIN_PASSWORD`, `KEEWEB_*` :
   `make init` régénère les `htpasswd`, puis `docker compose restart traefik`
   (les `htpasswd` de KeeWeb sont lus par Apache à chaque requête) ;
3. pour `CODE_SERVER_PASSWORD` : `make up` recrée le conteneur.

### Mot de passe de base de données

`make init` ne change pas les utilisateurs déjà créés dans MariaDB/PostgreSQL.
Procédure complète :

```sh
# 1. nouveau mot de passe dans .env (PHP_DB_PASSWORD, AZURIOM_DB_PASSWORD…)
$EDITOR .env

# 2. appliquer côté serveur (mots de passe lus dans le conteneur)
docker compose exec -T db-php sh -c 'exec mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' <<'SQL'
ALTER USER 'php_site'@'%' IDENTIFIED BY 'NOUVEAU';
FLUSH PRIVILEGES;
SQL

# Azuriom : même commande sur db-azuriom avec l'utilisateur azuriom.
# Forgejo :
docker compose exec -T db-forgejo sh -c 'exec psql -U "$POSTGRES_USER" -d postgres' <<'SQL'
ALTER USER forgejo WITH PASSWORD 'NOUVEAU';
SQL

# 3. recréer les conteneurs applicatifs
make up
```

> Les noms d'utilisateurs (`php_site`, `azuriom`, `forgejo`) sont ceux par
> défaut : les adapter si `*_DB_USER` a été changé.

### AZURIOM_APP_KEY

Changer la clé d'Azuriom invalide les sessions et les données chiffrées
(certaines valeurs de plugins). En cas de fuite :

```sh
docker compose exec azuriom php artisan key:generate --force
# puis reporter la nouvelle valeur dans .env
```

### VELOCITY_SECRET

Changer `VELOCITY_SECRET` dans `.env` puis `make up` : un `restart` ne recrée
pas les conteneurs et garde l'ancienne valeur. Le secret est réinjecté au
démarrage dans `forwarding.secret` (Velocity) et dans
`config/paper-global.yml` (Paper). Les joueurs n'ont rien à faire.

### FORGEJO_SECRET_KEY / tokens

Voir la documentation Forgejo : <https://forgejo.org/docs/latest/admin/>. En
pratique, régénérer `FORGEJO_SECRET_KEY` invalide les sessions, mais pas les
dépôts. Conserver l'ancienne valeur le temps de la migration.

## Vérifier qu'aucun secret n'est commité

```sh
git status --short          # .env, auth/*.htpasswd ne doivent jamais apparaître
grep -R "CHANGE_ME" .env    # doit être vide une fois l'installation terminée
```

Les `htpasswd` et `.env` sont listés dans `.gitignore`. En cas de doute :

```sh
git check-ignore -v .env stacks/proxy/auth/dashboard.htpasswd
```
