#!/bin/sh
# =============================================================================
# install.sh — Installation automatisée d'Altherneum server-v2
# Usage : curl -fsSL <url> | sh    ou    ./install.sh
# =============================================================================
set -eu

REPO_URL="https://github.com/Altherneum/server.git"
REPO_DIR="/opt/altherneum"
SERVER_DIR="${REPO_DIR}/server-v2"
USE_SCRIPT_DIR=0

# Si le script est lancé depuis un clone existant, l'utiliser au lieu de créer
# un second clone dans /opt/altherneum.
if [ -f "$0" ]; then
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/compose.yaml" ]; then
        SERVER_DIR="$SCRIPT_DIR"
        REPO_DIR=$(dirname "$SERVER_DIR")
        USE_SCRIPT_DIR=1
    fi
fi

log() { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[ERR]\033[0m %s\n' "$*"; }

need_root() {
    if [ "$(id -u)" -ne 0 ]; then
        err "Ce script doit être lancé en root (sudo)."
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
    else
        err "Impossible de détecter l'OS (/etc/os-release manquant)."
        exit 1
    fi
    log "OS détecté : $PRETTY_NAME"
}

install_alpine() {
    log "Installation des paquets Alpine..."
    apk update && apk upgrade
    apk add tzdata
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    echo "Europe/Paris" > /etc/timezone
    # docker-openrc fournit /etc/init.d/docker (absent du méta-paquet docker).
    apk add git curl openssl make docker docker-cli-compose docker-openrc
    rc-update add docker default
    service docker start
}

install_arch() {
    log "Installation des paquets Arch..."
    pacman -Syu --needed --noconfirm docker docker-compose git make openssl curl
    systemctl enable --now docker
}

install_debian() {
    log "Installation des paquets Debian/Ubuntu..."
    apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS_ID} $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git make openssl
    systemctl enable --now docker
}

install_os_packages() {
    case "$OS_ID" in
        alpine) install_alpine ;;
        arch) install_arch ;;
        debian|ubuntu) install_debian ;;
        *) err "OS non supporté : $OS_ID (Alpine, Arch, Debian, Ubuntu uniquement)." ; exit 1 ;;
    esac
}

ensure_compose_plugin() {
    if docker compose version >/dev/null 2>&1; then
        return
    fi
    if command -v docker-compose >/dev/null 2>&1; then
        mkdir -p /usr/lib/docker/cli-plugins
        ln -sf "$(command -v docker-compose)" /usr/lib/docker/cli-plugins/docker-compose
        log "Plugin Docker Compose lié depuis docker-compose."
    else
        err "Docker Compose est introuvable."
        exit 1
    fi
}

configure_docker() {
    log "Configuration de Docker daemon..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
        systemctl restart docker
    elif command -v rc-service >/dev/null 2>&1; then
        rc-service docker restart
    elif command -v service >/dev/null 2>&1; then
        service docker restart
    else
        warn "Aucun gestionnaire de service détecté : redémarrez Docker manuellement."
    fi
}

wait_for_docker() {
    log "Attente du démarrage de Docker..."
    i=0
    while [ "$i" -lt 30 ]; do
        if docker info >/dev/null 2>&1; then
            log "Docker est prêt."
            return
        fi
        i=$((i + 1))
        sleep 1
    done
    err "Docker ne répond pas après 30 secondes."
    exit 1
}

add_user_to_docker() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        if id -nG "$SUDO_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
            log "Utilisateur $SUDO_USER déjà dans le groupe docker."
            return
        fi
        if command -v usermod >/dev/null 2>&1; then
            usermod -aG docker "$SUDO_USER"
        else
            addgroup "$SUDO_USER" docker
        fi
        log "Utilisateur $SUDO_USER ajouté au groupe docker (reconnectez-vous pour appliquer)."
    fi
}

chown_repo() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        chown -R "$SUDO_USER" "$REPO_DIR" 2>/dev/null || true
    fi
}

git_pull() {
    # Le dépôt peut appartenir à l'utilisateur qui a lancé sudo : autoriser
    # explicitement ce chemin pour Git, sinon `pull` échoue en « dubious ownership ».
    git -C "$REPO_DIR" -c safe.directory="$REPO_DIR" pull --ff-only
}

clone_repo() {
    if [ "$USE_SCRIPT_DIR" = "1" ]; then
        log "Utilisation du dépôt existant : $SERVER_DIR"
        if [ -d "$REPO_DIR/.git" ]; then
            git_pull || warn "git pull impossible (dépôt local modifié ?)."
        fi
        cd "$SERVER_DIR"
        chown_repo
        return
    fi

    if [ -d "$REPO_DIR/.git" ]; then
        log "Dépôt déjà présent dans $REPO_DIR"
        git_pull || warn "git pull impossible (dépôt local modifié ?)."
        cd "$SERVER_DIR"
    else
        if [ -d "$REPO_DIR" ] && [ -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]; then
            err "$REPO_DIR existe mais n'est pas un dépôt Git. Déplacez-le ou supprimez-le."
            exit 1
        fi
        log "Clonage du dépôt dans $REPO_DIR..."
        mkdir -p "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$SERVER_DIR"
    fi
    chown_repo
}

