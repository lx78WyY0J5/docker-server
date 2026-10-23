# Architecture

## Principe

Toute l'infrastructure tourne sur **un seul hôte Alpine Linux** avec **Docker
Compose**. Traefik est le point d'entrée web et route le trafic brut TCP vers
Velocity pour Minecraft ; les ports Bedrock (`19132/tcp`, `19132/udp` et
`19133/udp`) sont publiés directement par Compose (Geyser ne passe pas par
Traefik). `19132/udp` sert à RakNet, `19132/tcp` à la signalisation NetherNet
et `19133/udp` au transport WebRTC NetherNet.

```text
                        ┌──────────────────── VPS Alpine ─────────────────────┐
   Internet             │                                                     │
      │                 │   ┌─────────────────────────────────────────────┐   │
      │ 80/443/25565    │   │                Traefik 3.7                  │   │
      └─────────────────┼──▶│  web → websecure (TLS Let's Encrypt)        │   │
                        │   │  minecraft → TCP 25565                      │   │
                        │   └───────┬──────────────────────┬──────────────┘   │
                        │           │ altherneum_proxy     │                    │
                        │   ┌───────▼──────┐       ┌───────▼───────┐            │
                        │   │  web : meme  │       │  velocity     │            │
                        │   │  php-site    │       │  (proxy MC)   │            │
                        │   │  azuriom     │       └───┬───┬───┬───┘            │
                        │   │  forgejo     │           │   │   │  altherneum_   │
                        │   │  code-server │       ┌───▼┐┌─▼─┐┌▼───┐ minecraft_ │
                        │   │  keeweb      │       │hub ││…8 ││test│ internal   │
                        │   │  phpmyadmin  │       └────┘└───┘└────┘            │
                        │   └───────┬──────┘                                   │
                        │           │ réseaux <projet>_internal                 │
                        │   ┌───────▼──────┐     ┌───────────────────┐          │
                        │   │ db-php       │     │  fail2ban         │          │
                        │   │ db-azuriom   │     │  logs → iptables  │          │
                        │   │ db-forgejo   │     └───────────────────┘          │
                        │   └──────────────┘                                   │
                        │   mailcow = stack officielle séparée (voir 06)       │
                        └─────────────────────────────────────────────────────┘
```

## Conventions

| Convention | Règle |
|---|---|
| Projet Compose | `name: altherneum` dans chaque fichier |
| Compose racine | `compose.yaml` avec `include:` (une entrée par stack) |
| Un conteneur = un `Dockerfile` | jamais d'image « communautaire » non épinglée |
| Versions | épinglées (tag, release ou build), sauf PHP qui suit la version par défaut d'Alpine |
| Noms de conteneurs | `<service>` ou `db-<projet>` |
| Volumes | `altherneum_<service>-<rôle>` |
| Sauvegarde | label `com.altherneum.backup=true` sur les volumes applicatifs |
| Réseaux externes | créés par `make init`, référencés en `external: true` |
| Bases de données | une par projet, jamais publiées sur l'hôte |
| Documentation | un lien officiel par service (voir `docs/services/`) |

## Réseaux

| Réseau | Créé par | Rôle |
|---|---|---|
| `altherneum_proxy` | `make init` | Traefik ↔ toutes les apps exposées |
| `altherneum_db_admin` | `make init` (`--internal`) | bases MariaDB ↔ phpMyAdmin |
| `altherneum_minecraft_internal` | `make init` (`--internal`) | Velocity ↔ Paper ↔ Azuriom (ping/RCON) |
| `altherneum_minecraft_egress` | le compose Minecraft (bridge non interne) | sortie Internet des serveurs Paper (Mojang, plugin), aucun port publié |
| `altherneum_<projet>_internal` | le compose du projet (`internal: true`) | app ↔ sa propre base uniquement |

Un conteneur n'est joignable que par les services présents sur le même réseau.
Par défaut, une application est sur `proxy` + son réseau `_internal` ; sa base
n'est que sur `_internal` (+ `db_admin` pour MariaDB afin d'être visible par
phpMyAdmin).

## Flux

**Site web** : client → `80/443` → Traefik (TLS, redirections, auth, headers)
→ conteneur applicatif (port 80/3000/8080) via `altherneum_proxy`.

**Minecraft Java** : client → `25565` → Traefik (routeur TCP `HostSNI(*)` sur
l'entrypoint `minecraft`) → conteneur `velocity` → serveurs Paper via
`altherneum_minecraft_internal`. Les serveurs Paper ne sont jamais exposés ;
leur seul accès Internet est sortant via `altherneum_minecraft_egress` (clés
Mojang, vérifications du plugin). Les plugins sont récupérés au build par
`mc-plugins`.

**Minecraft Bedrock** : client → `19132/udp` (RakNet) ou
`19132/tcp` + `19133/udp` (NetherNet) → conteneur `velocity`
(Geyser + Floodgate). Ces ports sont publiés directement par Compose, sans
passer par Traefik.

## Variante home lab

Le compose fourni suppose que Traefik et les services tournent sur le même
hôte. Pour garder des services au home lab **sans exposer l'IP domestique** :

1. laisser Traefik et les ports `80/tcp`, `443/tcp`, `25565/tcp`,
   `19132/tcp`, `19132/udp` et `19133/udp` sur le VPS ;
2. relier le VPS au home lab par un tunnel WireGuard (ou Tailscale) ;
3. router les services distants via le provider file de Traefik, ou un Traefik
   dédié au home lab derrière le tunnel ; le provider Docker du VPS ne voit pas
   les conteneurs d'un autre hôte ;
4. ne publier que la sortie du tunnel côté box, sans NAT `80/443/25565`
   (et `19132/tcp`, `19132/udp`, `19133/udp` si Geyser reste au home lab) ;
5. garder les DNS publics pointés sur le VPS.

Le socket Docker ne doit jamais être exposé sur Internet. Pour Minecraft, le
même tunnel peut transporter le TCP `25565` ainsi que le TCP `19132` et les
UDP `19132`/`19133` si Velocity reste au home lab.

## Algorithme de démarrage

1. `make init` : `.env`, secrets, htpasswd, réseaux Docker ;
2. `make build` : images de base (`php-apache`, `mariadb`, `postgres`,
   `paper`) puis images des stacks ;
3. `make up` : `mc-plugins` télécharge les plugins puis sort ; Velocity et les
   serveurs Paper démarrent ensuite (`depends_on: service_completed_successfully`) ;
4. Traefik lit le socket Docker en lecture seule et découvre les labels.

## Où trouver quoi

| Besoin | Fichier |
|---|---|
| Ajouter un domaine | `stacks/proxy/templates/dynamic/dynamic.yml.template` (redirection) ou labels du service |
| Ajouter un service web | nouveau dossier dans `stacks/`, 3 labels + 1 entrée dans `compose.yaml` |
| Ajouter un serveur Minecraft | `stacks/minecraft/compose.yaml` + `velocity.toml.template` |
| Ajouter une base | nouveau conteneur dans la stack du projet, réseau `_internal` dédié |
| Changer la mémoire d'un serveur | `.env` (`MINECRAFT_MEMORY_*`) puis `make up` |
