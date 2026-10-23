# Stack bot Discord

Le JAR est construit par l'image à partir de la release GitHub officielle.
`tokens.yml` est généré au démarrage depuis `.env`.

- `DISCORD_BOT_TOKEN` doit être renseigné dans `.env` ;
- les données du bot sont conservées dans `altherneum_discord-data`.

```sh
docker compose --env-file .env -f stacks/discord/compose.yaml up -d --build
```

Documentation : [`docs/services/discord-bot.md`](../../docs/services/discord-bot.md).
