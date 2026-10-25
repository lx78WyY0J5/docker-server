# Minecraft

**Rôle :** serveur Minecraft Java et Bedrock avec un proxy Velocity et huit
serveurs Paper.

**Conteneurs :**

- `velocity` : point d'entrée des joueurs ;
- `mc-plugins` : télécharge les plugins puis s'arrête ;
- `mc-hub`, `mc-survie`, `mc-creatif`, `mc-anarchie`, `mc-rpg`, `mc-skyblock`,
  `mc-opprison`, `mc-test` : serveurs de jeu.

## Adresses

| Usage | Adresse |
|---|---|
| Java | `mc.<DOMAIN_NAME><TLD>:25565` |
| Bedrock | `mc.<DOMAIN_NAME><TLD>` port `19132` |
| Accès direct à un serveur | `<serveur>.<domaine>:25565` |

Exemple avec `altherneum.fr` :

```text
mc.altherneum.fr:25565          (Java)
mc.altherneum.fr:19132          (Bedrock)
survie.altherneum.fr:25565      (accès direct)
```

## Mots de passe

Les joueurs n'ont pas de mot de passe à saisir dans le jeu.

| Variable `.env` | Utilisation |
|---|---|
| `VELOCITY_SECRET` | Secret interne entre Velocity et Paper |
| `MINECRAFT_RCON_PASSWORD` | Administration RCON interne |

Ces secrets sont générés par `make init`. Ils ne doivent pas être partagés avec
les joueurs.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `MINECRAFT_PORT` | Port Java exposé par Traefik (`25565`) |
| `MINECRAFT_LEVEL_NAME` | Nom du monde par défaut |
| `MINECRAFT_MAX_PLAYERS` | Nombre maximum de joueurs |
| `MINECRAFT_MEMORY_*` | RAM allouée à chaque serveur Paper |
| `VELOCITY_MEMORY` | RAM allouée au proxy |
| `VELOCITY_SECRET` | Secret Velocity / Paper |
| `VELOCITY_ONLINE_MODE` | `true` premium, `false` hors-ligne |
| `VELOCITY_MOTD` | Message affiché dans la liste des serveurs |
| `MINECRAFT_RCON_PASSWORD` | Mot de passe RCON |

Les variables `MINECRAFT_MEMORY_HUB`, `MINECRAFT_MEMORY_SURVIE`,
`MINECRAFT_MEMORY_CREATIF`, `MINECRAFT_MEMORY_ANARCHIE`,
`MINECRAFT_MEMORY_RPG`, `MINECRAFT_MEMORY_SKYBLOCK`,
`MINECRAFT_MEMORY_OPPRISON` et `MINECRAFT_MEMORY_TEST` règlent la mémoire de
chaque serveur.

## Démarrer

Pour tout démarrer :

```sh
sudo make up
```

Ou service par service :

```sh
sudo make up-service SERVICE=velocity
sudo make up-service SERVICE=mc-hub
sudo make up-service SERVICE=mc-survie
sudo make up-service SERVICE=mc-creatif
sudo make up-service SERVICE=mc-anarchie
sudo make up-service SERVICE=mc-rpg
sudo make up-service SERVICE=mc-skyblock
sudo make up-service SERVICE=mc-opprison
sudo make up-service SERVICE=mc-test
```

`mc-plugins` démarre automatiquement avant les autres. Il s'arrête une fois les
plugins téléchargés : c'est normal.

## Arrêter

```sh
sudo make stop SERVICE=velocity
sudo make stop SERVICE=mc-hub
sudo make stop SERVICE=mc-survie
sudo make stop SERVICE=mc-creatif
sudo make stop SERVICE=mc-anarchie
sudo make stop SERVICE=mc-rpg
sudo make stop SERVICE=mc-skyblock
sudo make stop SERVICE=mc-opprison
sudo make stop SERVICE=mc-test
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=mc-hub
```

Chaque serveur a son propre volume de monde. `clean-service` supprime ce volume
et donc le monde du serveur. Le volume `mc-plugins` est partagé : il est
conservé.

Pour supprimer aussi Velocity :

```sh
sudo CONFIRM=yes make clean-service SERVICE=velocity
```

## Premium et hors-ligne

| Mode | `VELOCITY_ONLINE_MODE` | Azuriom |
|---|---|---|
| Premium Microsoft | `true` | `AZURIOM_GAME=mc-online` |
| Comptes locaux | `false` | `AZURIOM_GAME=mc-offline` |

Les deux valeurs doivent être cohérentes. En mode premium, le joueur doit
posséder Minecraft Java.

## Mondes initiaux (maps)

Les cartes de départ sont livrées avec l'image Paper, dans
`stacks/minecraft/paper/maps/<Carte>/Spawn.zip`. Au premier démarrage d'un
serveur, l'entrypoint extrait la carte dans son volume `/data` ; les démarrages
suivants conservent le monde et les modifications des joueurs.

| Serveur | Carte utilisée |
|---|---|
| `mc-hub` | `Hub` |
| `mc-survie` | `Survie` |
| `mc-anarchie` | `Survie` |
| `mc-test` | `Survie` |
| `mc-skyblock` | `SkyBlock` |
| `mc-opprison` | `OPPrison` |
| `mc-creatif` | génération vanilla |
| `mc-rpg` | génération vanilla |

Les cartes contiennent un monde nommé `Spawn`. `MINECRAFT_LEVEL_NAME` doit donc
rester `Spawn` pour qu'elles soient utilisées.

L'extraction n'a lieu que si le monde est absent ou si le fichier de carte a
changé depuis la dernière installation. Après une mise à jour du dépôt qui
modifie une carte, reconstruisez l'image et redémarrez le serveur concerné :

```sh
sudo make paper-base
sudo make up-service SERVICE=mc-hub
```

Le monde est alors réinstallé depuis l'archive : les modifications locales de
ce monde sont remplacées. Pour repartir d'une carte propre sans mise à jour :

```sh
sudo CONFIRM=yes make clean-service SERVICE=mc-hub
sudo make up-service SERVICE=mc-hub
```

## Plugins

`mc-plugins` télécharge notamment :

- le plugin Altherneum ;
- ViaVersion et ViaBackwards ;
- WorldEdit (serveur créatif uniquement) ;
- Geyser et Floodgate pour Bedrock.

Les plugins sont copiés dans un volume partagé. Pour les mettre à jour,
relancez :

```sh
sudo make up-service SERVICE=mc-plugins
```

## Sauvegarde

`make backup` archive les mondes des serveurs Paper. Les volumes de Velocity et
des plugins ne sont pas sauvegardés (ils peuvent être recréés).
