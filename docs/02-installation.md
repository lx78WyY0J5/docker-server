# Installation sur Alpine Linux

Cible : VPS vierge, Alpine Linux 3.24 minimum, RAM ≥ 12 Go recommandée
(16 Go confortables avec Velocity + 8 serveurs Paper + mailcow). Docs officielles :
<https://wiki.alpinelinux.org/wiki/Docker>,
<https://docs.docker.com/engine/install/>, <https://docs.docker.com/compose/>.

## Installation automatisée (recommandée)

Sur une machine vierge (Alpine, Arch, Debian, Ubuntu), en **root** :

```sh
# Option 1 : via curl (si le repo n'est pas encore cloné)
curl -fsSL https://raw.githubusercontent.com/lx78WyY0J5/docker-server/main/install.sh | sh

# Option 2 : si le repo est déjà cloné
cd docker-server
sudo ./install.sh
```

Ce script détecte l'OS (Alpine, Arch, Debian, Ubuntu), installe Docker, Docker Compose, git, make, openssl, configure le daemon Docker, clone le dépôt, génère `.env` + secrets + htpasswd + réseaux Docker. Lancé depuis un clone existant, il le réutilise au lieu de créer un second clone ; `make init` est idempotent et ne remplace jamais les secrets déjà présents.

## Installation manuelle (pas à pas)

Si vous préférez contrôler chaque étape :

### 0. Test local (Arch Linux)

Pour valider la construction et l'orchestration avant de louer le VPS :

```sh
sudo pacman -S --needed docker docker-compose git make openssl
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"   # se reconnecter pour appliquer le groupe

git clone https://github.com/lx78WyY0J5/docker-server.git ~/docker-server
cd ~/docker-server
make init
$EDITOR .env                      # domaine de test, secrets locaux
make check-env
make build
make up
make ps
```

Le test local valide surtout les images, les réseaux et les bases. Pour le
HTTPS, Let's Encrypt exige un nom public et les ports `80/443` : en local,
utilise un nom de test et accepte le certificat auto-signé de Traefik avec
`curl -k`. L'ACME staging de [`03-dns.md`](03-dns.md) sert aux tests sur le VPS
avec un vrai nom. Ne pas pointer le domaine de production vers le poste local.

Une fois le `make ps` propre, reprendre à la section 1 sur le VPS. mailcow est
une installation séparée : ne pas la lancer sur le poste de test.

## 1. Base Alpine

```sh
# Installation minimale + SSH
setup-alpine
apk update && apk upgrade

# Heure et fuseau
apk add tzdata
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
echo "Europe/Paris" > /etc/timezone

# Outils nécessaires au dépôt
apk add git curl openssl make
```

Le dépôt peut être cloné ensuite :

```sh
git clone https://github.com/lx78WyY0J5/docker-server.git /opt/docker-server
cd /opt/docker-server
```

## 2. Docker

```sh
# docker-openrc fournit /etc/init.d/docker
apk add docker docker-cli-compose docker-openrc
rc-update add docker default
service docker start

# Vérifications : Engine 24+ et Compose v2.24+ (`include`, `!reset`)
docker version
docker compose version
```

Configuration recommandée (`/etc/docker/daemon.json`) : limiter la rotation des
logs pour éviter de saturer le disque (Traefik écrit dans un volume, mais les
autres conteneurs utilisent le driver json-file) :

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

```sh
service docker restart
```

Docker reste actif au reboot et les conteneurs `restart: unless-stopped`
redémarrent seuls. Après un reboot, `make up` n'est utile que pour recréer des
conteneurs modifiés.

## 3. Limites système

Pour 8 serveurs Paper + mailcow sur une machine modérée :

```sh
# Swap de secours conditionné par la RAM (zram ou fichier d'échange)
apk add zram-init 2>/dev/null || true

# Augmenter la limite de descripteurs pour Docker (OpenRC)
printf '%s\n' 'rc_ulimit="-n 65535"' > /etc/conf.d/docker
service docker restart
```

Éviter la mise en veille du disque et surveiller l'espace : les mondes
Minecraft et mailcow sont les deux plus gros consommateurs.

## 4. Pare-feu

Exemple avec `awall` (`/etc/awall/optional/altherneum.json`) :

```json
{
  "policy": [{ "in": "DROP", "out": "ACCEPT", "forward": "DROP" }],
  "filter": [
    { "in": "internet", "out": "_fw", "service": "ssh", "action": "accept" },
    { "in": "internet", "out": "_fw", "service": "http", "action": "accept" },
    { "in": "internet", "out": "_fw", "service": "https", "action": "accept" },
    { "in": "internet", "out": "_fw",
      "proto": "tcp", "port": 25565, "action": "accept" },
    { "in": "internet", "out": "_fw",
      "proto": "tcp", "port": 19132, "action": "accept" },
    { "in": "internet", "out": "_fw",
      "proto": "udp", "port": 19132, "action": "accept" },
    { "in": "internet", "out": "_fw",
      "proto": "udp", "port": 19133, "action": "accept" },
    { "in": "internet", "out": "_fw",
      "proto": "tcp", "port": [25, 465, 587, 110, 143, 993, 995, 4190],
      "action": "accept" }
  ]
}
```

```sh
apk add awall
awall enable altherneum
awall activate
```

Les ports `80` et `443` sont indispensables à Let's Encrypt (HTTP-01) et aux
sites. `25565/tcp` sert au proxy Velocity. Pour le cross-play Bedrock, ouvrir
`19132/tcp` (signalisation NetherNet), `19132/udp` (RakNet) et `19133/udp`
(WebRTC NetherNet). Le port `25` peut être bloqué par le fournisseur : voir
[`06-mailcow.md`](06-mailcow.md).

## 5. Déploiement

```sh
cd /opt/docker-server

make init          # .env + secrets + htpasswd + réseaux
$EDITOR .env       # DISCORD_BOT_TOKEN, AZURIOM_ADMIN_GAME_ID, e-mails, etc.
make check-env     # contrôle avant démarrage (aussi lancé par make up)

make build
make up
make ps
```

L'installation initiale d'Azuriom (migrations + compte admin) se fait toute
seule au premier démarrage. En `mc-online`, renseigner
`AZURIOM_ADMIN_GAME_ID` (UUID Minecraft de l'admin, sans tirets) avant
`make up` ; voir [`services/azuriom.md`](services/azuriom.md#connexion-microsoft-mc-online).
Le compte admin Forgejo se crée avec `make forgejo-admin`.

## 6. Après installation

```sh
# HTTPS et redirections
curl -sI https://altherneum.fr | head -n1
curl -sI https://php.altherneum.fr | head -n1

# état des services
make ps

# logs en direct
make logs
```

- vérifier `https://traefik.altherneum.fr` (basic auth de `.env`) ;
- créer les comptes mailcow puis activer le SMTP d'Azuriom/Forgejo
  (voir [`06-mailcow.md`](06-mailcow.md)) ;
- mettre en place la sauvegarde planifiée ([`05-backup-restore.md`](05-backup-restore.md)) ;
- vérifier la résolution DNS avant le premier `make up` ([`03-dns.md`](03-dns.md)).

## Mise à jour de l'infrastructure

```sh
cd /opt/docker-server
git pull

# versions applicatives : .env (AZURIOM_VERSION, FORGEJO_VERSION…)
make build
make up
```

Docker lui-même : `apk upgrade` puis `service docker restart`. Les stacks
applicatives se mettent à jour en changeant la version dans `.env` (ou les
`ARG` des Dockerfile) puis `make build && make up`.
