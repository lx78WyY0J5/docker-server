# Sauvegardes

Ce dossier reçoit les archives produites par [`scripts/backup.sh`](../scripts/backup.sh)
(`make backup`). Chaque sauvegarde est un sous-dossier daté
`AAAA-MM-JJ_HHMMSS/` contenant :

- les dumps SQL (`db-php.sql`, `db-azuriom.sql`, `db-forgejo.sql`) ;
- les archives des volumes applicatifs (`volume-*.tar.gz`) ;
- un `manifest.txt` (date, hôte, domaine, version Docker, volumes et dumps).

Les archives ne sont **pas** versionnées : `.gitignore` ignore tout le contenu
sauf ce README et `.gitkeep`.

## Utilisation

```sh
make backup
make restore BACKUP=backups/AAAA-MM-JJ_HHMMSS
```

La restauration est destructive et exige `CONFIRM=yes`. Les procédures de
rétention, de copie hors site et de test de restauration sont dans
[Sauvegarde et restauration](../docs/05-backup-restore.md).

Ne pas stocker de secrets en clair dans ce dossier : les dumps peuvent
contenir des données sensibles (comptes, tickets, messages).
