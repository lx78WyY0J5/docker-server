# Serveurs Paper

Image commune des **8 serveurs Paper 1.21.11** de la stack Minecraft. Chaque
conteneur (`mc-hub`, `mc-survie`, etc.) est construit depuis ce dossier et
partage le même entrypoint.

## Contenu

| Fichier | Rôle |
|---|---|
| `Dockerfile` | télécharge Paper avec version et build épinglés via l'API Fill v3, puis pré-cache le jar Mojang et le jar patché |
| `entrypoint.sh` | copie le cache hors ligne, génère `eula.txt`, `server.properties` et la configuration Paper, copie les plugins, puis lance Java |
| `config/` | modèles par défaut de `paper-global.yml`, `paper-world-defaults.yml`, `ops.json`, icône |

Le serveur écoute sur `25565` **à l'intérieur** du réseau
`altherneum_minecraft_internal` ; il n'est jamais publié sur l'hôte. Les
joueurs passent par Velocity. Un second réseau,
`altherneum_minecraft_egress`, donne uniquement un accès **sortant** à Internet
(clés Mojang, vérifications du plugin). Les Paper utilisent **Java 25**,
comme Velocity (WorldEdit 7.4.6 exige Java 25).

## Variables importantes

`SERVER_NAME`, `VELOCITY_SECRET`, `MINECRAFT_RCON_PASSWORD`, `VELOCITY_ONLINE_MODE`,
`MEMORY`, `LEVEL_NAME`, `MAX_PLAYERS` et `DOMAIN` sont injectées par le
[`compose.yaml`](../compose.yaml) parent.

## Construire et démarrer un serveur

```sh
# Construit l'image Paper si nécessaire puis démarre le serveur
make up-service SERVICE=mc-hub

make logs-service SERVICE=mc-hub
```

En appel direct de Compose, construire d'abord l'image :
`make paper-base` puis
`docker compose --env-file .env -f stacks/minecraft/compose.yaml up -d mc-hub`.

La configuration durable se fait dans `entrypoint.sh` (le `server.properties`
est réécrit à chaque démarrage) ou dans `config/paper-global.yml`. Pour ajouter
un serveur, suivre le [README de la stack](../README.md).

## Documentation

- [Minecraft](../../../docs/services/minecraft.md)
- [Stack Minecraft](../README.md)
- Paper : <https://docs.papermc.io/paper/>
- Téléchargements Paper : <https://fill-data.papermc.io/>
