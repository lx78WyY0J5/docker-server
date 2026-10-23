# Stack code-server

code-server 4.141.0 (image officielle Coder), protégé par mot de passe.

- `code.` et `vscode.` sont routés par Traefik ;
- les extensions et réglages sont dans `altherneum_code-server-data` ;
- les projets sont dans `altherneum_code-server-workspace`.

```sh
docker compose --env-file .env -f stacks/code-server/compose.yaml up -d --build
```

Documentation : [`docs/services/code-server.md`](../../docs/services/code-server.md).
