# Minecraft

L'infrastructure MC d'Altherneum : **Velocity 4.3.0** (Java 25) comme proxy
unique et **8 serveurs Paper 1.21.11** derrière lui. Docs officielles :
<https://docs.papermc.io/velocity/> et <https://docs.papermc.io/paper/>.

## Topologie

```text
joueur Java    ──▶ mc.altherneum.fr:25565   (Traefik, routeur TCP)
joueur Bedrock ──▶ mc.altherneum.fr:19132   (RakNet UDP + signalisation TCP)
                    mc.altherneum.fr:19133   (NetherNet WebRTC UDP)
                    │
              ┌─────▼─────┐
              │ velocity  │  online-mode configurable, forwarding modern
              │ + Geyser  │  cross-play Bedrock
              │ +Floodgate│
              └─┬──┬──┬───┘
      ┌─────────┘  │  └──────────────┐
   ┌──▼──┐  ┌─────▼────┐      ┌──────▼─────┐
   │hub  │  │ survie…  │  …   │ test       │   8 × Paper (interne :25565)
   └─────┘  └──────────┘      └────────────┘
```

| Conteneur | Serveur | Volume de données |
|---|---|---|
| `velocity` | proxy | `altherneum_mc-velocity-data` |
| `mc-hub` | Hub | `altherneum_mc-hub-data` |
| `mc-survie` | Survie | `altherneum_mc-survie-data` |
| `mc-creatif` | Créatif | `altherneum_mc-creatif-data` |
| `mc-anarchie` | Anarchie | `altherneum_mc-anarchie-data` |
| `mc-rpg` | RPG | `altherneum_mc-rpg-data` |
| `mc-skyblock` | SkyBlock | `altherneum_mc-skyblock-data` |
| `mc-opprison` | OPPrison | `altherneum_mc-opprison-data` |
| `mc-test` | Test | `altherneum_mc-test-data` |
| `mc-plugins` | init (téléchargement) | `altherneum_mc-plugins` |

Tous les serveurs Paper écoutent sur `25565` **à l'intérieur de leur
conteneur** : pas de conflit de ports. Ils ne sont joignables que via le
réseau `altherneum_minecraft_internal` (Velocity, et Azuriom pour
ping/RCON/API).

> En démarrant ces conteneurs, l'opérateur accepte l'EULA de Mojang
> (`eula.txt` est généré avec `eula=true`) : <https://aka.ms/MinecraftEULA>.

## Démarrage

```sh
make up                    # mc-plugins se lance une fois puis s'arrête
make logs                  # ou : docker compose logs -f mc-survie
```

L'ordre est garanti par `depends_on: service_completed_successfully` :
`mc-plugins` télécharge les JAR, puis Velocity et les serveurs démarrent.
Chaque serveur recopie les plugins dans son dossier `/data/plugins` à chaque
démarrage.

## Configuration

### `.env`

| Variable | Rôle | Défaut |
|---|---|---|
| `MINECRAFT_PORT` | port publié par Traefik | `25565` |
| `MINECRAFT_LEVEL_NAME` | nom du monde | `Spawn` |
| `MINECRAFT_MAX_PLAYERS` | joueurs par serveur Paper | `20` |
| `MINECRAFT_MEMORY_HUB` … | RAM allouée à chaque serveur | `1G` (`512M` pour `test`) |
| `VELOCITY_MEMORY` | RAM de Velocity | `512M` |
| `VELOCITY_SECRET` | secret de forwarding (généré par `make init`) | — |
| `VELOCITY_ONLINE_MODE` | `true` = authentification Mojang (premium), `false` = comptes hors-ligne | `true` |
| `MINECRAFT_RCON_PASSWORD` | RCON des Paper | — |
| `VELOCITY_MOTD` | MOTD optionnel du proxy | `<#09add3>Altherneum.fr` |

> `VELOCITY_MOTD` est inséré par `sed` : éviter les caractères `|` et `&` dans
> la valeur (utiliser les codes couleur Minecraft `§` ou `<#rrggbb>`).

### `server.properties` (généré à chaque démarrage)

