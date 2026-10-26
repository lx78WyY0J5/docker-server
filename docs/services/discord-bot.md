# Bot Discord

**Rôle :** bot du serveur Discord.

**Conteneur :** `discord-bot`  
**Adresse :** aucune. Le bot se connecte à Discord ; il n'ouvre pas de site web.

## Token et mot de passe

| Variable `.env` | Obligatoire | Rôle |
|---|---|---|
| `DISCORD_BOT_TOKEN` | Oui | Token du bot, à récupérer sur le portail Discord |
| `DISCORD_BOT_NAME` | Non | Nom affiché par le bot |

Le token n'est **pas** généré par `make init` : il faut le créer à la main sur
<https://discord.com/developers/applications>.

Si le token est vide ou vaut `CHANGE_ME`, le conteneur s'arrête avec une erreur.

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=bot
sudo make ps-service SERVICE=bot
sudo make logs-service SERVICE=bot
sudo make stop SERVICE=bot
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=bot
```

Cela supprime les volumes `discord-data` et
`discord-config`. Les données du bot sont perdues.

## Inviter le bot

1. Créez une application sur le portail Discord.
2. Ajoutez un bot et copiez son token dans `DISCORD_BOT_TOKEN`.
3. Générez une URL d'invitation avec les permissions nécessaires.
4. Invitez le bot sur votre serveur.
5. Démarrez le service.

## Sécurité

- Le token donne le contrôle du bot. Ne le montrez jamais et ne le commitez pas.
- S'il est divulgué, régénérez-le sur le portail Discord et mettez à jour
  `.env`.
- Le token est écrit dans `/DiscordBot/data/tokens.yml` dans le conteneur, avec
  des permissions restreintes.

## Sauvegarde

`make backup` archive `discord-data`. Le token reste dans `.env`,
à sauvegarder séparément.

## Dépannage

```sh
sudo make logs-service SERVICE=bot
```

- **`DISCORD_BOT_TOKEN manquant`** : la variable est absente de `.env`.
- **`renseigner DISCORD_BOT_TOKEN`** : la valeur est encore `CHANGE_ME`.
- **Le bot est en ligne mais ne répond pas** : vérifiez les permissions et
  l'activation des intents sur le portail Discord.
