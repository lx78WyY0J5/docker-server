# code-server

VS Code dans le navigateur, avec l'image **officielle** de Coder
(`codercom/code-server:4.141.0`). Docs :
<https://coder.com/docs/code-server>, dépôt :
<https://github.com/coder/code-server>.

## Composants

| Élément | Détail |
|---|---|
| `code-server` | image officielle, écoute sur `8080` |
| `altherneum_code-server-data` | `~/.local/share/code-server` : extensions, réglages, sessions |
| `altherneum_code-server-workspace` | projets (`/home/coder/workspace`) |
| réseau | `altherneum_proxy` (Traefik) |

## Domaines et authentification

`code.` et `vscode.` → interface, protégée par `CODE_SERVER_PASSWORD`
(variable `PASSWORD`). Traefik relaie les WebSockets nécessaires au terminal.

Pour changer le mot de passe : modifier `.env` puis `make up`.

## Utilisation

- ouvrir `https://code.altherneum.fr` et saisir le mot de passe ;
- les projets sont dans `/home/coder/workspace` (volume persistant) ;
- installer des extensions depuis l'interface : elles restent dans le volume
  `altherneum_code-server-data` ;
- l'image fournit `git`, `node`/`npm`, `python3` ; pour d'autres outils,
  créer une extension du `Dockerfile` :

```dockerfile
FROM codercom/code-server:4.141.0
USER root
RUN apk add --no-cache make gcc musl-dev
USER coder
```

## Terminal et Docker

Le conteneur ne voit pas le socket Docker (choix de sécurité). Pour exécuter
`docker` depuis le terminal, monter `/var/run/docker.sock` — à réserver à un
usage de confiance, car cela équivaut à un accès root sur l'hôte.

## Sauvegarde

`make backup` archive les deux volumes (réglages et projets). Pour ne
sauvegarder que les projets, se limiter à
`volume-altherneum_code-server-workspace.tar.gz`.

## Mise à jour

```sh
# stacks/code-server/compose.yaml
image: altherneum/code-server:4.142.0      # + Dockerfile FROM codercom/code-server:4.142.0

make build && make up
```

## Dépannage

| Symptôme | Piste |
|---|---|
| redemande le mot de passe à chaque requête | proxy intermédiaire qui retire les cookies : Traefik doit rester le seul reverse proxy |
| interface figée, terminal inutilisable | WebSocket bloqué par un pare-feu/proxy d'entreprise |
| extensions disparues | vérifier que `altherneum_code-server-data` est bien monté |
