# Dossier `backups`

Les sauvegardes créées par `sudo make backup` sont stockées ici, dans un
sous-dossier daté :

```text
backups/2026-10-25_120000/
```

Chaque dossier contient un `manifest.txt`, des dumps SQL et des archives de
volumes. Ce dossier est ignoré par Git (sauf ce README).

## Créer une sauvegarde

```sh
cd /opt/docker-server
sudo make backup
```

## Restaurer

```sh
sudo CONFIRM=yes make restore BACKUP=backups/AAAA-MM-JJ_HHMMSS
```

> La restauration remplace les données actuelles.

## À conserver séparément

`.env` et les fichiers `.htpasswd` ne sont pas dans les sauvegardes. Copiez-les
dans un endroit sûr.

Documentation complète :
[Sauvegarde et restauration](../docs/05-backup-restore.md).
