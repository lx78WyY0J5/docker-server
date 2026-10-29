# ToDo list
## SSH + UFW
- Quand docker-server est installé
- il faut ajouter les clefs SSH privés
- Configurer UFW ?
## JDA bot discord convert
- Vérifier + tester si la conversion vers JDA est OK
## Liste
| Services | Sous-Section | Description | Validation |
|---|---|---|---|
| `traefik` | ------------ | ------------ | OK |
| `traefik` #1 | ~~Redirection vers search.brave.com/ask | Il faut retirer le / final, l'URL doit être /ask et non pas /ask/~~ | OK |
| `traefik` #2 | TLS pour remplacer cerbot | Vérifier si le TLS se crée sur un VPS avec DNS | à faire |
| `php-site` | ------------ | ------------ | OK |
| `php-site` #1 | Vérifie le /api/deploy | Vérifier si le git pull marche bien lors d'un /api/deploy | à re valider |
| `azuriom` | ------------ | ------------ | OK |
| `azuriom` #1 | ------------ | Vérifier la boutique, si les commandes sont bien envoyés, ainsi que les clés privés de payement "dédipass" etc | à faire |
| `azuriom` #2 | Image dynamique | Dans le futur, ajouter les images à la racine, et indiquer à l'utilisateur de les remplacer au besoin (car avec le logo Altherneum, et le projet doit pouvoir changer de nom/identité facilement), images dans un dossier ".env", les copiers de ce .env vers le bon endroit (azuriom, logo minecraft server.png, etc) | à faire |
| `keeweb` | ------------ | ------------ | à re valider |
| `phpmyadmin` | | | ? |
| `meme` | | | ? |
| `forgejo`, `db-forgejo` | | | ? |
| `code-server` | ------------ | ------------ | à re valider |
| `velocity`, `mc-*` | ------------ | ------------ | OK |
| `Plugin` | ------------ | ------------ | OK |
| `Plugin` #1 | Logo resource pack | Je crois qu'un logo manque / est cassé : Logo du shop vanilla (diamond), alors qu'il devrait (de mémoire) être un billet doré | à faire |
| `bot` | ------------ | ------------ | ? |
| `fail2ban` | ------------ | ------------ | ? |
| `mailcow` | ------------ | ------------ | ? |