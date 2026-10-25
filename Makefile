# =============================================================================
# Altherneum — raccourcis d'exploitation
# =============================================================================
SHELL := /bin/sh
COMPOSE := docker compose
MAILCOW_DIR := $(or $(shell sed -n 's/^MAILCOW_DIR=//p' .env 2>/dev/null | tail -n1),/opt/mailcow-dockerized)

.PHONY: help init check-env ensure-networks build base php-base mariadb-base postgres-base paper-base ensure-base up down restart ps logs config backup restore \
        php-site-src php-site-env \
        forgejo-admin mail-integrate mail-up mail-down mail-logs clean \
        stop restart-service logs-service up-service down-service \
        ps-service services

help: ## Affiche cette aide
	@awk 'BEGIN {FS = ":.*##"; printf "\nCommandes disponibles :\n\n"} /^[a-zA-Z_-]+:.*?##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\n"

init: ## Génère .env, les mots de passe, les htpasswd et les réseaux Docker
	./scripts/init.sh

check-env: ## Vérifie que .env contient les secrets nécessaires avant make up
	./scripts/check-env.sh

ensure-networks: ## Crée les réseaux Docker externes manquants
	./scripts/ensure-networks.sh

build: base ## Construit les images de base puis celles des stacks
	$(COMPOSE) build

php-site-src: ## Clone le dépôt website dans stacks/web/php-site/src
	./scripts/php-site-src.sh

php-site-env: ## Régénère stacks/web/php-site/src/.env depuis .env
	PHP_SITE_ENV_OVERWRITE=true ./scripts/php-site-src.sh

php-base: ## Construit uniquement l'image de base PHP/Apache
	docker build --pull --no-cache -t altherneum/php-apache:latest images/php-apache

mariadb-base: ## Construit uniquement l'image de base MariaDB
	docker build -t altherneum/mariadb:11.8 images/mariadb

postgres-base: ## Construit uniquement l'image de base PostgreSQL
	docker build -t altherneum/postgres:18 images/postgres

paper-base: ## Construit l'image commune des serveurs Paper
	docker build -t altherneum/paper:1.21.11 stacks/minecraft/paper

base: php-base mariadb-base postgres-base paper-base ## Construit toutes les images de base

ensure-base: ## Construit les images de base manquantes
	@docker image inspect altherneum/php-apache:latest >/dev/null 2>&1 || $(MAKE) php-base
	@docker image inspect altherneum/mariadb:11.8 >/dev/null 2>&1 || $(MAKE) mariadb-base
	@docker image inspect altherneum/postgres:18 >/dev/null 2>&1 || $(MAKE) postgres-base
	@docker image inspect altherneum/paper:1.21.11 >/dev/null 2>&1 || $(MAKE) paper-base

up: check-env ensure-networks ensure-base php-site-src ## Démarre toute l'infrastructure
	$(COMPOSE) up -d --remove-orphans

down: ## Arrête toute l'infrastructure (les volumes sont conservés)
	$(COMPOSE) down

restart: ## Redémarre toute l'infrastructure
	$(COMPOSE) restart

ps: ## Liste l'état des conteneurs
	$(COMPOSE) ps

logs: ## Suit les logs de tous les conteneurs
	$(COMPOSE) logs -f --tail=200

config: ## Valide et affiche la configuration Compose fusionnée
	$(COMPOSE) config

backup: ## Sauvegarde les bases et les volumes applicatifs
	./scripts/backup.sh

restore: ## Restaure une sauvegarde : make restore BACKUP=backups/AAAA...
	@test -n "$(BACKUP)" || (echo "Usage : make restore BACKUP=backups/AAAA-MM-JJ_HHMMSS"; exit 1)
	CONFIRM=yes ./scripts/restore.sh "$(BACKUP)"

forgejo-admin: ## Crée le compte admin Forgejo depuis .env
	./scripts/forgejo-admin.sh

mail-integrate: ## Installe l'override Traefik dans MAILCOW_DIR
	./scripts/mail-integrate.sh

mail-up: ## Démarre mailcow avec l'intégration Traefik
	cd "$(MAILCOW_DIR)" && docker compose -f docker-compose.yml -f docker-compose.override.yml up -d

mail-down: ## Arrête mailcow
	cd "$(MAILCOW_DIR)" && docker compose down

mail-logs: ## Suit les logs de mailcow
	cd "$(MAILCOW_DIR)" && docker compose logs -f --tail=200

clean: ## Supprime les conteneurs ET les volumes (DESTRUCTIF)
	@printf "Cette commande supprime toutes les données Docker d'Altherneum. Confirmer avec CONFIRM=yes\n"
	@test "$${CONFIRM:-no}" = "yes"
	$(COMPOSE) down -v --remove-orphans

# --- Opérations sur un service unique ---
SERVICE ?=

stop: ## Arrête un service (ex: make stop SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make stop SERVICE=nom"; exit 1)
	$(COMPOSE) --env-file .env stop $(SERVICE)

restart-service: ## Redémarre un service (ex: make restart-service SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make restart-service SERVICE=nom"; exit 1)
	$(COMPOSE) --env-file .env restart $(SERVICE)

logs-service: ## Suit les logs d'un service (ex: make logs-service SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make logs-service SERVICE=nom"; exit 1)
	$(COMPOSE) --env-file .env logs -f --tail=200 $(SERVICE)

up-service: ## Démarre un service (ex: make up-service SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make up-service SERVICE=nom"; exit 1)
	@./scripts/ensure-networks.sh
	@if [ -n "$(filter $(SERVICE),php-site)" ]; then \
		$(MAKE) php-site-src ; \
	fi
	@if [ -n "$(filter $(SERVICE),php-site azuriom)" ]; then \
		docker image inspect altherneum/php-apache:latest >/dev/null 2>&1 \
			|| $(MAKE) php-base ; \
	fi
	@if [ -n "$(filter $(SERVICE),php-site azuriom db-php db-azuriom)" ]; then \
		docker image inspect altherneum/mariadb:11.8 >/dev/null 2>&1 \
			|| $(MAKE) mariadb-base ; \
	fi
	@if [ -n "$(filter $(SERVICE),forgejo db-forgejo)" ]; then \
		docker image inspect altherneum/postgres:18 >/dev/null 2>&1 \
			|| $(MAKE) postgres-base ; \
	fi
	@if [ -n "$(filter $(SERVICE),mc-hub mc-survie mc-creatif mc-anarchie mc-rpg mc-skyblock mc-opprison mc-test)" ]; then \
		docker image inspect altherneum/paper:1.21.11 >/dev/null 2>&1 \
			|| $(MAKE) paper-base ; \
	fi
	$(COMPOSE) --env-file .env up -d --build $(SERVICE)

down-service: ## Arrête et supprime un service (ex: make down-service SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make down-service SERVICE=nom"; exit 1)
	$(COMPOSE) --env-file .env rm -sf $(SERVICE)

ps-service: ## État d'un service (ex: make ps-service SERVICE=azuriom)
	@test -n "$(SERVICE)" || (echo "Usage: make ps-service SERVICE=nom"; exit 1)
	$(COMPOSE) --env-file .env ps $(SERVICE)

# Lister les services disponibles
services: ## Liste tous les noms de services
	$(COMPOSE) --env-file .env config --services
