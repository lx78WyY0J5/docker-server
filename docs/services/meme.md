# Meme - site de redirection

**Rôle :** petite page statique qui redirige vers une vidéo YouTube choisie au
hasard.

**Conteneur :** `meme`  
**Adresse :** `https://meme.<DOMAIN_NAME><TLD>`  
**Alias :** `windows`, `microsoft`, `arch`, `linux`  
**Exemple :** `https://meme.altherneum.fr`

## Mot de passe

Aucun. Le site est public et ne contient pas de données sensibles.

## Variables `.env`

Aucune variable spécifique. Le service utilise seulement `TZ` et le domaine
global via Traefik. La règle de routage utilise `DOMAIN_NAME` et `TLD`.

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=meme
sudo make ps-service SERVICE=meme
sudo make logs-service SERVICE=meme
sudo make stop SERVICE=meme
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=meme
```

Aucun volume : le service est sans état.

## Modifier le contenu

Le fichier à éditer est :

```text
stacks/web/meme/public/index.html
```

Après modification, reconstruisez et redémarrez :

```sh
sudo make up-service SERVICE=meme
```

Le site choisit une liste de vidéos selon le premier mot du nom de domaine
(`meme`, `windows`, `arch`, etc.). Modifiez les tableaux `global`, `arch` et
`microsoft` dans le fichier HTML.
