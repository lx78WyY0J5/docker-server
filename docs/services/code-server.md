# code-server

**Rôle :** Visual Studio Code dans le navigateur, pour éditer des fichiers
directement sur le serveur.

**Conteneur :** `code-server`  
**Adresse :** `https://code.<DOMAIN_NAME><TLD>`  
**Alias :** `https://vscode.<domaine>`  
**Exemple :** `https://code.supername.fr`

## Authentification en deux étapes

1. **Protection HTTP Basic par Traefik** :

| Variable `.env` | Utilisation |
|---|---|
| `CODE_SERVER_HTTP_USER` | Identifiant Basic (par défaut `code-server`) |
| `CODE_SERVER_HTTP_PASSWORD` | Mot de passe Basic, généré par `make init` |

2. **Mot de passe de l'éditeur code-server** :

| Variable `.env` | Utilisation |
|---|---|
| `CODE_SERVER_PASSWORD` | Mot de passe demandé à l'ouverture de code-server |

Les deux mots de passe sont générés par `make init`. La protection HTTP utilise
`stacks/proxy/auth/code-server.htpasswd`, régénéré à partir de `.env` par
`make init`. Contrairement aux comptes admin Azuriom/Forgejo, le mot de passe
de l'éditeur est relu à chaque démarrage : modifiez `.env` puis redémarrez le
service pour le changer.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `CODE_SERVER_HTTP_USER` | Identifiant de la protection HTTP Basic |
| `CODE_SERVER_HTTP_PASSWORD` | Mot de passe de la protection HTTP Basic |
| `CODE_SERVER_PASSWORD` | Mot de passe de l'éditeur |
| `CODE_SERVER_THEME` | Thème appliqué par défaut (défaut : `Default High Contrast`) |
| `GIT_USER_NAME` | Nom du profil Git global (commits) |
| `GIT_USER_EMAIL` | Adresse e-mail du profil Git global |
| `TZ` | Fuseau horaire |

Il n'y a pas d'utilisateur séparé dans l'éditeur : toute personne qui connaît
les deux mots de passe peut éditer le workspace et exécuter des commandes dans
le conteneur.

## Extensions installées par défaut

Le `Dockerfile` préinstalle les extensions listées dans
`stacks/code-server/extensions.txt` :

- `GitHub.vscode-pull-request-GitHub` ;
- `PKief.material-icon-theme` ;
- `ms-vscode.live-server` ;
- `vscjava.vscode-java-pack` ;
- `redhat.vscode-yaml`.

Un volume `code-server-data` neuf reçoit ces extensions à sa création. Si le
volume existe déjà, `entrypoint.sh` installe au démarrage celles qui manquent.
Pour en ajouter une, complétez `extensions.txt`, reconstruisez l'image puis
redémarrez le service :

```sh
sudo docker compose build code-server
sudo make up-service SERVICE=code-server
```

## Thème par défaut

Au démarrage, `entrypoint.sh` applique le thème défini par
`CODE_SERVER_THEME` (par défaut `Default High Contrast`, de l'extension
intégrée `vscode.theme-defaults`) dans `User/settings.json` du volume
`code-server-data`. Le réglage n'est écrit que s'il n'existe pas déjà : un
thème choisi dans l'interface est conservé.

Pour changer le thème par défaut d'un volume neuf, modifiez
`CODE_SERVER_THEME` dans `.env` puis redémarrez. Sur un volume existant,
utilisez le sélecteur de code-server (`Ctrl+K Ctrl+T`) ou modifiez
`workbench.colorTheme` dans les réglages.

## Profil Git

`entrypoint.sh` configure le profil Git global du conteneur à partir de
`GIT_USER_NAME` et `GIT_USER_EMAIL` (voir `.env`). Les deux variables doivent
être renseignées ensemble ; sinon code-server affiche un rappel au démarrage.
Modifiez `.env` puis redémarrez le service :

```sh
sudo make restart-service SERVICE=code-server
```

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=code-server
sudo make ps-service SERVICE=code-server
sudo make logs-service SERVICE=code-server
sudo make stop SERVICE=code-server
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=code-server
```

Cela supprime les volumes `code-server-data` (réglages, extensions)
et `code-server-workspace` (vos projets). **Sauvegardez avant.**

## Utilisation

1. Ouvrez `https://code.<domaine>`.
2. Saisissez `CODE_SERVER_HTTP_USER` / `CODE_SERVER_HTTP_PASSWORD` (Traefik).
3. Saisissez `CODE_SERVER_PASSWORD` (éditeur).
4. Travaillez dans `/home/coder/workspace`.

Les fichiers du workspace sont conservés dans un volume Docker. Ils survivent
aux redémarrages, mais pas à `clean-service`.

## Sécurité

- Le conteneur ne monte pas le socket Docker : on ne peut pas piloter Docker
  depuis le terminal de code-server.
- N'exposez pas cette adresse sans mot de passe.
- Pour installer des outils système, modifiez le `Dockerfile` de la stack.

## Sauvegarde

`make backup` archive les deux volumes :

- `code-server-data` ;
- `code-server-workspace`.

## Dépannage

- **Le mot de passe est redemandé sans arrêt** : un autre proxy retire les
  cookies. Traefik doit rester le seul reverse proxy.
- **Terminal figé** : les WebSockets sont bloqués par un pare-feu ou un proxy.
- **Extensions disparues** : vérifiez que le volume `code-server-data` est bien
  monté. Les extensions de `stacks/code-server/extensions.txt` sont réinstallées
  au démarrage si elles manquent ; vérifiez les logs et l'accès réseau du
  conteneur si l'installation échoue.
- **Erreur 502** : vérifiez les logs et que le conteneur écoute sur `8080`.
