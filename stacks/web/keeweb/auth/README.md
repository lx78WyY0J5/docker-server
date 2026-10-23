# Authentification KeeWeb

Ce dossier contient les fichiers **htpasswd** de KeeWeb et de son accès
WebDAV. Ils sont générés par [`scripts/init.sh`](../../../../scripts/init.sh)
et montés en lecture seule dans le conteneur
(`/usr/local/apache2/auth`).

| Fichier | Usage |
|---|---|
| `keeweb.htpasswd` | basic auth de l'interface KeeWeb |
| `webdav.htpasswd` | basic auth du WebDAV qui héberge `kdbx.kdbx` |

## Règles

- ne jamais commiter les `*.htpasswd` (ils sont dans `.gitignore`) ;
- les mots de passe en clair restent dans `.env` ;
- après rotation, relancer `make init` ; les fichiers sont montés dans le
  conteneur. En cas de doute, `docker compose restart keeweb` ;
- le volume `altherneum_keeweb-webdav` contient le fichier `kdbx` et est
  sauvegardé par `make backup`.

Voir [Secrets](../../../../docs/04-secrets.md) et
[KeeWeb](../../../../docs/services/keeweb.md).
