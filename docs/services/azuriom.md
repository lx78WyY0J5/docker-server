# Azuriom

**Rôle :** site et panneau d'administration pour un serveur Minecraft.

**Conteneurs :** `azuriom`, `db-azuriom`  
**Adresse :** `https://minecraft.<DOMAIN_NAME><TLD>`  
**Administration :** `https://minecraft.<DOMAIN_NAME><TLD>/admin`  
**Exemple :** `https://minecraft.supername.fr`

## Mot de passe

| Variable `.env` | Utilisation |
|---|---|
| `AZURIOM_ADMIN_NAME` | Identifiant admin |
| `AZURIOM_ADMIN_PASSWORD` | Mot de passe admin, généré par `make init` |
| `AZURIOM_ADMIN_EMAIL` | E-mail admin |
| `AZURIOM_DB_USER` / `AZURIOM_DB_PASSWORD` | Compte de la base |
| `AZURIOM_DB_ROOT_PASSWORD` | Compte root MariaDB |

Le compte admin est créé au premier démarrage. Changer
`AZURIOM_ADMIN_PASSWORD` dans `.env` ensuite ne modifie pas le compte existant :
utilisez l'interface d'administration.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `AZURIOM_VERSION` | Version d'Azuriom |
| `AZURIOM_SHOP_VERSION` | Version du plugin Shop installée au premier démarrage |
| `AZURIOM_PRISM_VERSION` | Version du thème Prism installée et synchronisée au démarrage |
| `AZURIOM_DB_NAME` | Nom de la base |
| `AZURIOM_DB_USER` | Utilisateur de la base |
| `AZURIOM_DB_PASSWORD` | Mot de passe de la base |
| `AZURIOM_APP_KEY` | Clé applicative, générée |
| `AZURIOM_GAME` | `mc-online` (premium) ou `mc-offline` |
| `AZURIOM_ADMIN_GAME_ID` | UUID Minecraft de l'admin, sans tirets |
| `AZURIOM_ADMIN_NAME` | Identifiant admin |
| `AZURIOM_ADMIN_EMAIL` | E-mail admin |
| `AZURIOM_ADMIN_PASSWORD` | Mot de passe admin |
| `AZURIOM_RESOURCE_PACK_URL` | URL source du resource pack, téléchargé dans le volume puis servi sous `/storage/zip/resourcePack.zip` |
| `AZURIOM_MAIL_*` | Configuration e-mail |
| `MICROSOFT_CLIENT_ID` / `MICROSOFT_CLIENT_SECRET` | OAuth Microsoft (optionnel) |

## Mode premium ou hors-ligne

| Mode | `AZURIOM_GAME` | `VELOCITY_ONLINE_MODE` | `AZURIOM_ADMIN_GAME_ID` |
|---|---|---|---|
| Premium (Microsoft) | `mc-online` | `true` | Obligatoire au premier démarrage |
| Hors-ligne | `mc-offline` | `false` | Ignoré |

Choisissez le mode **avant** le premier démarrage. En `mc-online`, Azuriom
refuse de démarrer sans l'UUID du compte admin.

Pour obtenir l'UUID :

```sh
curl -s https://api.mojang.com/users/profiles/minecraft/<pseudo>
```

Gardez les 32 caractères hexadécimaux, sans tirets.

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=azuriom
sudo make ps-service SERVICE=azuriom
sudo make logs-service SERVICE=azuriom
sudo make stop SERVICE=azuriom
```

`db-azuriom` démarre automatiquement avec Azuriom. Le premier démarrage peut
prendre plusieurs minutes (migrations et création de l'admin).

## Données de démonstration (seed)

Au premier démarrage, Azuriom importe automatiquement les données de l'ancien
serveur pour éviter de reconfigurer le site :

- paramètres généraux, liens sociaux et éléments de menu ;
- images du site (`storage/app/public/img`) et images des packages
  (`storage/app/public/packages`) ;
- catégories et packages de la boutique ;
- rôles et permissions ;
- vue personnalisée `resources/views/custom/body.blade.php`.

Le thème **Prism** et le plugin **Shop** nécessaires à ces données sont
installés automatiquement depuis le market Azuriom. Les versions sont
configurables avec `AZURIOM_PRISM_VERSION` et `AZURIOM_SHOP_VERSION`.

Le thème doit être en version **1.1.0** ou plus récente : les versions 0.1.x
utilisent Bootstrap 4/Font Awesome et n'affichent ni les icônes Bootstrap ni la
couleur rouge configurée dans les données d'origine. Au démarrage, le thème
est mis à jour automatiquement si sa version diffère de celle embarquée dans
l'image.

Les fichiers sources sont dans `stacks/web/azuriom/seed/`. L'import SQL n'a
lieu qu'une seule fois : le marqueur `/var/www/config/.installed` indique que
l'installation est terminée. Les images et la vue personnalisée sont recopiées
à chaque démarrage, et le thème est resynchronisé lorsque sa version change,
car ils ne sont pas tous dans un volume persistant.

Pour réappliquer les données sur une installation existante, reconstruisez
d'abord l'image puis lancez le script :

```sh
sudo make up-service SERVICE=azuriom
sudo CONFIRM=yes make azuriom-seed
```

Cette commande réécrit les paramètres, rôles et données de la boutique définis
dans les fichiers SQL. Elle ne supprime pas les comptes utilisateurs.

L'URL du site et la configuration mail sont remplacées par les valeurs du
`.env` (`APP_URL`, `AZURIOM_MAIL_*`) après l'import : les anciennes valeurs
`play.Altherneum` et `mailhog` de l'ancien serveur ne sont donc pas utilisées.

> Le plugin Shop 0.2.26 utilise encore `Blueprint::unsignedDecimal()`, retiré de
> Laravel 12. Ses migrations sont adaptées automatiquement pendant la
> construction de l'image Azuriom.

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=azuriom
sudo CONFIRM=yes make clean-service SERVICE=db-azuriom
```

Cela supprime le site, ses volumes et la base. **Sauvegardez avant.**

## E-mail

Par défaut, `AZURIOM_MAIL_MAILER=log` : les e-mails ne sont pas envoyés. Une
fois mailcow configuré :

```dotenv
AZURIOM_MAIL_MAILER=smtp
AZURIOM_MAIL_HOST=mail.monprojet.com
AZURIOM_MAIL_PORT=587
AZURIOM_MAIL_USERNAME=noreply@monprojet.com
AZURIOM_MAIL_PASSWORD=...
AZURIOM_MAIL_ENCRYPTION=tls
AZURIOM_MAIL_FROM_ADDRESS=noreply@monprojet.com
```

Le mot de passe de la boîte `noreply@` est `AZURIOM_MAIL_PASSWORD`, généré par
`make init`. Il doit être créé dans mailcow avec le même mot de passe.

## Sauvegarde

`make backup` sauvegarde :

- la base via un dump `db-azuriom` ;
- les volumes `azuriom-storage`, `azuriom-plugins`, `azuriom-themes` et
  `azuriom-config`.

## Dépannage

- **Le conteneur redémarre en boucle** : vérifiez `AZURIOM_ADMIN_GAME_ID` et
  `AZURIOM_GAME` au premier démarrage.
- **Erreur de base** : vérifiez `AZURIOM_DB_*`.
- **Pas d'e-mail** : gardez `AZURIOM_MAIL_MAILER=log` tant que mailcow n'est
  pas prêt.
- **Accès admin** : `/admin` sur le domaine Azuriom.
