# Stack KeeWeb

KeeWeb (release HTML officielle) + WebDAV Apache pour le fichier `kdbx.kdbx`.

- auth UI : `stacks/web/keeweb/auth/keeweb.htpasswd` ;
- auth WebDAV : `stacks/web/keeweb/auth/webdav.htpasswd` ;
- données : volume `altherneum_keeweb-webdav`.

Les deux fichiers htpasswd sont générés par `make init` et ignorés par Git.

```sh
docker compose --env-file .env -f stacks/web/keeweb/compose.yaml up -d --build
```

Documentation : [`docs/services/keeweb.md`](../../../docs/services/keeweb.md).
