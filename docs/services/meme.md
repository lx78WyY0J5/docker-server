# Site de memes

Site statique historique (`meme.altherneum.fr` et alias), servi par Apache
httpd officiel. Docs : <https://httpd.apache.org/docs/2.4/>.

## Fichiers

| Fichier | Rôle |
|---|---|
| `Dockerfile` | `httpd:2.4.69-alpine3.24` + copie de `public/` |
| `public/` | contenu du site (HTML/CSS/JS, images) |
| `compose.yaml` | un conteneur `meme`, réseau `altherneum_proxy` |

Le contenu est **embarqué dans l'image** : toute modification de `public/`
nécessite un rebuild.

## Domaines

```text
meme.altherneum.fr      windows.altherneum.fr   microsoft.altherneum.fr
arch.altherneum.fr      linux.altherneum.fr
```

Tous pointent sur le même conteneur (règle `Host(...)` multiple). Pour ajouter
un domaine, compléter le label dans `compose.yaml` puis `make up`.

## Modifier le site

```sh
$EDITOR stacks/web/meme/public/index.html
docker compose up -d --build meme
```

## Migration depuis l'ancien serveur

L'ancien contenu vivait dans `/var/www/meme` (vhosts Apache). Copier les
fichiers dans `stacks/web/meme/public/`, commiter, puis reconstruire l'image.
Les vhosts Apache de redirection ne sont plus nécessaires : tout passe par les
règles `Host()` et les redirections Traefik.

## Vérifications

```sh
docker compose logs -f meme
curl -sI https://meme.altherneum.fr | head -n1
```
