# Altherneum — infrastructure Docker v2

Refonte complète de l'infrastructure `Altherneum.fr` autour de **Traefik**,
de **Docker Compose** et d'un hôte **Alpine Linux**.

Objectifs :

- un seul point d'entrée HTTP/HTTPS (Traefik) ;
- une stack indépendante par application ;
- une base de données par projet ;
- des images construites localement à partir de sources officielles ;
- une documentation courte par service, avec les liens officiels ;
- un déploiement portable VPS → home lab.

> **Politique images** : aucune image « communautaire » ou douteuse.
> Les seules images de base utilisées sont les images officielles des éditeurs
> (Traefik, MariaDB, PostgreSQL, Apache httpd, Eclipse Temurin, Coder,
> mailcow) ou des images Alpine officielles. Tous les autres services ont
> leur propre `Dockerfile` et téléchargent une release officielle épinglée
> (tag ou build), sans vérification SHA-256 locale.
>
> La base PHP est volontairement **non figée** : elle suit la version par
> défaut du dépôt Alpine (voir [`images/php-apache/README.md`](images/php-apache/README.md)).

---

## 1. Démarrage rapide

Prérequis : Alpine 3.24+, Docker Engine, Docker Compose v2.24+,
ports `80/tcp`, `443/tcp`, `25565/tcp`, `19132/tcp`, `19132/udp` et
`19133/udp` ouverts, DNS configuré
(voir [`docs/03-dns.md`](docs/03-dns.md)).

```sh
cd docker-server

# 1. Génère .env, les mots de passe, les htpasswd et les réseaux Docker
make init

# 2. Renseigne les secrets que l'init ne peut pas générer
#    (token Discord, UUID Minecraft de l'admin…)
$EDITOR .env

# 3. Vérifie les secrets et la cohérence de .env
#    (make up effectue aussi ce contrôle)
make check-env

# 4. Construit les images
make build

# 5. Démarre tout
make up

# 6. Vérifie
make ps
```

Première configuration :

```sh
# Compte admin Forgejo
make forgejo-admin

# Le compte admin Azuriom est créé automatiquement au premier démarrage
# avec AZURIOM_ADMIN_* et lié à AZURIOM_ADMIN_GAME_ID (mc-online).
```

Les identifiants générés sont dans `.env` et dans
`stacks/proxy/auth/*.htpasswd`. **Ne jamais commiter `.env`.**

### Tester un seul service

`make up` démarre toute l'infrastructure. Pour valider un service isolément,
utilisez `make up-service` : la commande construit l'image du service et
démarre uniquement ses dépendances Compose (par exemple la base MariaDB), sans
toucher aux autres stacks.

```sh
# Traefik est nécessaire pour l'accès HTTPS des services web
make up-service SERVICE=traefik

# Exemple : Azuriom + db-azuriom (l'image de base PHP est construite si besoin)
make up-service SERVICE=azuriom

make ps-service SERVICE=azuriom
make logs-service SERVICE=azuriom

# Arrêt du service (la base et les volumes restent)
make stop SERVICE=azuriom
```

Autres exemples : `php-site`, `phpmyadmin`, `meme`, `keeweb`, `code-server`,
`forgejo`, `velocity`, `mc-hub`, `fail2ban`, `bot`. La liste complète est
donnée par `make services`. Pour Minecraft, démarrez aussi `velocity` et un
serveur Paper (`mc-hub`) si vous voulez tester une connexion complète. Les
commandes d'une seule stack (`docker compose -f stacks/...`) fonctionnent
aussi, mais `make up-service` évite d'oublier les images de base et les
dépendances.

---

## 2. Architecture

