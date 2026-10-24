# Traefik

Le proxy est le cœur de l'infrastructure : il publie `80`, `443` et `25565`,
termine le TLS et découvre les services par les labels Docker.

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | `traefik:3.7.16` + entrypoint de rendu |
| `entrypoint.sh` | remplace les placeholders `@@…@@` des templates |
| `templates/traefik.yml.template` | configuration **statique** (entrypoints, ACME, providers) |
| `templates/dynamic/dynamic.yml.template` | configuration **dynamique** (TLS, middlewares, redirections) |
| `compose.yaml` | ports, socket Docker, volumes `traefik-acme` et `traefik-logs` |
| `auth/*.htpasswd` | basic auth (généré par `make init`, ignoré par Git) |

Au démarrage, l'entrypoint copie les templates dans `/etc/traefik/` et
`/etc/traefik/dynamic/` après substitution des variables. Toute modification
se fait donc **dans le dépôt**, jamais dans le conteneur.

Placeholders disponibles : `@${DOMAIN_NAME}.${TLD}`, `@@DOMAIN_REGEX@@` (domaine avec
`[.]`), `@@ACME_EMAIL@@`, `@@ACME_CA_SERVER@@`, `@@TRAEFIK_LOG_LEVEL@@`,
`@@TRAEFIK_DASHBOARD_HOST@@`, `@@PROXY_NETWORK@@`.

## Entrypoints

| Nom | Adresse | Usage |
|---|---|---|
| `web` | `:80` | redirection permanente vers `websecure` + challenge ACME HTTP-01 |
| `websecure` | `:443` | trafic HTTPS, certificat par défaut `letsencrypt` |
| `minecraft` | `:25565/tcp` | trafic brut TCP vers Velocity |

Ports publiés par le conteneur : `80`, `443` et
`${MINECRAFT_PORT:-25565}:25565/tcp`.

## Providers

```yaml
providers:
  docker:
    exposedByDefault: false       # seuls les conteneurs avec traefik.enable=true
    network: "@@PROXY_NETWORK@@"  # rendu depuis .env (défaut altherneum_proxy)
    watch: true
  file:
    directory: /etc/traefik/dynamic
    watch: true
```

Le socket Docker (`/var/run/docker.sock`) est monté **en lecture seule** :
Traefik observe les conteneurs mais ne peut pas les piloter. C'est un accès
sensible (l'API Docker n'est pas fine-grained) : voir ci-dessous pour le
sécuriser davantage.

## Ajouter un site

1. le service doit être sur le réseau `altherneum_proxy` ;
2. il déclare ses labels (exemple générique) :

```yaml
    labels:
      traefik.enable: "true"
      traefik.docker.network: ${PROXY_NETWORK}
      traefik.http.routers.mon-site.rule: "Host(`mon-site${DOMAIN_NAME}.${TLD}`)"
      traefik.http.routers.mon-site.entrypoints: "websecure"
      traefik.http.routers.mon-site.tls.certResolver: "letsencrypt"
      traefik.http.routers.mon-site.middlewares: "secure-headers@file"
      traefik.http.services.mon-site.loadbalancer.server.port: "80"
```

3. pour une nouvelle redirection de domaine, ajouter un routeur
   (`noop@internal`) + un middleware `redirectRegex` dans
   `templates/dynamic/dynamic.yml.template` ;
4. `docker compose up -d` (pas besoin de redémarrer Traefik grâce à `watch`).

Le nom du routeur (`mon-site`) est arbitraire, mais doit être unique.

## Redirections en place

| Hôtes | Cible |
|---|---|
| `altherneum.fr`, `www` | `https://discord.altherneum.fr` |
| `docs`, `wiki`, `info` | `https://doc.altherneum.fr` (GitHub Pages) |
| `github` | GitHub de l'organisation Altherneum |
| `search` | Brave Search |
| `ask`, `ai`, `ia` | Brave Ask |
| `archterneum`, `myarch`, `git.arch` | script Archterneum (raw.githubusercontent) |
| `discord` | invitation Discord |
| `vocal` | invitation vocale Discord |
| `lost` | `https://discord.altherneum.fr` |

