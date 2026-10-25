# code-server

**Rôle :** Visual Studio Code dans le navigateur, pour éditer des fichiers
directement sur le serveur.

**Conteneur :** `code-server`  
**Adresse :** `https://code.<DOMAIN_NAME><TLD>`  
**Alias :** `https://vscode.<domaine>`  
**Exemple :** `https://code.altherneum.fr`

## Mot de passe

| Variable `.env` | Utilisation |
|---|---|
| `CODE_SERVER_PASSWORD` | Mot de passe demandé à l'ouverture de code-server |

Le mot de passe est généré par `make init`. Contrairement aux comptes admin
Azuriom/Forgejo, il est relu à chaque démarrage : modifiez `.env` puis
redémarrez le service pour le changer.

## Variables `.env` utiles

| Variable | Rôle |
|---|---|
| `CODE_SERVER_PASSWORD` | Mot de passe de l'éditeur |
| `TZ` | Fuseau horaire |

Il n'y a pas d'utilisateur séparé : toute personne qui connaît le mot de passe
peut éditer le workspace et exécuter des commandes dans le conteneur.

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

Cela supprime les volumes `altherneum_code-server-data` (réglages, extensions)
et `altherneum_code-server-workspace` (vos projets). **Sauvegardez avant.**

## Utilisation

1. Ouvrez `https://code.<domaine>`.
2. Saisissez `CODE_SERVER_PASSWORD`.
3. Travaillez dans `/home/coder/workspace`.

Les fichiers du workspace sont conservés dans un volume Docker. Ils survivent
aux redémarrages, mais pas à `clean-service`.

## Sécurité

- Le conteneur ne monte pas le socket Docker : on ne peut pas piloter Docker
  depuis le terminal de code-server.
- N'exposez pas cette adresse sans mot de passe.
- Pour installer des outils système, modifiez le `Dockerfile` de la stack.

## Sauvegarde

`make backup` archive les deux volumes :

- `altherneum_code-server-data` ;
- `altherneum_code-server-workspace`.

## Dépannage

- **Le mot de passe est redemandé sans arrêt** : un autre proxy retire les
  cookies. Traefik doit rester le seul reverse proxy.
- **Terminal figé** : les WebSockets sont bloqués par un pare-feu ou un proxy.
- **Extensions disparues** : vérifiez que le volume `code-server-data` est bien
  monté.
- **Erreur 502** : vérifiez les logs et que le conteneur écoute sur `8080`.
