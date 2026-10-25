# KeeWeb — gestionnaire de mots de passe

**Rôle :** interface web pour ouvrir et stocker des fichiers KeePass
(`.kdbx`), avec un espace WebDAV pour les synchroniser.

**Conteneur :** `keeweb`  
**Adresse :** `https://keeweb.<DOMAIN_NAME><TLD>`  
**Alias :** `keepass`, `keys`, `key`  
**Exemple :** `https://keeweb.altherneum.fr`

## Mots de passe

KeeWeb utilise **deux** authentifications HTTP Basic :

| Variable `.env` | Utilisation |
|---|---|
| `KEEWEB_UI_USER` | Identifiant d'accès à l'interface |
| `KEEWEB_UI_PASSWORD` | Mot de passe d'accès à l'interface |
| `KEEWEB_WEBDAV_USER` | Identifiant du stockage WebDAV |
| `KEEWEB_WEBDAV_PASSWORD` | Mot de passe du stockage WebDAV |

Les valeurs par défaut des identifiants sont `keeweb` et `webdav`. Les mots de
passe sont générés par `make init` et stockés dans les fichiers
`stacks/web/keeweb/auth/*.htpasswd`.

Le **mot de passe maître du fichier `.kdbx`** est différent : il est choisi
dans KeeWeb et n'est **pas** stocké dans `.env`.

## URL WebDAV

```text
https://keeweb.<DOMAIN_NAME><TLD>/webdav/
```

Le fichier prévu par la configuration par défaut est `kdbx.kdbx`, stocké dans
le volume `altherneum_keeweb-webdav`.

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=keeweb
sudo make ps-service SERVICE=keeweb
sudo make logs-service SERVICE=keeweb
sudo make stop SERVICE=keeweb
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=keeweb
```

Cela supprime le volume WebDAV et donc **tous les fichiers `.kdbx`**.
**Sauvegardez avant.**

## Utilisation

1. Ouvrez `https://keeweb.<domaine>`.
2. Connectez-vous avec `KEEWEB_UI_USER` / `KEEWEB_UI_PASSWORD`.
3. Ouvrez ou créez un fichier `.kdbx`.
4. Choisissez un mot de passe maître solide (il n'est pas dans `.env`).
5. Pour la synchronisation, utilisez l'URL WebDAV et les identifiants
   `KEEWEB_WEBDAV_*`.

## Sauvegarde

`make backup` archive le volume `altherneum_keeweb-webdav`, qui contient les
fichiers `.kdbx`. Le mot de passe maître reste indispensable pour les ouvrir :
conservez-le dans un endroit sûr.

## Problème connu

Dans la version actuelle du dépôt, le script `stacks/web/keeweb/entrypoint.sh`
utilise la variable `CONFIG_DIR` sans la définir. Le conteneur peut s'arrêter
avec :

```text
CONFIG_DIR: parameter not set
```

Vérifiez les logs et corrigez le script avant de compter sur ce service. Voir
[Dépannage](../06-depannage.md).

## Dépannage

```sh
sudo make logs-service SERVICE=keeweb
```

- **401** : mauvais identifiant ou mot de passe Basic.
- **Le conteneur redémarre** : voir le problème connu ci-dessus.
- **Fichier introuvable** : vérifiez le chemin `/webdav/kdbx.kdbx`.
