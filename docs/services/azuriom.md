# Azuriom

CMS officiel pour serveurs Minecraft. Version : **1.2.13** (release officielle
épinglée). Docs : <https://azuriom.com/docs/>,
dépôt : <https://github.com/Azuriom/Azuriom/releases>.

## Composants

| Élément | Détail |
|---|---|
| `azuriom` | `altherneum/php-apache:latest` + release Azuriom, docroot `/var/www/html/public` |
| `db-azuriom` | MariaDB 11.8, volume `altherneum_db-azuriom` |
| réseaux | `proxy`, `altherneum_azuriom_internal` (privé), `db_admin` (phpMyAdmin), `altherneum_minecraft_internal` (ping/RCON) |
| volumes | `azuriom-storage` (sauvegardé), `azuriom-plugins`, `azuriom-themes`, `azuriom-config` |

L'image PHP suit la version par défaut d'Alpine (actuellement PHP 8.5) ; voir
[`images/php-apache/README.md`](../../images/php-apache/README.md).

## Domaines

`minecraft.` sert le site Azuriom. `mc.` et `play.` redirigent en permanent
vers `minecraft.` : cela garde un seul domaine canonique pour les cookies et
le retour OAuth Microsoft (`APP_URL`).

## Premier démarrage (automatique)

`entrypoint.sh` :

1. génère `/var/www/config/.env` (clé `APP_KEY` persistée dans le volume) ;
2. attend que MariaDB réponde (PDO) ;
3. si `/var/www/config/.installed` est absent :
   `php artisan migrate --force --seed`, lien de stockage, puis création du
   compte admin (`AZURIOM_ADMIN_*`) **si la table `users` est vide** et
   association de `AZURIOM_ADMIN_GAME_ID` en mode `mc-online` ;
4. télécharge le resource pack (`AZURIOM_RESOURCE_PACK_URL`) ;
5. vide les caches, corrige les permissions et lance Apache.

Le fichier `/var/www/config/.installed` marque l'installation : ne le
supprimer que pour forcer une réinstallation (voir dépannage).

```sh
docker compose logs -f azuriom     # suivre l'installation initiale
```

## Configuration

