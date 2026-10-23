# Migration depuis l'ancien serveur

L'ancien serveur (Debian + Apache + systemd + scripts shell) et le nouveau
(`server-v2`, Docker + Traefik) peuvent cohabiter le temps de la migration.
Stratégie : préparer le nouveau serveur, copier les données, vérifier, puis
basculer le DNS.

## Différences de comportement

- **Logs Apache** : l'ancien `logRedirect.sh` envoyait chaque ligne Apache à
  Discord. Ce n'est pas repris : les applications écrivent sur stdout/stderr
  (`docker compose logs`), Traefik écrit un access log JSON et fail2ban s'en
  sert pour bannir. Pour des alertes Discord, utiliser un webhook ou un bot
  dédié, pas une notification par requête.
- **URLs Minecraft** : `mc.<domaine>` et `play.<domaine>` redirigent vers
  `minecraft.<domaine>` (site Azuriom) ; le jeu reste sur
  `mc.<domaine>:25565`. Les URLs par serveur (`hub.`, `survie.`, etc.) sont des
  `[forced-hosts]` Velocity et nécessitent le DNS correspondant (wildcard ou
  entrées dédiées). Geyser/Floodgate sont installés sur Velocity par défaut ;
  leurs configs sont régénérées dans le volume du proxy.
- **Basic auth** : Apache ne protège plus que KeeWeb (UI + WebDAV). Le
  dashboard Traefik et phpMyAdmin utilisent le basic auth Traefik ; Forgejo et
  code-server ont leur authentification native. Roundcube n'est plus déployé :
  la messagerie est mailcow (SOGo).
- **Catch-all Discord** : l'ancien `*.domaine` vers Discord n'est pas reproduit ;
  seules les redirections explicites du template dynamique existent (`lost.`,
  `discord.`, etc.).

## Correspondance des données

| Ancien | Nouveau | Méthode |
|---|---|---|
| `/Serveurs/Hub`, `Survie`, `Creatif`, `Anarchie`, `RPG`, `SkyBlock`, `OPPrison`, `Test` | volumes `altherneum_mc-<nom>-data` (`/data`) | `rsync` via conteneur |
| `/Serveurs/Waterfall` (Velocity) | `altherneum_mc-velocity-data` | config régénérée : reprendre les configs métier des plugins, pas les JAR ni Geyser/Floodgate |
| `/DiscordBot/Data/` | `altherneum_discord-data` (`/DiscordBot/Data`) | `rsync` |
| base MySQL `site` (Azuriom) | `db-azuriom` | dump → import |
| `/var/www/html` (Azuriom : `storage/`) | `altherneum_azuriom-storage` | `rsync` |
| base Forgejo | `db-forgejo` + `altherneum_forgejo-data` | `forgejo dump`/`restore` ou clone/push |
| `kdbx.kdbx` (KeeWeb) | `altherneum_keeweb-webdav` | copie |
| `~/.config/code-server` | `altherneum_code-server-data` | copie |
| `/var/www/meme` | `stacks/web/meme/public` | copie dans le dépôt |
| `/var/www/phpdoc` | `stacks/web/php-site/src` | copie dans le dépôt |
| boîtes mail (si existantes) | mailcow | `imapsync` (voir [`06-mailcow.md`](06-mailcow.md)) |

## 0. Préparation

```sh
# Sur le nouveau serveur
cd /opt/altherneum/server-v2
make init
$EDITOR .env              # DISCORD_BOT_TOKEN, ACME_EMAIL, AZURIOM_ADMIN_GAME_ID
make check-env
make build
make up
make ps                   # tout doit être healthy/running sauf mc-plugins (exited 0)
```

Ne pas encore basculer le DNS. Pour tester avant la bascule, utiliser l'option
`--resolve` de curl et l'IP publique du nouveau serveur :

```sh
curl --resolve meme.altherneum.fr:443:IP_NOUVEAU https://meme.altherneum.fr
```

## 1. Mondes Minecraft

```sh
# Sur l'ancien serveur : arrêter les serveurs (les mondes doivent être fermés proprement)
service minecraft stop
service minecraft@hub stop && … (tous les serveurs)

# Depuis le nouveau serveur, copier un monde dans son volume
docker run --rm -it \
    -v altherneum_mc-survie-data:/target \
    -v /ancre/old:/source:ro \
    alpine:3.24 sh -c 'rm -rf /target/* && cp -a /source/. /target/'
```

- `/ancre/old` contient une copie des dossiers `Serveurs/<Nom>` (rsync/scp) ;
- refaire l'opération pour chaque serveur (la casse des volumes est en
  minuscules : `Survie` → `altherneum_mc-survie-data`, `OPPrison` →
  `altherneum_mc-opprison-data`) ;
- ne pas copier les anciens `paper-global.yml`/`server.properties` : ils sont
  régénérés au démarrage avec le bon secret de forwarding et le bon port ;
- les plugins sont récupérés par `mc-plugins`, seul `plugins/` propre au
  serveur peut être copié si nécessaire.

```sh
docker compose up -d mc-survie   # vérifier les logs : monde chargé
```

## 2. Bot Discord

```sh
docker run --rm -it \
    -v altherneum_discord-data:/target \
    -v /ancre/old/DiscordBot/Data:/source:ro \
    alpine:3.24 sh -c 'cp -a /source/. /target/'
```

`tokens.yml` est régénéré au démarrage depuis `.env` ; ne pas le copier.

## 3. Azuriom (base + fichiers)

