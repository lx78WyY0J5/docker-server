# Sauvegarde et restauration

## Ce qui est sauvegardé

`make backup` (⇒ `scripts/backup.sh`) produit un dossier daté
`backups/AAAA-MM-JJ_HHMMSS/` contenant :

| Élément | Contenu |
|---|---|
| `db-php.sql` | dump `mariadb-dump` complet du serveur `db-php` |
| `db-azuriom.sql` | dump complet du serveur `db-azuriom` |
| `db-forgejo.sql` | `pg_dump --clean --if-exists` de la base `forgejo` |
| `volume-<nom>.tar.gz` | archive de chaque volume labellisé `com.altherneum.backup=true` |
| `manifest.txt` | date, hôte, domaine, version Docker, liste des volumes et dumps |

Sont exclus volontairement :

- les volumes de bases (`altherneum_db-*`) : les dumps SQL sont la source de
  vérité, un volume MariaDB n'est pas portable tel quel ;
- les volumes marqués `com.altherneum.backup=false` (données recréables :
  plugins Minecraft, config Azuriom, caches).

Volumes actuellement sauvegardés : `altherneum_azuriom-storage`,
`altherneum_forgejo-data`, `altherneum_code-server-data`,
`altherneum_code-server-workspace`, `altherneum_keeweb-webdav`,
`altherneum_discord-data`, `altherneum_mc-*-data` (8 mondes).

## Lancer une sauvegarde

```sh
make backup
# → sauvegarde dans backups/2026-10-22_031500
```

Pour un instantané **cohérent** des mondes Minecraft et des dépôts Forgejo,
arrêter d'abord les producteurs :

```sh
docker compose stop mc-hub mc-survie mc-creatif mc-anarchie mc-rpg mc-skyblock mc-opprison mc-test forgejo
make backup
docker compose up -d
```

Forgejo écrit dans `altherneum_forgejo-data` (dépôts Git, pièces jointes) :
archiver ce volume pendant un `push` peut produire une copie incohérente.
Pour un export Forgejo atomique et portable, préférer `forgejo dump` (voir
[`services/forgejo.md`](services/forgejo.md#sauvegarde)). Les volumes
`code-server`, KeeWeb et Azuriom sont archivés à chaud ; les ajouter à la
liste des arrêts si un instantané strictement cohérent est nécessaire.

Les dumps MariaDB/PostgreSQL sont, eux, cohérents à chaud
(`--single-transaction`, `pg_dump`).

## Automatisation (cron Alpine)

```sh
cat > /etc/periodic/daily/altherneum-backup <<'EOF'
#!/bin/sh
cd /opt/docker-server || exit 1
docker compose stop mc-hub mc-survie mc-creatif mc-anarchie mc-rpg mc-skyblock mc-opprison mc-test forgejo
./scripts/backup.sh
docker compose up -d
EOF
chmod +x /etc/periodic/daily/altherneum-backup

rc-service crond start
rc-update add crond default
```

`/etc/periodic/daily` s'exécute vers 02:00. Les logs arrivent dans
`/var/log/messages`.

### Rétention et copie hors site

```sh
# garder 30 jours localement
find /opt/docker-server/backups -maxdepth 1 -mindepth 1 -type d -mtime +30 -exec rm -rf {} +

# copie chiffrée hors site (exemple rclone, à configurer une fois)
apk add rclone
rclone config          # créer un remote (S3, B2, SFTP…)
rclone sync /opt/docker-server/backups remote:altherneum-backups --fast-list
```

Un dossier de sauvegarde fait facilement plusieurs gigaoctets (mondes
Minecraft). `--exclude`/`--include` ne sont utiles que si les mondes
grossissent trop : dans ce cas, ne conserver que la dernière semaine pour les
mondes et tout l'historique pour les dumps SQL.

## Restaurer

```sh
make restore BACKUP=backups/2026-10-22_031500
# (l'équivalent manuel : CONFIRM=yes ./scripts/restore.sh backups/…)
```

`scripts/restore.sh` :

1. arrête toutes les applications (`docker compose stop`) ;
2. démarre `db-php`, `db-azuriom`, `db-forgejo` et attend qu'ils soient
   `healthy` ;
3. recharge les dumps SQL (s'ils sont présents et non vides) ;
4. vide puis extrait chaque `volume-<nom>.tar.gz` vers le volume correspondant ;
5. relance toute l'infrastructure (`docker compose up -d`).

### Restaurer un seul élément

```sh
# une base (le mot de passe root est lu dans le conteneur)
docker exec -i db-azuriom sh -c 'exec mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' \
    < backups/…/db-azuriom.sql

# un volume
docker run --rm \
    -v altherneum_keeweb-webdav:/target \
    -v "$(pwd)/backups/…":/backup:ro \
    alpine:3.24 \
    sh -c 'rm -rf /target/* && tar xzf /backup/volume-altherneum_keeweb-webdav.tar.gz -C /target'
```

### Restaurer un monde Minecraft sur un serveur précis

```sh
docker compose stop mc-survie
docker run --rm \
    -v altherneum_mc-survie-data:/target \
    -v "$(pwd)/backups/…":/backup:ro \
    alpine:3.24 \
    sh -c 'rm -rf /target/* && tar xzf /backup/volume-altherneum_mc-survie-data.tar.gz -C /target'
docker compose up -d mc-survie
```

## Tester une restauration

Un plan de sauvegarde n'est valable que s'il a déjà été restauré. Sur un
serveur de test :

1. restaurer les dumps dans un MariaDB/PostgreSQL jetable ;
2. vérifier les tables principales (`SHOW TABLES`, `\dt`) ;
3. extraire un volume Minecraft et vérifier la présence de `level.dat` /
   `server.properties` :
   `tar tzf backups/…/volume-altherneum_mc-survie-data.tar.gz | head`.

## mailcow

mailcow ne fait pas partie de `make backup`. Utiliser l'outil officiel :

```sh
cd "$MAILCOW_DIR"
./helper-scripts/backup_and_restore.sh backup all
```

Documentation : <https://docs.mailcow.email/backup_restore/>. Prévoir une
sauvegarde hors site séparée (les boîtes mail ne tiennent pas dans le même
volume que les mondes Minecraft).