```text
                         Internet
                            │
                    ┌───────▼────────┐
                    │    Traefik     │  80/443, TLS Let's Encrypt
                    │  (stack proxy) │  dashboards + redirects
                    └───────┬────────┘
                            │ réseau altherneum_proxy
      ┌─────────────┬───────┼────────────┬──────────────┬─────────────┐
      │             │       │            │              │             │
  ┌───▼───┐   ┌─────▼───┐ ┌─▼────────┐ ┌─▼──────────┐ ┌─▼─────────┐ ┌─▼──────────┐
  │ meme  │   │ php-site│ │ Azuriom  │ │  Forgejo   │ │ code-server│ │  KeeWeb    │
  └───────┘   └────┬────┘ └────┬─────┘ └─────┬──────┘ └────────────┘ └────────────┘
                   │           │             │
              ┌────▼────┐ ┌────▼─────┐  ┌────▼──────┐
              │ db-php  │ │db-azuriom│  │db-forgejo │  (un conteneur BDD par projet)
              └─────────┘ └──────────┘  └───────────┘
                            │
                    ┌───────▼────────┐
                    │   phpMyAdmin   │  (réseau db-admin séparé)
                    └────────────────┘

  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │  fail2ban    │     │  Minecraft : Velocity + 8 serveurs Paper     │
  │ logs Traefik │     │  réseau altherneum_minecraft_internal        │
  └──────────────┘     └──────────────────────────────────────────────┘

  ┌──────────────────────────┐
  │ mailcow (stack séparée)  │  mail.* / webmail.*
  └──────────────────────────┘
```

### Réseaux

| Réseau | Rôle |
|---|---|
| `altherneum_proxy` | Traefik ↔ applications web |
| `altherneum_db_admin` | Bases MariaDB ↔ phpMyAdmin (réseau interne) |
| `altherneum_minecraft_internal` | Velocity ↔ Paper, et Azuriom pour RCON/ping |
| réseaux `<projet>_internal` | isolation application ↔ sa base |

### Volumes

Chaque volume persistant porte un nom explicite `altherneum_*` et, pour les
données applicatives, le label `com.altherneum.backup=true`. Les volumes de
bases ne sont pas archivés tels quels : les bases sont dumpées avec
`mariadb-dump` / `pg_dump`.

---

## 3. Services et URLs

