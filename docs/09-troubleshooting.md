# Dépannage

## Méthode

```sh
make ps                          # état des conteneurs
make logs                        # tous les logs
docker compose logs -f traefik   # un service en particulier
docker inspect <conteneur> | less
docker compose config            # vérifier la fusion des fichiers compose
```

Trois causes couvrent la majorité des incidents : un conteneur arrêté, un
label Traefik absent/erroné, ou une ressource (DNS, port, base) indisponible.

### `make up` s'arrête sur une erreur `.env`

`make up` lance d'abord `make check-env` : si un secret obligatoire manque ou
si `AZURIOM_GAME`/`VELOCITY_ONLINE_MODE` sont incohérents, aucun conteneur
n'est démarré. Corriger `.env`, puis relancer :

```sh
make check-env
make up
```

Pour démarrer uniquement un service sans passer ce contrôle global :
`make up-service SERVICE=traefik` (puis les autres services nécessaires).

---

## Traefik

### Un site répond 404

1. le conteneur cible est-il démarré ? `docker compose ps <service>` ;
2. a-t-il les labels `traefik.enable=true` et `Host(...)` attendus ?
   `docker inspect <conteneur> --format '{{json .Config.Labels}}' | jq` ;
3. est-il sur le réseau `altherneum_proxy` ? Le label
   `traefik.docker.network` doit indiquer ce réseau ;
4. le routeur apparaît-il dans le dashboard
   (`https://traefik.altherneum.fr` → Routers) ?
5. les logs Traefik montrent-ils une erreur de provider Docker ?

Cas fréquent : un conteneur recréé sans `make up` (le réseau a changé) ;
`docker compose up -d` corrige.

### Un site répond 502

Le routeur existe mais le backend refuse : mauvais port dans
`traefik.http.services.<nom>.loadbalancer.server.port`. Vérifier le port
d'écoute réel :

```sh
docker compose exec meme netstat -lntp 2>/dev/null || docker compose exec meme ss -lntp
```

### Le dashboard Traefik est inaccessible

```sh
# le htpasswd contient-il bien une ligne ?
cat stacks/proxy/auth/dashboard.htpasswd
# regénérer après changement dans .env
make init && docker compose up -d traefik
```

### Le port 80/443 est déjà utilisé

```sh
ss -lntp | grep -E ':80|:443'
```

mailcow publie ses propres ports par défaut : l'override `make mail-integrate`
les supprime (`ports: !reset []`). Relancer mailcow après l'intégration.
Un autre Apache/nginx sur l'hôte doit être arrêté ou configuré en amont.

### Placeholder `@@…@@` visible dans une config

Un template n'a pas été rendu (variable vide ou nom inconnu). Vérifier
l'entrypoint de la stack concernée et que toutes les variables sont dans `.env`.

---

## DNS et TLS

| Symptôme | Action |
|---|---|
| `acme: error: 404` | le nom ne résout pas vers le VPS, ou le port 80 est fermé |
| `` no such host `` | enregistrement `A`/`CNAME` manquant (`dig`) |
| certificat invalide pour un sous-domaine | le routeur demande le certificat au premier accès ; vérifier les logs ACME |
| renouvellement en boucle | horloge système décalée : `apk add chrony && rc-service chronyd start` |

```sh
docker compose logs traefik | grep -iE 'acme|error'
dig +short <nom>.altherneum.fr
```

Pour repartir d'un ACME propre :

```sh
docker compose rm -sf traefik
docker volume rm altherneum_traefik-acme
docker compose up -d traefik
```

---

## Bases de données

### `Access denied for user`