Le fichier est réécrit depuis `stacks/minecraft/paper/entrypoint.sh` :
`online-mode=false` (authentification faite par Velocity), `enforce-secure-profile=false`,
`difficulty=easy`, `max-players`, `enable-rcon=true`, `spawn-protection=0`,
`motd=${SERVER_NAME}${DOMAIN_NAME}.${TLD}`, serveur en écoute sur `0.0.0.0`. Toute
personnalisation durable doit être faite **dans l'entrypoint**.

### `config/paper-global.yml`

Le secret de forwarding est réinjecté à chaque démarrage
(`proxies.velocity.secret`) ; le reste vient de
`stacks/minecraft/paper/config/paper-global.yml` (timings, anti-xray, etc.).
L'entrypoint force aussi `perform-username-validation: false` : les pseudos
Bedrock préfixés par Floodgate (`.` + pseudo) ne respectent pas la regex Java.

### `velocity.toml`

Généré depuis `stacks/minecraft/velocity/config/velocity.toml.template` :

- `online-mode = ${VELOCITY_ONLINE_MODE}` et
  `force-key-authentication` de même valeur : `true` pour les comptes premium,
  `false` pour les comptes hors-ligne ;
- `player-info-forwarding-mode = "modern"` ;
- `prevent-client-proxy-connections = false` : Traefik termine le TCP sur
  `25565`, donc Velocity voit l'IP du conteneur Traefik et non celle du joueur.
  Laisser `false`, sinon tous les joueurs Java sont kickés ;
- `[servers]` : correspondance nom → `mc-<nom>:25565` ;
- `[forced-hosts]` : `hub.altherneum.fr`, `survie.altherneum.fr`, etc. : un
  joueur qui se connecte à ces noms est envoyé directement sur le bon serveur,
  sans passer par le Hub. Le template contient `\${DOMAIN_NAME}.\${TLD}`, remplacé au
  démarrage par la valeur de `<${DOMAIN_NAME}.${TLD}>` ; changer de domaine met donc aussi à
  jour ces hôtes.

Pour modifier durablement la configuration de Velocity, éditer le template
puis reconstruire l'image (le template est copié dedans) :
`docker compose up -d --build velocity`.

### Mode premium / hors-ligne

`VELOCITY_ONLINE_MODE` est injecté à la fois dans `velocity.toml` et dans
`paper-global.yml` (`proxies.velocity.online-mode`) à chaque démarrage :

| `VELOCITY_ONLINE_MODE` | `AZURIOM_GAME` | Usage |
|---|---|---|
| `true` (défaut) | `mc-online` | comptes Microsoft/premium |
| `false` | `mc-offline` | comptes locaux, serveur non premium |

