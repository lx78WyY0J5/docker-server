# Stacks Docker

Chaque **stack de premier niveau** (proxy, web, forgejo, etc.) possède son
`compose.yaml`, ses Dockerfiles, ses configurations et son `README.md` ; les
sous-dossiers de composants (images Paper, templates Traefik, filtres
fail2ban, etc.) ont eux aussi leur README. Le fichier
[`compose.yaml`](../compose.yaml) à la racine assemble les stacks avec
`include` pour un démarrage global.

| Dossier | Rôle | README | Documentation |
|---|---|---|---|
| [`proxy/`](proxy/README.md) | Traefik, TLS, redirections, auth | oui | [Traefik](../docs/services/traefik.md) |
| [`web/`](web/README.md) | applications HTTP (meme, PHP, Azuriom, KeeWeb, phpMyAdmin) | oui | [Services web](../docs/services/README.md) |
| [`forgejo/`](forgejo/README.md) | Forgejo + PostgreSQL | oui | [Forgejo](../docs/services/forgejo.md) |
| [`code-server/`](code-server/README.md) | VS Code dans le navigateur | oui | [code-server](../docs/services/code-server.md) |
| [`minecraft/`](minecraft/README.md) | Velocity + 8 serveurs Paper | oui | [Minecraft](../docs/services/minecraft.md) |
| [`discord/`](discord/README.md) | bot Discord Altherneum | oui | [Bot Discord](../docs/services/discord-bot.md) |
| [`fail2ban/`](fail2ban/README.md) | bannissement depuis les logs Traefik | oui | [fail2ban](../docs/services/fail2ban.md) |
| [`mail/`](mail/README.md) | intégration de mailcow (stack officielle séparée) | oui | [mailcow](../docs/06-mailcow.md) |

## Conventions

- chaque stack déclare `name: altherneum` pour pouvoir être lancée seule avec
  les mêmes noms de conteneurs et de volumes ;
- les stacks sont sur le réseau `altherneum_proxy` pour être joignables par
  Traefik, et sur un réseau interne dédié pour leurs bases ;
- les volumes persistants sont nommés `altherneum_*` et les volumes
  applicatifs portent le label `com.altherneum.backup=true` ;
- une stack se lance seule avec :

```sh
docker compose --env-file .env -f stacks/<nom>/compose.yaml up -d --build
```

Le démarrage complet passe par `make up` ; les images de base doivent avoir été
construites par `make build`. Voir
[l'architecture](../docs/01-architecture.md) et
[l'installation](../docs/02-installation.md).
