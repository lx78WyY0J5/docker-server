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
| `TZ` | Fuseau horaire |

Il n'y a pas d'utilisateur séparé dans l'éditeur : toute personne qui connaît
les deux mots de passe peut éditer le workspace et exécuter des commandes dans
le conteneur.

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
  monté.
- **Erreur 502** : vérifiez les logs et que le conteneur écoute sur `8080`.
