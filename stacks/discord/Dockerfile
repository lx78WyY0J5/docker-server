# =============================================================================
# Bot Discord Altherneum.
# Release officielle : https://github.com/Altherneum/bot/releases
# =============================================================================
FROM eclipse-temurin:21-jre-alpine

ARG BOT_URL=https://github.com/Altherneum/bot/releases/latest/download/bot-1.0-fat.jar

RUN apk add --no-cache curl tzdata \
    && mkdir -p /DiscordBot/data /DiscordBot/Data \
    && curl -fsSL --retry 5 -o /DiscordBot/bot.jar "$BOT_URL"

COPY entrypoint.sh /usr/local/bin/discord-entrypoint
RUN chmod +x /usr/local/bin/discord-entrypoint

WORKDIR /DiscordBot

ENTRYPOINT ["/usr/local/bin/discord-entrypoint"]
