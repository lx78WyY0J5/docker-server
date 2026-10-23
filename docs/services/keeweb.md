# KeeWeb

Gestionnaire de mots de passe KeePass (release HTML officielle KeeWeb
**1.18.7**) + WebDAV Apache pour héberger le fichier `kdbx`.
Docs : <https://keeweb.info/>, releases :
<https://github.com/keeweb/keeweb/releases>.

## Composants

| Élément | Détail |
|---|---|
| `keeweb` | `httpd:2.4.69-alpine3.24` + KeeWeb + `mod_dav` |
| `altherneum_keeweb-webdav` | volume des fichiers `.kdbx` (`/var/www/webdav`) |
| `auth/keeweb.htpasswd` | accès à l'interface (basic auth) |
| `auth/webdav.htpasswd` | accès WebDAV (sync depuis les applications) |
| réseau | `altherneum_proxy` |

## Domaines

`keeweb.`, `keepass.`, `keys.`, `key.` → interface KeeWeb (basic auth).

## Fonctionnement

1. `entrypoint.sh` génère `config.json` depuis
   `config.json.template` (URL WebDAV calculée avec `DOMAIN`) ;
2. KeeWeb affiche directement `kdbx.kdbx` hébergé sur
   `https://keeweb.altherneum.fr/webdav/kdbx.kdbx` ;
3. le navigateur se synchronise en WebDAV, protégé par une seconde
   authentification (`KEEWEB_WEBDAV_USER` / `KEEWEB_WEBDAV_PASSWORD`) ;
4. le fichier n'est jamais déchiffré côté serveur : la clé maître reste dans le
   navigateur.

## Utilisation

- ouvrir `https://keeweb.altherneum.fr` (basic auth puis mot de passe maître
  du fichier `kdbx`) ;
- pour synchroniser depuis les applications desktop/mobile, utiliser l'URL
  WebDAV `https://keeweb.altherneum.fr/webdav/` avec les identifiants
  `KEEWEB_WEBDAV_*` ;
- pour déposer un fichier supplémentaire (par exemple `kdbx.kdbx` migré) :

```sh
docker run --rm -it \
    -v altherneum_keeweb-webdav:/target \
    -v "$PWD":/source:ro \
    alpine:3.24 sh -c 'cp /source/kdbx.kdbx /target/ && chown 82:82 /target/kdbx.kdbx'
```

Déposer une copie de `.env` et des secrets importants dans une entrée du
coffre KeePass (voir [`../04-secrets.md`](../04-secrets.md)).

## Sécurité

- double authentification HTTP (interface + WebDAV) ;
- HSTS via le middleware `secure-headers` ;
- le contenu WebDAV n'est jamais servi en clair : seul le `.kdbx` chiffré est
  stocké ;
- les mots de passe `KEEWEB_*` sont générés par `make init` et peuvent être
  changés à tout moment (`make init` régénère les `htpasswd`, puis
  `docker compose up -d keeweb`).

## Mise à jour

```sh
# mettre à jour KEEWEB_VERSION dans le Dockerfile
# et le build arg KEEWEB_VERSION dans compose.yaml
docker compose build keeweb && docker compose up -d keeweb
```

## Dépannage

| Symptôme | Piste |
|---|---|
| WebDAV en lecture seule | droits du volume : `www-data` (uid 82) doit pouvoir écrire |
| « config introuvable » | `config.json` est régénéré au démarrage : relancer le conteneur |
| sync mobile qui échoue | certaines applis exigent `https://…/webdav/` avec le slash final |
