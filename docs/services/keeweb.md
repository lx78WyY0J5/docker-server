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

## Configuration

Au démarrage, `stacks/web/keeweb/entrypoint.sh` génère
`/usr/local/apache2/htdocs/config.json` à partir de
`stacks/web/keeweb/config.json.template`, en remplaçant `@@DOMAIN@@` par la
valeur de `DOMAIN_NAME` + `TLD`. Il crée aussi le dossier du volume WebDAV.

Après une modification du domaine dans `.env`, recréez le conteneur pour
régénérer `config.json` :

```sh
sudo make up-service SERVICE=keeweb
```

## Dépannage

```sh
sudo make logs-service SERVICE=keeweb
```

- **401** : mauvais identifiant ou mot de passe Basic.
- **404 via Traefik** : le conteneur n'est pas démarré, donc le routeur n'est
  pas enregistré. Vérifiez `sudo make ps-service SERVICE=keeweb`.
- **Le conteneur redémarre** : consultez les logs, `DOMAIN` doit être défini.
- **Fichier introuvable** : vérifiez le chemin `/webdav/kdbx.kdbx`.