Changer de mode exige `make up` : un simple `restart` ne recrée pas les
conteneurs et conserve l'ancien environnement. Les deux variables doivent
rester cohérentes. Sur une base Azuriom existante, les `game_id` enregistrés
diffèrent entre les deux modes : relier les comptes avant de basculer (voir
[`azuriom.md`](azuriom.md#connexion-microsoft-mc-online)).

> En mode hors-ligne, l'identité n'est plus vérifiée par Mojang : n'importe qui
> peut prendre un pseudo existant. À réserver aux tests ou à une communauté de
> confiance, avec une whitelist si nécessaire.

## Plugins

Téléchargés par `mc-plugins` (`stacks/minecraft/plugins/fetch-plugins.sh`) :

| Plugin | Version | Cible |
|---|---|---|
| Altherneum (plugin maison) | dernière release | Paper |
| ViaVersion | 5.12.1 | Paper |
| ViaBackwards | 5.12.1 | Paper |
| WorldEdit | 7.4.6 | Paper |
| Geyser | latest | Velocity |
| Floodgate | latest | Velocity |

Floodgate n'est installé que sur Velocity : c'est le mode officiel recommandé
quand les serveurs Paper n'utilisent pas l'API Floodgate. Il n'y a donc ni
`Floodgate-Spigot` ni base SQLite sur les Paper.

Geyser 2.12 nécessite Velocity 4.x (API Adventure récente) : Velocity 3.5.1
provoque un `NoSuchMethodError` au chargement de Geyser. L'image Velocity est
donc épinglée sur **4.3.0** avec **Java 25**. Paper utilise également
**Java 25** : WorldEdit 7.4.6 est compilé en classe Java 25 (version 69) et ne
se charge pas sur Java 21. Ne pas revenir à Java 21 pour les images Velocity
ou Paper.

- mise à jour : éditer les versions/URLs dans `fetch-plugins.sh`, puis
  `docker compose build mc-plugins`,
  `docker compose rm -sf mc-plugins || true` et
  `docker compose run --rm mc-plugins` (téléchargement terminé avant de
  continuer), enfin `docker compose restart velocity mc-hub mc-survie …`
  (recopie des JAR) ;
- le plugin Altherneum est publié ici :
  <https://github.com/Altherneum/plugin/releases> ;
- ViaVersion permet aux clients récents/anciens de se connecter
  (<https://viaversion.com/>) ;
- **Geyser + Floodgate** activent le cross-play Bedrock (voir ci-dessous).

### Cross-play Bedrock (Geyser + Floodgate)

Geyser et Floodgate tournent **uniquement sur Velocity**. Les joueurs Bedrock
se connectent sur `mc.altherneum.fr`, port `19132` (ou
`mc.altherneum.fr:19132` sur les clients qui demandent explicitement le port).

1. **Ports Bedrock** : `stacks/minecraft/compose.yaml` publie directement
   `19132/tcp` (signalisation NetherNet), `19132/udp` (RakNet) et
   `19133/udp` (WebRTC NetherNet) sur le conteneur `velocity`. Traefik
   n'intervient pas pour ces flux ; ouvrir les trois ports dans le pare-feu du
   VPS et chez le fournisseur.
2. **Config Geyser** : générée au premier démarrage dans
   `/data/plugins/Geyser-Velocity/config.yml` à partir de
   [`geyser.yml.template`](../../stacks/minecraft/velocity/config/geyser.yml.template).
   Le template active `transport: both` : les anciens clients utilisent RakNet
   sur `19132/udp`, les clients récents NetherNet via `19132/tcp` et
   `19133/udp`. NetherNet est requis par les nouveaux clients Bedrock depuis
   octobre 2026 ; ne pas revenir à `raknet` seul. `advertise-addresses`
   annonce `mc.<<${DOMAIN_NAME}.${TLD}>>` (port `19133` ajouté automatiquement) : ce nom doit
   résoudre publiquement avant le démarrage de Velocity.
3. **Config Floodgate** : générée dans `/data/plugins/floodgate/config.yml` à
   partir de [`floodgate.yml.template`](../../stacks/minecraft/velocity/config/floodgate.yml.template).
4. **Clé** : l'entrypoint génère `/data/plugins/floodgate/key.pem` (clé
   AES-128 brute attendue par Floodgate) si elle n'existe pas. Elle est
   persistée dans le volume `altherneum_mc-velocity-data` : ne pas la publier.
5. `VELOCITY_ONLINE_MODE` peut rester à `true` : Floodgate gère les joueurs
   Bedrock même quand le proxy vérifie les comptes Java auprès de Mojang. Le
   passer à `false` seulement pour un serveur non premium
   (`AZURIOM_GAME=mc-offline`).
6. `perform-username-validation` est forcé à `false` côté Paper, sinon les
   pseudos Bedrock sont rejetés.

Après une modification des templates, reconstruire l'image Velocity
(`docker compose up -d --build velocity`) puis supprimer les configs du volume
si l'on veut les régénérer. Les logs Geyser/Floodgate sont dans
`docker compose logs velocity`.

### Resource pack

Le pack livré par Azuriom (`pack.mcmeta`) est un **pack Java**. Il est déclaré
dans `server.properties` de chaque serveur Paper via
`resource-pack=https://minecraft.<<${DOMAIN_NAME}.${TLD}>>/storage/zip/resourcePack.zip`.
Il n'est **pas** envoyé à Geyser : un pack Bedrock exige un `manifest.json`,
pas un `pack.mcmeta`. C'est pourquoi `resource-pack-urls` est vide dans
`geyser.yml.template`. Si un pack Bedrock est ajouté plus tard, renseigner son
URL dans ce template, reconstruire Velocity et supprimer
`/data/plugins/Geyser-Velocity/config.yml` pour le régénérer.

## Réseau et premier démarrage hors ligne

Les serveurs Paper sont sur deux réseaux :

- `altherneum_minecraft_internal` (`internal: true`) pour Velocity ↔ Paper et
  Azuriom (ping/RCON) ;
- `altherneum_minecraft_egress` (bridge non interne) pour la **sortie
  Internet uniquement** : le plugin Altherneum vérifie `google.fr`/`discord.com`
  et Paper récupère les clés Mojang. Aucun port n'est publié sur ce réseau.

Paper n'a donc pas d'accès entrant, mais peut joindre Internet. L'image Paper
pré-télécharge au build le jar Mojang et le jar patché (`PAPER_VERSION`) ;
l'entrypoint les copie dans `/data/cache` et `/data/versions` avant le premier
démarrage. Sans ce cache, Paper échouerait sur
`UnknownHostException: piston-data.mojang.com` puisque le réseau `internal`
n'a pas de DNS externe.

## Ajouter un serveur

1. copier un bloc `mc-<nom>` dans `compose.yaml` (mêmes ancres YAML) ;
2. ajouter son volume dans la section `volumes:` ;
3. déclarer le serveur dans `velocity.toml.template` (`[servers]` et, si
   voulu, `[forced-hosts]`) ;
4. `docker compose up -d` puis `docker compose up -d --build velocity`
   (le template est copié dans l'image).

## Jouer

| Adresse | Résultat |
|---|---|
| `mc.altherneum.fr:25565` | connexion au Hub (puis `/server <nom>`) |
| `hub.altherneum.fr:25565` | Hub directement |
| `survie.altherneum.fr:25565`, `anarchie`, `rpg`, `skyblock`, `creatif`, `opprison`, `test` | serveur correspondant |
| `mc.altherneum.fr:19132` (TCP + UDP) | connexion Bedrock via Geyser (RakNet + signalisation NetherNet) |
| `mc.altherneum.fr:19133` (UDP) | transport WebRTC NetherNet (annoncé automatiquement) |

Le port Java public est `MINECRAFT_PORT` (par défaut 25565, celui publié par
Traefik). Les ports Bedrock `19132/tcp`, `19132/udp` et `19133/udp` sont
publiés directement par Compose.

## RCON et Azuriom

RCON est actif (`25575`, mot de passe `MINECRAFT_RCON_PASSWORD`). Azuriom,
connecté au réseau interne, peut s'y connecter avec les noms `mc-hub`,
`mc-survie`, etc. Un serveur par défaut pour les nouveaux joueurs est
généralement le Hub.

## Sauvegarde et migration

- chaque monde est dans un volume sauvegardé par `make backup` (voir
  [`../05-backup-restore.md`](../05-backup-restore.md)) ;
- migration des anciens mondes : [`../08-migration.md`](../08-migration.md) ;
- arrêter un serveur avant de restaurer son volume.

## Dépannage

| Symptôme | Piste |
|---|---|
| connexion refusée de l'extérieur | routeur TCP `velocity` absent, port `25565/tcp` fermé, conteneur arrêté |
| « Please use a proxy » / erreurs de forwarding | secret différent entre Velocity et Paper → `make up` (recréation pour relire `.env`) |
| « Invalid session » avec des comptes locaux | `VELOCITY_ONLINE_MODE=true` alors qu'il faut `false` (et inversement pour le premium) |
| Bedrock ne voit pas le serveur | `19132/udp`, `19132/tcp` ou `19133/udp` fermé sur le VPS, port occupé, ou `velocity` arrêté |
| Bedrock « invalid username » | `perform-username-validation` doit être `false` dans `paper-global.yml` |
| Geyser « missing key » | vérifier `/data/plugins/floodgate/key.pem` et redémarrer `velocity` |
| plugins absents | relancer `mc-plugins` puis les serveurs |
| client ancien refusé | ViaVersion/ViaBackwards manquants ou serveur non redémarré |
| `OutOfMemoryError` | augmenter `MINECRAFT_MEMORY_*`, vérifier `docker stats` |
| serveur bloqué au démarrage | `docker compose logs mc-<nom>`, espace disque, RAM |
| un plugin a besoin d'Internet | les serveurs Paper n'ont accès qu'au réseau interne : ajouter `proxy` aux réseaux du service si nécessaire |

Pour les problèmes d'authentification Mojang, Velocity a besoin d'Internet
(réseau `proxy`) : vérifier la sortie réseau du VPS.