run_init() {
    log "Initialisation (.env, secrets, htpasswd, réseaux)..."
    # make init est idempotent : il ne remplace jamais les secrets existants.
    make init
    chown_repo
}

show_next_steps() {
    cat <<EOF

================================================================================
✅ Initialisation terminée — les services ne sont PAS encore démarrés
================================================================================

Le script a installé Docker, cloné le dépôt et généré `.env`, les secrets,
les htpasswd et les réseaux. Il ne construit pas les images et ne démarre
aucun conteneur.

Répertoire du projet : $SERVER_DIR

Prochaines étapes :
1. Editer les secrets obligatoires :
   cd $SERVER_DIR
   \$EDITOR .env
   # Renseigner au minimum :
   #   - DISCORD_BOT_TOKEN
   #   - AZURIOM_ADMIN_GAME_ID (UUID Minecraft sans tirets, mode mc-online)
   # Si mailcow est utilisé, créer les boîtes noreply@ et git@ avec les
   # mots de passe déjà générés dans .env.

2. Vérifier la configuration (make up le fait aussi) :
   make check-env

3. Construire les images (peut prendre 10-20 min) :
   make build

4. Démarrer tout :
   make up

5. Vérifier :
   make ps

================================================================================
EXEMPLE COMPLET : Lancer SEULEMENT Azuriom (+ sa base MariaDB)
================================================================================

# 1. Construire l'image de base PHP (requise pour Azuriom)
make build

# 2. Démarrer Traefik (nécessaire pour l'accès HTTPS)
make up-service SERVICE=traefik
# ou équivalent docker compose :
# docker compose --env-file .env -f stacks/proxy/compose.yaml up -d --build

# 3. Démarrer Azuriom + sa base (db-azuriom)
make up-service SERVICE=azuriom
# ou équivalent docker compose :
# docker compose --env-file .env -f stacks/web/azuriom/compose.yaml up -d --build

# 4. Vérifier que le conteneur tourne
make ps-service SERVICE=azuriom
# NAME                STATUS
# azuriom             Up (healthy)
# (make ps affiche aussi db-azuriom et les autres services)

# 5. Suivre les logs en temps réel (Ctrl+C pour quitter)
make logs-service SERVICE=azuriom

# 6. Vérifier l'accès web (remplacez par votre domaine)
curl -k https://minecraft.votre-domaine.fr

# 7. Arrêter proprement
make stop SERVICE=azuriom
# Les volumes (base de données, fichiers) sont conservés.
# db-azuriom reste démarré : make stop SERVICE=db-azuriom pour l'arrêter aussi.

# 8. Pour redémarrer plus tard
make up-service SERVICE=azuriom

# 9. Pour supprimer le conteneur (les volumes sont conservés)
# make down-service SERVICE=azuriom

================================================================================
EXEMPLE : Lancer TOUTE l'infrastructure
================================================================================

make up
make ps
make logs

================================================================================
COMMANDES MAKE UTILES (service unique)
================================================================================

  make up-service SERVICE=azuriom      # build + démarre un service
  make stop SERVICE=azuriom            # arrête un service
  make restart-service SERVICE=azuriom # redémarre un service
  make logs-service SERVICE=azuriom    # logs en temps réel (Ctrl+C)
  make ps-service SERVICE=azuriom      # état d'un service
  make down-service SERVICE=azuriom    # arrête + supprime conteneur (volumes gardés)
  make services                        # liste tous les noms de services

================================================================================
COMMANDES MAKE GLOBALES
================================================================================

  make up              # démarre toute l'infrastructure
  make down            # arrête tout (volumes conservés)
  make restart         # redémarre tout
  make ps              # état de tous les conteneurs
  make logs            # suit les logs de tout
  make build           # construit toutes les images
  make backup          # sauvegarde (bases + volumes)
  make restore         # restauration (voir docs/05-backup-restore.md)
  make forgejo-admin   # crée l'admin Forgejo (après make up)
  make clean           # DÉTRUIT tout (conteneurs + volumes)
  make help            # liste toutes les commandes

Autres services seuls (même principe qu'Azuriom) :
  make up-service SERVICE=php-site
  make up-service SERVICE=keeweb
  make up-service SERVICE=velocity
  make up-service SERVICE=mc-hub
  make up-service SERVICE=mc-survie
  ...

Documentation complète : $SERVER_DIR/docs/README.md
Index des services : $SERVER_DIR/docs/services/README.md
EOF
}

main() {
    need_root
    detect_os
    install_os_packages
    ensure_compose_plugin
    configure_docker
    wait_for_docker
    add_user_to_docker
    clone_repo
    run_init
    show_next_steps
}

main "$@"