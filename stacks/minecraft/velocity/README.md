# Proxy Velocity

Image du proxy **Velocity 4.3.0** (Java 25), seul point d'entrée des joueurs
Minecraft. Traefik publie le port `25565` et route le trafic TCP vers ce
conteneur ; les serveurs Paper restent internes.

## Contenu

| Fichier | Rôle |
|---|---|
| `Dockerfile` | télécharge Velocity avec version et build épinglés via l'API Fill v3 |
| `entrypoint.sh` | génère `velocity.toml`, écrit `forwarding.secret`, copie les plugins puis lance Java |
| `config/velocity.toml.template` | modèle avec les serveurs, `[forced-hosts]` et les placeholders |
| `config/server-icon.png` | icône affichée dans la liste des serveurs |

## Template

Les placeholders sont remplacés au démarrage :

| Placeholder | Source |
|---|---|
| `__DOMAIN__` | `DOMAIN` |
| `__MOTD__` | `VELOCITY_MOTD` |
| `__ONLINE_MODE__` | `VELOCITY_ONLINE_MODE` |

Le fichier contient aussi les `[forced-hosts]` (`hub.DOMAINE`,
`survie.DOMAINE`, etc.) : un joueur qui se connecte à ces noms arrive
directement sur le serveur correspondant. Les noms doivent exister dans le DNS
(wildcard ou entrées dédiées, voir [DNS](../../../docs/03-dns.md)).

## Modifier la configuration

1. éditer `config/velocity.toml.template` ou l'`entrypoint.sh` ;
2. reconstruire l'image (les fichiers sont copiés dans l'image) :

```sh
docker compose --env-file .env -f stacks/minecraft/compose.yaml build velocity
docker compose --env-file .env -f stacks/minecraft/compose.yaml up -d velocity
```

Le volume `altherneum_mc-velocity-data` conserve les données du proxy ; le
`velocity.toml` est régénéré à chaque démarrage.

## Documentation

- [Minecraft](../../../docs/services/minecraft.md)
- [Stack Minecraft](../README.md)
- Velocity : <https://docs.papermc.io/velocity/>
- Forwarding moderne : <https://docs.papermc.io/velocity/player-information-forwarding/>
