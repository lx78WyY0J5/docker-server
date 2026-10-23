# Stack Minecraft

Velocity 4.3.0 (proxy) + 8 serveurs Paper 1.21.11 :
`hub`, `survie`, `creatif`, `anarchie`, `rpg`, `skyblock`, `opprison`, `test`.

- les joueurs Java se connectent uniquement à **Velocity**
  (`mc.altherneum.fr:25565`) ; les joueurs Bedrock passent par Geyser sur le
  même conteneur (RakNet `19132/udp`, signalisation NetherNet `19132/tcp` et
  WebRTC `19133/udp`) ;
- les serveurs Paper ne sont pas exposés : ils vivent sur le réseau interne
  `altherneum_minecraft_internal` et écoutent tous sur le port `25565` ;
- `mc-plugins` télécharge les plugins officiels dans le volume
  `altherneum_mc-plugins`, puis chaque serveur les recopie au démarrage ;
- chaque serveur a son volume `altherneum_mc-<nom>-data` (monde + config).

```sh
# Démarrer uniquement la stack Minecraft
docker compose --env-file .env -f stacks/minecraft/compose.yaml up -d --build

# Voir les logs d'un serveur
docker compose logs -f mc-survie

# Ajouter un serveur plus tard : copier un bloc `mc-*` dans compose.yaml,
# ajouter le volume `altherneum_mc-<nom>-data`, puis déclarer le serveur dans
# stacks/minecraft/velocity/config/velocity.toml.template et relancer.
```

Les versions sont documentées dans `paper/Dockerfile`, `velocity/Dockerfile`
et `plugins/fetch-plugins.sh` (Geyser, Floodgate et le plugin Altherneum
suivent leur release « latest »). ViaVersion, ViaBackwards, WorldEdit, Geyser
et Floodgate sont installés par défaut ; voir
[`docs/services/minecraft.md`](../../docs/services/minecraft.md).
