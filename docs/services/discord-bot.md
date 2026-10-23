# Bot Discord

Bot développé par Altherneum, distribué sous forme de JAR par les releases
GitHub : <https://github.com/Altherneum/bot/releases>.

## Composants

| Élément | Détail |
|---|---|
| `discord-bot` | `eclipse-temurin:21-jre-alpine` + JAR officiel |
| `altherneum_discord-data` | données persistantes (`/DiscordBot/Data`) |
| réseau | aucun réseau applicatif : uniquement la sortie Internet par défaut |

Le bot n'est pas exposé par Traefik : il se connecte lui-même à l'API Discord
(WebSocket) et n'écoute aucun port.

## Configuration

| Variable `.env` | Rôle |
|---|---|
| `DISCORD_BOT_TOKEN` | token du bot (portail développeur Discord) |
| `DISCORD_BOT_NAME` | nom affiché dans `tokens.yml` |

Au démarrage, `entrypoint.sh` écrit `/DiscordBot/data/tokens.yml` (mode 600)
à partir de ces variables ; les données applicatives vivent dans le volume
`/DiscordBot/Data`.

## Exploitation

```sh
docker compose up -d --build bot
docker compose logs -f discord-bot

# mettre à jour vers la dernière release
docker build -t altherneum/discord-bot:1.0 stacks/discord --no-cache
docker compose up -d bot
```

Pour épingler une version précise plutôt que `latest`, modifier `ARG BOT_URL`
dans `stacks/discord/Dockerfile` (par exemple
`…/releases/download/v1.2/bot-1.2-fat.jar`).

## Migration depuis l'ancien serveur

L'ancien service systemd utilisait `/DiscordBot/data` (token) et
`/DiscordBot/Data` (données). Copier uniquement `Data` :

```sh
docker run --rm -it \
    -v altherneum_discord-data:/target \
    -v /ancre/old/DiscordBot/Data:/source:ro \
    alpine:3.24 sh -c 'cp -a /source/. /target/'
```

`tokens.yml` n'est pas copié : il est régénéré depuis `.env`.

## Sauvegarde

`make backup` archive le volume `altherneum_discord-data`. Après restauration,
vérifier que `DISCORD_BOT_TOKEN` dans `.env` correspond toujours au bot
(portail Discord → Bot → Reset Token si nécessaire).

## Dépannage

| Symptôme | Piste |
|---|---|
| conteneur en boucle de redémarrage | token invalide ou manquant (`docker compose logs discord-bot`) |
| bot hors ligne mais conteneur actif | token révoqué : en générer un nouveau dans le portail Discord |
| données perdues après recréation | le volume `altherneum_discord-data` a été supprimé : restaurer une sauvegarde |