| Variable `.env` | Rôle |
|---|---|
| `AZURIOM_APP_KEY` | clé Laravel (ne jamais la changer sans raison) |
| `AZURIOM_GAME` | `mc-online` (Velocity premium, connexion Microsoft) ou `mc-offline` (comptes locaux) ; doit correspondre à `VELOCITY_ONLINE_MODE` |
| `AZURIOM_ADMIN_GAME_ID` | UUID Minecraft de l'admin, sans tirets (requis au premier démarrage en `mc-online`) |
| `AZURIOM_ADMIN_*` | premier compte administrateur (nom, e-mail, mot de passe CLI) |
| `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET` | application Microsoft Entra ID optionnelle ; vide = relais OAuth officiel Azuriom |
| `AZURIOM_RESOURCE_PACK_URL` | pack de ressources proposé aux joueurs |
| `AZURIOM_MAIL_*` | SMTP mailcow (`log` tant que mailcow n'est pas prêt) |

Le `.env` complet vit dans le volume `altherneum_azuriom-config` et est
régénéré depuis les variables à chaque démarrage : toute modification doit
passer par `.env` (ou être faite dans l'interface d'administration).

## Connexion Microsoft (`mc-online`)

Par défaut, Velocity est en `online-mode=true` (`VELOCITY_ONLINE_MODE=true`) :
les joueurs utilisent un compte Minecraft premium. `AZURIOM_GAME=mc-online`
active donc la connexion Microsoft sur le site et stocke l'UUID premium du
joueur (au lieu d'un UUID hors-ligne).

Au premier démarrage, `AZURIOM_ADMIN_GAME_ID` est **obligatoire** : c'est
l'UUID Minecraft du compte admin, sans tirets (32 caractères hexadécimaux).
Pour l'obtenir :

```sh
curl -s https://api.mojang.com/users/profiles/minecraft/<pseudo>
# {"id":"0123456789abcdef0123456789abcdef","name":"<pseudo>"}
# → reporter id dans AZURIOM_ADMIN_GAME_ID
```

L'entrypoint crée le compte admin (`AZURIOM_ADMIN_*`) puis associe cet UUID.
Au premier clic sur « Connexion avec Microsoft », Azuriom retrouve le compte
par UUID et ouvre la session. `AZURIOM_ADMIN_PASSWORD` ne sert alors qu'à la
création CLI du compte, pas à la connexion web.

URI de redirection : `https://minecraft.${DOMAIN}/user/login/callback`.

- `MICROSOFT_CLIENT_ID` et `MICROSOFT_CLIENT_SECRET` vides : Azuriom utilise
  son relais OAuth officiel (`xbox-api.azuriom.com`), aucun compte Azure à
  créer ;
- pour une application Microsoft Entra ID dédiée, renseigner les deux valeurs
  et déclarer l'URI de redirection ci-dessus :
  <https://learn.microsoft.com/entra/identity-platform/quickstart-register-app>.

Pour un serveur non premium, utiliser `AZURIOM_GAME=mc-offline`,
`VELOCITY_ONLINE_MODE=false` et laisser `AZURIOM_ADMIN_GAME_ID` vide : les
comptes sont alors locaux et les UUID calculés hors-ligne. Les deux variables
doivent être changées ensemble, puis `make up` (un `restart` ne prend pas les
nouvelles variables). Ne pas changer de mode sur une base existante sans
relier les comptes : les `game_id` enregistrés ne correspondent plus.

## Intégration Minecraft

Azuriom est connecté au réseau interne Minecraft : dans l'administration,
déclarer les serveurs avec leurs noms de conteneurs :

| Serveur | Hôte | Port |
|---|---|---|
| Hub | `mc-hub` | 25565 |
| Survie | `mc-survie` | 25565 |
| Créatif | `mc-creatif` | 25565 |
| Anarchie | `mc-anarchie` | 25565 |
| RPG | `mc-rpg` | 25565 |
| SkyBlock | `mc-skyblock` | 25565 |
| OPPrison | `mc-opprison` | 25565 |
| Test | `mc-test` | 25565 |

RCON : port `25575`, mot de passe `MINECRAFT_RCON_PASSWORD` (`.env`).
Les joueurs Java se connectent à Velocity (`mc.altherneum.fr:25565`) ; les
joueurs Bedrock passent par Geyser (`mc.altherneum.fr:19132`, TCP/UDP, et
`19133/udp` pour NetherNet).

## Extensions et thèmes

Installer depuis l'interface (marché Azuriom) : plugins dans
`/var/www/html/plugins`, thèmes dans `/var/www/html/themes` (volumes dédiés).

En CLI, télécharger un plugin du marché puis l'activer :

```sh
docker compose exec azuriom php artisan plugin:download <id-marche>
# activer dans l'administration, ou :
docker compose exec azuriom php artisan plugin:enable <id-plugin>
```

L'identifiant du marché peut différer de l'`id` du plugin (dossier installé).

Pour une archive téléchargée manuellement, l'extraire dans
`/var/www/html/plugins/<id>` (ou `themes/<id>`), puis activer le plugin avec
`plugin:enable <id>`. Un thème se choisit ensuite dans l'administration
(Apparence). L'archive doit contenir `plugin.json` ou `theme.json` à sa racine.

## Mise à jour

```sh
# .env
AZURIOM_VERSION=1.2.14

make build && make up
```

L'entrypoint applique `php artisan migrate --force` à chaque démarrage : les
migrations sont donc jouées automatiquement. Sauvegarder avant :

```sh
make backup
```

## Commandes utiles

```sh
docker compose exec azuriom php artisan about
docker compose exec azuriom php artisan user:create --admin
docker compose exec azuriom php artisan queue:work --once   # si un plugin l'exige
docker compose exec azuriom php artisan plugin:disable <id>
```

## Dépannage

| Symptôme | Action |
|---|---|
| erreur 500 au premier accès | `docker compose logs azuriom` ; souvent la base n'était pas prête |
| admin non créé | supprimer `/var/www/config/.installed` et redémarrer |
| connexion Microsoft impossible | vérifier `AZURIOM_ADMIN_GAME_ID` (UUID sans tirets) et l'URI de redirection |
| `AZURIOM_GAME=mc-online exige AZURIOM_ADMIN_GAME_ID` | renseigner l'UUID Minecraft de l'admin dans `.env` puis `make up` |
| pages cassées après migration | vider les caches : `php artisan optimize:clear` |
| téléchargements de plugins échouent | vérifier l'accès Internet du conteneur (`proxy`) et l'espace disque |