Toutes les redirections sont permanentes (`301`). Le groupe non-capturé est
utilisé dans le remplacement (`$1`, `$2`) : attention à conserver les
parenthèses lors de l'édition des regex.

L'ancien serveur redirigeait aussi tout sous-domaine inconnu (`*`) vers
`lost.altherneum.fr`. Ce catch-all n'est pas repris par défaut : avec un
certificat par hôte (HTTP-01), Let's Encrypt ne peut pas délivrer un certificat
pour un nom arbitraire. Il faut soit créer un routeur explicite par nom, soit
passer le TLS en wildcard DNS-01 (voir
[`../07-tls-wildcard.md`](../07-tls-wildcard.md)), puis ajouter un routeur
`HostRegexp` et la redirection correspondante.

## Middlewares globaux

| Nom | Usage |
|---|---|
| `secure-headers` | `nosniff`, `referrer-policy`, HSTS (1 an, sous-domaines, preload) |
| `dashboard-auth` | basic auth du dashboard |
| `phpmyadmin-auth` | basic auth de phpMyAdmin |

Ils sont référencés en `nom@file` depuis les labels des services.

## Minecraft (TCP)

Velocity n'utilise ni HTTP ni TLS : le routeur est de type TCP avec une règle
« joker » :

```yaml
traefik.tcp.routers.velocity.rule: "HostSNI(`*`)"
traefik.tcp.routers.velocity.entrypoints: "minecraft"
traefik.tcp.services.velocity.loadbalancer.server.port: "25565"
```

Comme il n'y a qu'un routeur TCP sur cet entrypoint, `HostSNI(*)` capte toutes
les connexions. Pour ajouter un second service TCP, créer un nouvel entrypoint
et un routeur dédié.

Bedrock/Geyser n'utilise pas Traefik : `19132/tcp` (signalisation NetherNet),
`19132/udp` (RakNet) et `19133/udp` (WebRTC NetherNet) sont publiés
directement par le Compose de la stack Minecraft. Traefik ne route que le TCP
Minecraft (`25565`).

## Journalisation

Traefik écrit un access log **JSON** dans le volume
`altherneum_traefik-logs` (`/var/log/traefik/access.log`), monté aussi dans
fail2ban. Format stable : ne pas le changer sans mettre à jour
`stacks/fail2ban/filter.d/`.

```sh
docker compose logs -f traefik
docker run --rm -v altherneum_traefik-logs:/logs alpine tail -f /logs/access.log
```

## Dashboard

`https://traefik.altherneum.fr` (hôte configurable via
`TRAEFIK_DASHBOARD_HOST`), protégé par `dashboard-auth` ; il expose l'API
`api@internal` (routeurs, services, certificats).

## Sécurité du socket Docker

Le socket en lecture seule reste une surface d'attaque : un conteneur
compromis ne peut pas contrôler Traefik, mais s'en prendre à Traefik peut
exposer l'API Docker. Deux durcissements possibles :

1. **socket-proxy** (technos officielles `tecnativa/docker-socket-proxy` —
   non retenu ici pour rester sur des images d'éditeurs). Avec un socket
   proxy, Traefik se connecte à `tcp://socket-proxy:2375` au lieu du socket ;
2. **labels seuls** : désactiver l'API dashboard en production
   (`api.dashboard: false`) une fois la configuration stabilisée.

Autres protections déjà en place : `no-new-privileges`, conteneur non
privilégié, HSTS, basic auth, fail2ban sur les codes d'erreur HTTP.

## Dépannage rapide

```sh
docker compose logs traefik | grep -i error
# un routeur n'apparaît pas dans le dashboard → labels ou réseau
docker inspect <conteneur> --format '{{json .Config.Labels}}' | jq
```

Suite complète : [`../09-troubleshooting.md`](../09-troubleshooting.md).
