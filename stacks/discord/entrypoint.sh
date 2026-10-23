#!/bin/sh
set -eu

: "${DISCORD_BOT_TOKEN:?DISCORD_BOT_TOKEN manquant}"
case "$DISCORD_BOT_TOKEN" in
    ""|"CHANGE_ME")
        echo "Erreur : renseigner DISCORD_BOT_TOKEN dans .env puis relancer." >&2
        exit 1
        ;;
esac

mkdir -p /DiscordBot/data /DiscordBot/Data

cat > /DiscordBot/data/tokens.yml <<EOF
BotName: ${DISCORD_BOT_NAME:-Altherneum}
Bot: ${DISCORD_BOT_TOKEN}
EOF
chmod 600 /DiscordBot/data/tokens.yml

exec java -Xms16M -Xmx32M -jar /DiscordBot/bot.jar
