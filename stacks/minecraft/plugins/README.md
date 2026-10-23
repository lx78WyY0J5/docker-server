# Plugins Minecraft

Service **one-shot** `mc-plugins` : il télécharge les plugins officiels dans le
volume partagé `altherneum_mc-plugins`, puis s'arrête. Velocity et chaque
serveur Paper recopient ensuite les JAR dans leur propre dossier `plugins` au
démarrage.

## Contenu

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Alpine + `curl` + le script de téléchargement |
| `fetch-plugins.sh` | liste des plugins, URLs et versions |

Plugins installés par défaut :

- plugin maison Altherneum (dernière release GitHub) ;
- ViaVersion et ViaBackwards 5.12.1 (compatibilité clients) ;
- WorldEdit 7.4.6 (Paper 1.21.11) ;
- Geyser et Floodgate (Velocity) pour le cross-play Bedrock.

Floodgate n'est installé que sur le proxy ; les serveurs Paper n'ont pas besoin
de Floodgate-Spigot ni de base SQLite. Les ports `19132/tcp`, `19132/udp` et
`19133/udp` doivent être ouverts sur le VPS pour RakNet et NetherNet (voir la
section Bedrock de la documentation).

## Mettre à jour un plugin

1. modifier l'URL ou la version dans `fetch-plugins.sh` ;
2. relancer le service puis les serveurs :

```sh
docker compose --env-file .env -f stacks/minecraft/compose.yaml build mc-plugins
docker compose --env-file .env -f stacks/minecraft/compose.yaml rm -sf mc-plugins || true
docker compose --env-file .env -f stacks/minecraft/compose.yaml run --rm mc-plugins
docker compose --env-file .env -f stacks/minecraft/compose.yaml restart velocity mc-hub mc-survie
```

Le volume `altherneum_mc-plugins` n'est pas sauvegardé : il est recréé par ce
service. Les plugins ajoutés manuellement dans `/data/plugins` d'un serveur
restent dans son volume de données, mais ne sont pas gérés par `mc-plugins`.

## Documentation

- [Plugins Minecraft](../../../docs/services/minecraft.md#plugins)
- [Stack Minecraft](../README.md)
- Plugin Altherneum : <https://github.com/Altherneum/plugin/releases>
- ViaVersion : <https://viaversion.com/>
- Geyser sur Velocity : <https://geysermc.org/wiki/geyser/velocity/>
- Floodgate : <https://geysermc.org/wiki/floodgate/>
- WorldEdit : <https://enginehub.org/worldedit/>