| URL | Service | Documentation |
|---|---|---|
| `altherneum.fr`, `www` | redirection Discord | [Traefik](https://doc.traefik.io/traefik/) |
| `discord.altherneum.fr` | redirection invitation Discord | — |
| `vocal.altherneum.fr` | redirection Discord vocal | — |
| `docs/wiki/info` | redirection `doc.altherneum.fr` | — |
| `github.altherneum.fr` | redirection GitHub | — |
| `search.altherneum.fr` | redirection Brave Search | — |
| `lost.altherneum.fr` | redirection Discord | — |
| `ask/ai/ia.altherneum.fr` | redirection Brave Ask | — |
| `meme/windows/microsoft/arch/linux` | site de memes | [Apache httpd](https://httpd.apache.org/docs/2.4/) |
| `php/phpdoc.altherneum.fr` | futur site PHP + MariaDB | [`docs/services/php-site.md`](docs/services/php-site.md) |
| `minecraft.altherneum.fr` (mc/play → redirection) | CMS Azuriom | [Azuriom](https://azuriom.com/docs/) |
| `git/repo/forgejo.altherneum.fr` | Forgejo | [Forgejo](https://forgejo.org/docs/latest/) |
| `code/vscode.altherneum.fr` | code-server | [code-server](https://coder.com/docs/code-server) |
| `keeweb/keepass/keys/key.altherneum.fr` | KeeWeb + WebDAV | [KeeWeb](https://keeweb.info/) |
| `phpmyadmin.altherneum.fr` | phpMyAdmin (basic auth + login) | [phpMyAdmin](https://docs.phpmyadmin.net/) |
| `traefik.altherneum.fr` | dashboard Traefik (basic auth) | [Traefik dashboard](https://doc.traefik.io/traefik/operations/dashboard/) |
| `mail/webmail/mails.altherneum.fr` | mailcow | [mailcow](https://docs.mailcow.email/) |
| `mc.altherneum.fr:25565` | Velocity | [Velocity](https://docs.papermc.io/velocity/) |
| `mc.altherneum.fr:19132` (TCP + UDP), `19133/udp` | Geyser/Floodgate (Bedrock, RakNet + NetherNet) | [Geyser](https://geysermc.org/wiki/geyser/velocity/) |

Le site de documentation `doc.altherneum.fr` reste hébergé sur GitHub Pages :
il ne passe pas par le VPS (CNAME dédié).

---

## 4. Arborescence

```text
docker-server/
├── compose.yaml              # compose racine (include)
├── Makefile                  # commandes d'exploitation
├── .env.example              # variables, sans secrets
├── docs/                     # documentation et procédures
├── images/
│   ├── php-apache/           # base Alpine + Apache + PHP par défaut Alpine
│   ├── mariadb/              # wrapper officiel MariaDB
│   └── postgres/             # wrapper officiel PostgreSQL
├── stacks/
│   ├── proxy/                # Traefik, TLS, redirections, auth
│   ├── web/                  # meme, php-site, Azuriom, KeeWeb, phpMyAdmin
│   ├── forgejo/              # Forgejo + PostgreSQL
│   ├── code-server/
│   ├── minecraft/            # Velocity + serveurs Paper
│   ├── discord/              # bot Altherneum
│   ├── fail2ban/
│   └── mail/                 # intégration mailcow officielle
├── scripts/                  # init, backup, restore, admin Forgejo
└── backups/                  # sauvegardes locales (contenu ignoré par Git)
```

Chaque stack possède son `compose.yaml`, ses `Dockerfile`, ses configs et son
`README`/documentation. Les dossiers structurants (`docs/`, `images/`,
`scripts/`, `stacks/`) ont aussi un README d'index. Une stack peut être lue et
comprise sans lire les autres, et lancée seule avec la commande indiquée dans
son `README` : celle-ci
passe `--env-file .env`, car Compose charge par défaut le `.env` du dossier du
premier fichier compose et non celui de la racine. Chaque fichier compose de
stack déclare `name: altherneum` : Compose ignore ce champ lors d'un `include`
(seuls les services et volumes/réseaux sont fusionnés), mais il garantit les
mêmes noms de conteneurs et de volumes en lancement séparé.

---

## 5. Documentation

Index général : [`docs/README.md`](docs/README.md). Index des fiches service :
[`docs/services/README.md`](docs/services/README.md).

- [Architecture](docs/01-architecture.md)
- [Installation sur Alpine](docs/02-installation.md)
- [DNS et TLS](docs/03-dns.md)
- [Secrets et comptes](docs/04-secrets.md)
- [Sauvegarde / restauration](docs/05-backup-restore.md)
- [mailcow](docs/06-mailcow.md)
- [TLS wildcard avec DNS-01](docs/07-tls-wildcard.md)
- [Migration depuis l'ancien serveur](docs/08-migration.md)
- [Dépannage](docs/09-troubleshooting.md)

Index techniques :

- [Images de base](images/README.md)
- [Scripts](scripts/README.md)
- [Stacks](stacks/README.md)

Documentation par service :

- [Traefik](docs/services/traefik.md)
- [Site de memes](docs/services/meme.md)
- [Site PHP](docs/services/php-site.md)
- [Azuriom](docs/services/azuriom.md)
- [Forgejo](docs/services/forgejo.md)
- [code-server](docs/services/code-server.md)
- [KeeWeb](docs/services/keeweb.md)
- [phpMyAdmin](docs/services/phpmyadmin.md)
- [Minecraft](docs/services/minecraft.md)
- [Bot Discord](docs/services/discord-bot.md)
- [fail2ban](docs/services/fail2ban.md)
- [mailcow](docs/services/mailcow.md)

---

## 6. Sécurité

- TLS Let's Encrypt via Traefik (HTTP-01 par défaut).
- Aucun port de base de données publié sur l'hôte.
- phpMyAdmin et le dashboard Traefik protégés par basic auth.
- `code-server`, KeeWeb, Forgejo et Azuriom ont leur propre authentification.
- fail2ban lit les logs JSON de Traefik et bannit via iptables.
- Les secrets sont générés aléatoirement par `make init`.
- Le socket Docker est monté en lecture seule dans Traefik ; il reste
  nécessaire au provider Docker. Voir
  [`docs/services/traefik.md`](docs/services/traefik.md#sécurité-du-socket-docker).

---

## 7. Migration depuis l'ancien serveur

L'ancien `install.sh` n'est plus utilisé. Les données à migrer sont :

- mondes Minecraft (`/Serveurs/<nom>/`) → volumes `altherneum_mc-*-data` ;
- `DiscordBot/Data/` → volume `altherneum_discord-data` ;
- base Azuriom `site` → dump SQL → `db-azuriom` ;
- base Forgejo (SQLite) → export Forgejo ou reconstruction ;
- `kdbx.kdbx` → volume `altherneum_keeweb-webdav` ;
- dépôts Forgejo → `forgejo dump` ou clone/push.

Procédure détaillée : [`docs/08-migration.md`](docs/08-migration.md).

---

## 8. Licence et sources

Ce dépôt ne contient que de la configuration et des scripts d'installation.
Chaque logiciel reste sous sa licence d'origine. Les URLs de téléchargement
pointent vers les releases officielles des éditeurs.