Les mots de passe des volumes sont **antérieurs** à un éventuel changement
dans `.env`. Soit remettre l'ancien mot de passe, soit le changer côté serveur
(voir [`04-secrets.md`](04-secrets.md#rotation)).

### MariaDB/PostgreSQL ne démarre pas

```sh
docker compose logs db-azuriom | tail -n 50
```

Souvent : volume initialisé avec une autre version majeure, permissions du
volume, ou corruption après `docker kill`. Ne jamais « réparer » en supprimant
le volume sans dump récent.

### phpMyAdmin ne voit pas une base

Ajouter le conteneur de base au réseau `db_admin` (comme `db-php`/`db-azuriom`)
et son nom à `PMA_HOSTS` dans `.env`, puis `make up`.

---

## Azuriom

### Le site affiche une erreur 500

```sh
docker compose logs -f azuriom
docker compose exec azuriom php artisan about
docker compose exec azuriom php artisan storage:link
```

Les erreurs « permission denied » sur `storage/` se corrigent avec
`docker compose exec -u root azuriom chown -R apache:apache /var/www/html/storage`.

### L'installation automatique n'a pas créé l'admin

En `mc-online`, vérifier d'abord `AZURIOM_ADMIN_GAME_ID` dans `.env` : sans
cet UUID, l'entrypoint refuse le premier démarrage. Après l'avoir renseigné,
`docker compose up -d azuriom` recrée le conteneur et associe l'UUID au
compte admin existant.

Créer le compte manuellement (sans supprimer le marqueur, qui relancerait les
seeders sur une base déjà remplie) :

```sh
docker compose exec azuriom php artisan user:create --admin \
    --name=admin --email=admin@altherneum.fr --password='…'
# puis renseigner AZURIOM_ADMIN_GAME_ID dans .env et redémarrer azuriom
```

### Les mails ne partent pas

`AZURIOM_MAIL_MAILER` est encore `log` : voir [`06-mailcow.md`](06-mailcow.md).
Tester immédiatement : `docker compose exec azuriom php artisan tinker`.

---

## Forgejo

```sh
docker compose logs -f forgejo
# recréer l'admin
make forgejo-admin
# Si Forgejo répond « name is reserved » : le nom `admin` est réservé.
# Choisir par exemple FORGEJO_ADMIN_NAME=altherneum dans .env puis relancer.

# vérifier la base
docker compose exec db-forgejo psql -U forgejo -d forgejo -c '\dt' | head
```

Erreur `Failed to connect to database` : identifiants `FORGEJO_DB_*` différents
de ceux ayant servi à créer le volume `altherneum_db-forgejo`.

Migration de version : changer `FORGEJO_VERSION` dans `.env`, `make build &&
make up` — Forgejo applique ses migrations au démarrage. Sauvegarder avant.

---

## Minecraft

```sh
docker compose logs -f velocity
docker compose logs -f mc-survie
docker compose exec mc-survie ls /data
```

### « Unable to connect to server » depuis l'extérieur

1. vérifier le routeur TCP : dashboard Traefik → TCP Routers → `velocity` ;
2. `ss -lntp | grep 25565` sur l'hôte : Traefik doit écouter ;
3. le conteneur `velocity` est-il `running` ?
4. le pare-feu laisse-t-il passer `25565/tcp` ?

### Bedrock ne voit pas le serveur

1. `ss -lntup | grep -E '19132|19133'` sur l'hôte : les ports TCP et UDP
   doivent être publiés ;
2. `docker compose logs velocity | grep -iE 'geyser|floodgate|nether|signaling'` ;
3. vérifier que `19132/tcp`, `19132/udp` et `19133/udp` sont ouverts dans le
   pare-feu et chez le fournisseur ;
4. le client Bedrock doit utiliser `mc.altherneum.fr` (port `19132` si demandé).
   Les clients récents passent par NetherNet : `19132/tcp` pour la
   signalisation et `19133/udp` pour le transport WebRTC.

### Kicked : « Invalid session » ou vérification Mojang impossible

Velocity a besoin d'Internet pour l'authentification quand
`VELOCITY_ONLINE_MODE=true`. Il est sur le réseau `proxy` par défaut ; vérifier
la sortie Internet du VPS. En mode hors-ligne (`false`), ce message indique
plutôt que le proxy ou Paper est resté en mode premium : relancer les deux
avec la même valeur.

### « Please use a proxy » / erreurs de forwarding

Le message typique côté Paper est :

```text
If you wish to use IP forwarding, please enable it in your BungeeCord config as well!
```

Cause : le secret de forwarding diffère entre Velocity et Paper. Les deux
lisent `VELOCITY_SECRET` dans `.env` ; relancer les deux côtés en recréant les
conteneurs (un `restart` ne relit pas `.env`) :

```sh
make up
docker compose exec mc-survie grep -A2 'velocity:' /data/config/paper-global.yml
```

Les serveurs Paper réécrivent le secret à chaque démarrage.

### Un client ancien n'arrive pas à se connecter

ViaVersion/ViaBackwards sont installés par `mc-plugins`. Si le serveur vient
d'être mis à jour sans plugins :

```sh
docker compose build mc-plugins
docker compose rm -sf mc-plugins || true
docker compose run --rm mc-plugins   # attend la fin du téléchargement
docker compose restart mc-hub mc-survie …   # recopie des JAR au démarrage
```

### Mémoire insuffisante / `OutOfMemoryError`

Ajuster `.env` (`MINECRAFT_MEMORY_*`) puis `make up`. Surveiller :

```sh
docker stats --no-stream
```

Prévoir de la marge : 8 serveurs × 1 Go + Velocity + mailcow ≈ 10 Go de RAM.

### Un monde ne charge pas après restauration

Vérifier le contenu du volume :

```sh
docker run --rm -v altherneum_mc-survie-data:/data alpine ls -la /data
```

`level.dat` et le dossier `world/` (nommé par `MINECRAFT_LEVEL_NAME`) doivent
être présents. Ne restaurer les volumes qu'avec les serveurs arrêtés.

### RCON depuis Azuriom/plugins

RCON est activé sur chaque serveur (port `25575`, mot de passe
`MINECRAFT_RCON_PASSWORD`). Azuriom y accède via le réseau
`altherneum_minecraft_internal` (nom du conteneur : `mc-survie`, etc.).

---

## fail2ban

```sh
docker exec fail2ban fail2ban-client status
docker exec fail2ban fail2ban-client status traefik-401
docker exec fail2ban fail2ban-client set traefik-401 unbanip 203.0.113.7
docker exec fail2ban fail2ban-client reload
```

Une IP légitime bannie (mot de passe oublié saisi plusieurs fois) se
débannit avec `unbanip`. Si trop de faux positifs, allonger `findtime` ou
monter `maxretry` dans `stacks/fail2ban/jail.d/`.

Les logs lus sont ceux de Traefik (`/var/log/traefik/access.log` du volume
`altherneum_traefik-logs`, format JSON). Si fail2ban ne voit rien :

```sh
docker compose logs traefik | tail        # Traefik écrit-il ?
docker exec fail2ban ls -l /var/log/traefik
```

Un bannissement doit apparaître dans `DOCKER-USER` (ports publiés par Docker),
pas dans `INPUT` :

```sh
docker exec fail2ban iptables -S DOCKER-USER | grep f2b
docker exec fail2ban fail2ban-client get traefik-404 banip
```

Si les règles existent mais que l'IP bannie passe toujours, vérifier que
l'hôte utilise le même frontend iptables que le conteneur (`iptables-nft` sur
Alpine) : `iptables-legacy` et `iptables-nft` ne voient pas les mêmes règles.

---

## code-server / KeeWeb

| Symptôme | Piste |
|---|---|
| code-server demande le mot de passe en boucle | cookie bloqué par un reverse proxy intermédiaire : ne pas mettre de proxy devant Traefik |
| extensions perdues | elles vivent dans `altherneum_code-server-data` : ne pas supprimer le volume |
| KeeWeb : « invalid config » | `config.json` généré au démarrage ; relancer le conteneur |
| KeeWeb : WebDAV refuse l'écriture | auth WebDAV (`webdav.htpasswd`) et permissions du volume (`www-data`, uid 82) |

---

## Hôte et Docker

```sh
df -h /var/lib/docker      # espace disque
docker system df           # usage par type
docker system prune        # supprime images/réseaux inutilisés (pas les volumes)
docker compose down && docker compose up -d
```

Ne jamais utiliser `docker system prune -a --volumes` ni `make clean` sans
sauvegarde : les volumes contiennent les mondes, bases et données.

Après un reboot de l'hôte :

```sh
service docker status
docker compose ps          # restart: unless-stopped doit avoir redémarré les conteneurs
```

Si `mc-plugins` est en `exited 0`, c'est normal : son rôle est unique.

---

## mailcow

Voir [`06-mailcow.md`](06-mailcow.md#dépannage). En résumé :

```sh
make mail-logs
cd "$MAILCOW_DIR" && docker compose ps
curl -sk https://mail.altherneum.fr | head
```

---

## Réinitialiser proprement un service

```sh
# recréer un conteneur sans toucher aux données
docker compose up -d --force-recreate <service>

# reconstruire une image après modification d'un Dockerfile
make build && make up

# dernier recours : supprimer le conteneur ET ses volumes (perte de données)
docker compose rm -sf <service>
docker volume rm altherneum_<service>-data
make up
```
