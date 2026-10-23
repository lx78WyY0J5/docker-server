# Documentation

Ce dossier contient les procédures d'exploitation de l'infrastructure
Altherneum. Les documents sont numérotés dans l'ordre de lecture ; chaque
service possède en plus une fiche détaillée dans [`services/`](services/).

## Parcours conseillé

1. [Architecture](01-architecture.md) — principes, réseaux, flux.
2. [Installation Alpine](02-installation.md) — préparer l'hôte et déployer.
3. [DNS et TLS](03-dns.md) — domaines, certificats HTTP-01.
4. [Secrets](04-secrets.md) — `.env`, comptes, rotation.
5. [Sauvegarde / restauration](05-backup-restore.md) — `make backup` et
   `make restore`.
6. [mailcow](06-mailcow.md) — installer et intégrer la messagerie.
7. [TLS wildcard](07-tls-wildcard.md) — passer à DNS-01 si nécessaire.
8. [Migration](08-migration.md) — reprendre les données de l'ancien serveur.
9. [Dépannage](09-troubleshooting.md) — symptômes et pistes.

## Documentation par service

Les fiches par service (Traefik, Azuriom, Forgejo, Minecraft, etc.) sont
indexées dans [`services/README.md`](services/README.md). Elles contiennent les
liens vers la documentation officielle de chaque logiciel.

## Conventions

- les commandes sont à lancer depuis la racine `docker-server/` ;
- les fichiers de secrets (`.env`, `*.htpasswd`) ne sont jamais commités ;
- une stack peut être lancée seule avec
  `docker compose --env-file .env -f stacks/<nom>/compose.yaml up -d --build`.

Retour au [README principal](../README.md).
