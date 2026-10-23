# Configuration dynamique Traefik

[`dynamic.yml.template`](dynamic.yml.template) est le modèle de la
configuration **dynamique** de Traefik. Il est rendu au démarrage dans
`/etc/traefik/dynamic/dynamic.yml` par
[`../../entrypoint.sh`](../../entrypoint.sh).

Il contient :

- les options TLS (`minVersion`, résolveur `letsencrypt` déclaré ailleurs) ;
- les middlewares globaux (`secure-headers`, `dashboard-auth`,
  `phpmyadmin-auth`) ;
- les redirections de domaines (`redirectRegex`) ;
- les routeurs qui utilisent le service `noop@internal` pour appliquer ces
  redirections.

## Ajouter une redirection

1. ajouter un middleware `redirect-<nom>` dans `http.middlewares` ;
2. ajouter un routeur `redirect-<nom>` dans `http.routers` avec
   `rule: Host(...)`, `service: noop@internal` et le middleware ;
3. reconstruire l'image Traefik (le template est copié dedans) :

```sh
docker compose --env-file .env -f stacks/proxy/compose.yaml build traefik
docker compose --env-file .env -f stacks/proxy/compose.yaml up -d traefik
```

Les placeholders `@@DOMAIN@@` et `@@DOMAIN_REGEX@@` sont remplacés au
démarrage. Voir [Traefik](../../../../docs/services/traefik.md),
[le README des templates](../README.md) et la
[documentation dynamique](https://doc.traefik.io/traefik/reference/dynamic-configuration/file/).