```sh
# Sur l'ancien serveur
mysqldump -uroot -p site > site.sql
tar czf azuriom-storage.tgz -C /var/www/html storage

# Sur le nouveau
# a) premier démarrage SANS import pour créer la base et l'admin
make up
docker compose exec azuriom php artisan migrate --force

# b) import du dump (remplace les tables)
docker exec -i db-azuriom sh -c 'exec mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" azuriom' \
    < site.sql

# c) fichiers (resource packs, avatars…)
#    l'entrypoint corrige ensuite les permissions (apache:apache)
docker run --rm -it \
    -v altherneum_azuriom-storage:/target \
    -v /ancre/old:/source:ro \
    alpine:3.24 sh -c 'cp -a /source/storage/. /target/'

# d) nettoyage des caches et vérification
#    (up --force-recreate relit .env, contrairement à restart)
docker compose up -d --force-recreate azuriom
docker compose logs azuriom | tail -n 30
```

L'`APP_KEY` du nouveau `.env` doit rester celle utilisée par l'instance
migrée ; si l'ancienne installation en avait une, la reporter dans `.env`
(`AZURIOM_APP_KEY=…`), sinon les sessions et données chiffrées seront
invalidées.

Vérifier aussi le mode de l'ancienne instance (`AZURIOM_GAME` dans son
`.env`) : le nouveau `.env` doit utiliser le même. `VELOCITY_ONLINE_MODE` doit
être cohérent (`true` avec `mc-online`, `false` avec `mc-offline`). Si
l'ancienne était en `mc-offline` et que le nouveau passe en `mc-online`, les
`game_id` enregistrés sont des UUID hors-ligne et ne correspondront plus aux
comptes Microsoft ; il faut relier les comptes avant de changer de mode.

## 4. Forgejo

Deux méthodes :

```sh
# A. dépôts uniquement : cloner puis pousser (simple, perd les issues/wiki)
#    sur l'ancien : git clone --mirror de chaque dépôt, puis push --mirror

# B. migration complète (recommandée) : dump/restore officiel
#    https://forgejo.org/docs/latest/admin/command-line/
#    sur l'ancien : forgejo dump -c /etc/forgejo/app.ini -f /tmp/forgejo-dump.zip
#    sur le nouveau :
docker compose stop forgejo
docker compose run --rm forgejo forgejo restore \
    --config /data/gitea/conf/app.ini --units all \
    --no-root --file /tmp/forgejo-dump.zip
docker compose up -d forgejo
```

Le volume de sauvegarde local est `altherneum_forgejo-data` ; y déposer le
dump avec un conteneur jetable (`-v altherneum_forgejo-data:/data`) avant la
restauration. Vérifier ensuite que les comptes peuvent se connecter
(les mots de passe restent valides).

## 5. KeeWeb

```sh
docker run --rm -it \
    -v altherneum_keeweb-webdav:/target \
    -v /ancre/old:/source:ro \
    alpine:3.24 sh -c 'cp /source/kdbx.kdbx /target/ && chown 82:82 /target/kdbx.kdbx'
```

Le mot de passe maître du fichier `kdbx` ne change pas ; `KEEWEB_UI_PASSWORD`
et `KEEWEB_WEBDAV_PASSWORD` (`.env`) protègent l'accès web.

## 6. code-server

```sh
docker run --rm -it \
    -v altherneum_code-server-data:/target \
    -v /ancre/old/vscode-config:/source:ro \
    alpine:3.24 sh -c 'cp -a /source/. /target/ && chown -R 1000:1000 /target'
```

Les projets vont dans `altherneum_code-server-workspace`.

## 7. Contenus web statiques

- memes : copier `/var/www/meme/*` dans `stacks/web/meme/public/`, commit,
  `make up` ;
- ancien `phpdoc` : copier dans `stacks/web/php-site/src/`, créer les tables
  dans `db-php` si nécessaire, mettre à jour les identifiants de `src/` avec
  les variables `PHP_DB_*`.

Les redirections Apache de l'ancien serveur sont déjà reproduites dans
`stacks/proxy/templates/dynamic/dynamic.yml.template` (voir
[`services/traefik.md`](services/traefik.md)).

## 8. Bascule DNS

1. réduire les TTL à `300` **au moins 24 h avant** ;
2. arrêter l'ancien Apache/Minecraft ;
3. mettre à jour `A @` et `A *` vers l'IP du nouveau serveur ;
4. surveiller :

```sh
watch -n5 'dig +short altherneum.fr'

curl -sI https://altherneum.fr | head -n1
curl -sI https://minecraft.altherneum.fr | head -n1
```

5. vérifier un certificat (`openssl s_client`) et un serveur Minecraft
   (`velocity` doit voir la connexion dans ses logs) ;
6. remettre les TTL à `3600`.

## 9. Liste de contrôle finale

- [ ] `make ps` : tout `running`/`healthy` ;
- [ ] `https://traefik.altherneum.fr` accessible (basic auth) ;
- [ ] les 8 mondes chargés (joueur à l'`hub` puis portails/`/server`) ;
- [ ] connexions `hub.altherneum.fr:25565` etc. OK ;
- [ ] connexion Bedrock `mc.altherneum.fr:19132` (Geyser/Floodgate, RakNet + signalisation NetherNet) et `19133/udp` OK ;
- [ ] bot Discord en ligne avec ses données ;
- [ ] connexion Azuriom (admin + comptes) et envoi de mail de test ;
- [ ] Forgejo : dépôts, issues, comptes ;
- [ ] KeeWeb ouvre `kdbx.kdbx` ;
- [ ] `make backup` produit un dossier complet ;
- [ ] mailcow : réception et envoi externes (SPF/DKIM) ;
- [ ] fail2ban bannit bien un scan (`fail2ban-client status`).

Conserver l'ancien serveur éteint mais intact pendant une à deux semaines :
un simple changement d'enregistrement `A` suffit à faire machine arrière.
