# Authentification Traefik

Ce dossier contient les fichiers **htpasswd** utilisés par les middlewares
Traefik. Ils sont générés par [`scripts/init.sh`](../../../scripts/init.sh) et
montés en lecture seule dans le conteneur (`/etc/traefik/auth`).

| Fichier | Usage |
|---|---|
| `dashboard.htpasswd` | basic auth du dashboard Traefik |
| `phpmyadmin.htpasswd` | basic auth de phpMyAdmin |

## Règles

- ne jamais commiter les `*.htpasswd` (ils sont dans `.gitignore`) ;
- les identifiants en clair restent dans `.env` ; les hashes sont régénérés par
  `make init` ;
- après une rotation de mot de passe, relancer `make init` puis recharger
  Traefik avec `docker compose restart traefik` (ou `make up` si le conteneur
  doit être recréé) ;
- les fichiers sont lisibles par le conteneur Traefik mais ne doivent pas être
  exposés par un volume applicatif.

Voir [Secrets](../../../docs/04-secrets.md) pour la rotation et
[Traefik](../../../docs/services/traefik.md) pour le rôle des middlewares.
