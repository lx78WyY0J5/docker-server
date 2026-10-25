# Docker Server

## Commandes
`sudo make help`
- **__help__** : Affiche cette aide
- **__init__** : Génère .env, les mots de passe, les htpasswd et les réseaux Docker
- **__check-env__** : Vérifie que .env contient les secrets nécessaires avant make up
- **__ensure-networks__** : Crée les réseaux Docker externes manquants
- **__build__** : Construit les images de base puis celles des stacks
- **__php-site-src__** : Clone le dépôt website dans stacks/web/php-site/src
- **__php-site-env__** : Régénère stacks/web/php-site/src/.env depuis .env
- **__php-base__** : Construit uniquement l'image de base PHP/Apache
- **__mariadb-base__** : Construit uniquement l'image de base MariaDB
- **__postgres-base__** : Construit uniquement l'image de base PostgreSQL
- **__paper-base__** : Construit l'image commune des serveurs Paper
- **__base__** : Construit toutes les images de base
- **__ensure-base__** : Construit les images de base manquantes
- **__up__** : Démarre toute l'infrastructure
- **__down__** : Arrête toute l'infrastructure sans supprimer les conteneurs (les volumes sont conservés)
- **__restart__** : Redémarre toute l'infrastructure
- **__ps__** : Liste l'état des conteneurs
- **__logs__** : Suit les logs de tous les conteneurs
- **__config__** : Valide et affiche la configuration Compose fusionnée
- **__backup__** : Sauvegarde les bases et les volumes applicatifs
- **__restore__** : Restaure une sauvegarde : make restore BACKUP=backups/AAAA...
- **__forgejo-admin__** : Crée le compte admin Forgejo depuis .env
- **__mail-integrate__** : Installe l'override Traefik dans MAILCOW_DIR
- **__mail-up__** : Démarre mailcow avec l'intégration Traefik
- **__mail-down__** : Arrête mailcow
- **__mail-logs__** : Suit les logs de mailcow
- **__clean__** : Supprime tous les conteneurs ET les volumes (DESTRUCTIF, `CONFIRM=yes`)
- **__clean-service__** : Supprime un service ciblé, ses conteneurs et ses volumes exclusifs (DESTRUCTIF, `CONFIRM=yes`)
- **__down-clean__** : Arrête puis supprime tous les conteneurs ET les volumes (DESTRUCTIF, `CONFIRM=yes`)
- **__down-clean-service__** : Arrête puis supprime un service ciblé et ses volumes exclusifs (DESTRUCTIF, `CONFIRM=yes`)
- **__stop__** : Arrête un service (ex: make stop SERVICE=azuriom)
- **__restart-service__** : Redémarre un service (ex: make restart-service SERVICE=azuriom)
- **__logs-service__** : Suit les logs d'un service (ex: make logs-service SERVICE=azuriom)
- **__up-service__** : Démarre un service (ex: make up-service SERVICE=azuriom)
- **__down-service__** : Arrête un service sans supprimer son conteneur (ex: make down-service SERVICE=azuriom)
- **__ps-service__** : État d'un service (ex: make ps-service SERVICE=azuriom)
- **__services__** : Liste tous les noms de services

## Mise à jour du site PHP

Le code du site est monté depuis `stacks/web/php-site/src`. Une mise à jour
modifie donc directement les fichiers lus par le conteneur, sans reconstruction :

```sh
sudo git -C stacks/web/php-site/src pull --ff-only
```

PHP relit les fichiers modifiés (opcache avec `validate_timestamps=1`), donc un
redémarrage n'est pas nécessaire pour du PHP/CSS/JS. L'endpoint `/api/deploy`
exécute la même commande depuis le conteneur, après avoir vérifié que le dernier
run CI de `main` est réussi.

`make up-service SERVICE=php-site` ne fait **pas** de `git pull` : il reconstruit
l'image et redémarre le service. Il faut mettre à jour `src` séparément.

Par défaut, l'entrypoint donne le dépôt à l'utilisateur `apache` pour que le
`git pull` web puisse écrire. Mettre `WEBSITE_GIT_DEPLOY=false` dans `.env` pour
désactiver ce comportement (les fichiers de l'hôte gardent alors leur
propriétaire).

## Arrêt et suppression

| Commande | Portée | Action |
| --- | --- | --- |
| `make down` | Toute l'infrastructure | Arrête les conteneurs sans les supprimer |
| `make down-service SERVICE=nom` | Un seul service | Arrête le conteneur sans le supprimer |
| `make clean` | Toute l'infrastructure | Supprime les conteneurs et les volumes |
| `make clean-service SERVICE=nom` | Un seul service | Supprime le conteneur et ses volumes exclusifs |
| `make down-clean` | Toute l'infrastructure | Arrête puis supprime les conteneurs et les volumes |
| `make down-clean-service SERVICE=nom` | Un seul service | Arrête puis supprime le conteneur et ses volumes exclusifs |

Les commandes `clean`, `clean-service`, `down-clean` et `down-clean-service` sont destructives et exigent `CONFIRM=yes`.
`clean-service` et `down-clean-service` n'acceptent qu'un seul nom de service.
Un volume partagé avec un autre service, ou encore utilisé par un autre conteneur, est conservé.

```sh
sudo CONFIRM=yes make clean-service SERVICE=azuriom
sudo CONFIRM=yes make down-clean-service SERVICE=azuriom
```

## Services
### Bases
- `base` : Images de base PHP/Apache, MariaDB, PostgreSQL, Paper

### Bases de données
- `db-azuriom` : Base de données Azuriom
- `db-forgejo` : Base de données Forgejo
- `db-php` : Base de données pour le site PHP

### Services de développement
- `code-server` : Interface web pour vs-code
- `phpmyadmin` : Gestionnaire PHP via interface web
- `forgejo` : Plateforme Forgejo (PHP)
- `keeweb` : Gestion des mots de passe (`.kdbx` / KeePass)

### Services Web
- `php-site` : Site web PHP
- `meme` : Site de redirection de meme
- `azuriom` : Site de pour serveurs Minecraft

### Services système
- `traefik` : Proxy
- `fail2ban` : Protection anti-brute force
- `bot` : Bot Discord

### Applications AAA
- `mail-integrate` : Override Traefik dans MAILCOW_DIR
- `mail-up` / `mail-down` : Gestion de MailCow
- `mail-logs` : Logs de MailCow

### Applications Minecraft
- `mc-anarchie`, `mc-creatif`, `mc-opprison`, `mc-hub`, `mc-skyblock`, `mc-survie`, `mc-rpg`, `mc-test` : Serveurs de jeu Minecraft
- `mc-plugins` : Plugins pour les serveurs

## Réseaux
Les services communiquent via :
- `PROXY_NETWORK`
  - `forgejo_internal`
  - `minecraft`
  - `azuriom_internal`
  - `db_admin`
  - `php_internal`

## Utilisation
- `sudo make init` - Initialisation (création des secrets, volumes, réseaux)
- `sudo make up` - Démarrage complet
- `sudo make down` - Arrêt complet sans supprimer les conteneurs
- `sudo make down-service SERVICE=azuriom` - Arrêt d'un service sans supprimer son conteneur
- `sudo make services` - Liste complète des services disponibles
- `sudo CONFIRM=yes make clean` - Suppression complète des conteneurs et volumes
- `sudo CONFIRM=yes make clean-service SERVICE=azuriom` - Suppression d'un service et de ses volumes
- `sudo CONFIRM=yes make down-clean-service SERVICE=azuriom` - Arrêt puis suppression d'un service et de ses volumes
