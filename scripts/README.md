# Scripts d'exploitation

Ces scripts sont appelés par le [`Makefile`](../Makefile). Ils se placent
eux-mêmes à la racine `server-v2/` et lisent `.env` ; il est donc préférable de
passer par `make` plutôt que de les lancer depuis un autre dossier.

| Script | Commande | Rôle | Documentation |
|---|---|---|---|
| [`init.sh`](init.sh) | `make init` | crée `.env`, génère les secrets et les `htpasswd`, vérifie les réseaux Docker | [Secrets](../docs/04-secrets.md) |
| [`check-env.sh`](check-env.sh) | `make check-env` | contrôle les variables obligatoires et la cohérence de `.env` | [Secrets](../docs/04-secrets.md) |
| [`backup.sh`](backup.sh) | `make backup` | dumps MariaDB/PostgreSQL + archives des volumes applicatifs | [Sauvegarde](../docs/05-backup-restore.md) |
| [`restore.sh`](restore.sh) | `make restore BACKUP=backups/…` | restaure une sauvegarde (opération destructive) | [Restauration](../docs/05-backup-restore.md) |
| [`forgejo-admin.sh`](forgejo-admin.sh) | `make forgejo-admin` | crée le compte admin Forgejo depuis `.env` | [Forgejo](../docs/services/forgejo.md) |
| [`mail-integrate.sh`](mail-integrate.sh) | `make mail-integrate` | installe l'override Traefik dans l'installation mailcow | [mailcow](../docs/06-mailcow.md) |

## Précautions

- `.env` et les fichiers `auth/*.htpasswd` ne doivent jamais être commités ;
- `restore.sh` exige `CONFIRM=yes` et remplace les données actuelles ;
- les scripts sont en `sh` POSIX : vérifier avec `sh -n scripts/<nom>.sh` après
  modification ;
- `init.sh` est idempotent : il ne remplace pas un secret déjà renseigné.

Voir aussi la liste des commandes avec `make help`.
