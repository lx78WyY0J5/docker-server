# Installation

## Ce qu'il faut

- Un serveur Linux (Alpine, Arch, Debian ou Ubuntu).
- Docker Engine et Docker Compose **v2.24 ou plus récent**.
- `git`, `make` et `openssl`.
- Un nom de domaine si vous voulez du HTTPS accessible depuis Internet.

## Méthode simple : `install.sh`

Le script installe Docker, clone le dépôt dans `/opt/docker-server`, crée
`.env`, génère les mots de passe et crée les réseaux Docker. Il ne démarre
**aucun** service.

```sh
sudo ./install.sh
```

Si le dépôt est déjà cloné, lancez le script depuis sa racine : il utilisera ce
dossier au lieu d'en créer un autre.

Ensuite :

```sh
cd /opt/docker-server
sudo nano .env          # domaine + token Discord + UUID Azuriom
sudo make check-env
sudo make up
sudo make ps
```

## Méthode manuelle

```sh
git clone https://github.com/lx78WyY0J5/docker-server.git
cd docker-server
sudo make init          # crée .env, les secrets, les htpasswd et les réseaux
sudo nano .env
sudo make check-env
sudo make build         # peut prendre 10 à 20 minutes la première fois
sudo make up
sudo make ps
```

## Configurer le domaine

Dans `.env` :

```dotenv
DOMAIN_NAME=monprojet
TLD=.com
ACME_EMAIL=admin@monprojet.com
```

- `DOMAIN_NAME` : sans extension.
- `TLD` : avec le point, ou vide pour un domaine local.
- `ACME_EMAIL` : adresse utilisée par Let's Encrypt pour les certificats.

Ensuite, créez les enregistrements DNS :

| Type | Nom | Valeur |
|---|---|---|
| `A` (ou `AAAA`) | `monprojet.com` | IP publique du serveur |
| `A` (ou `AAAA`) | `*.monprojet.com` | IP publique du serveur |

Le wildcard `*.monprojet.com` couvre tous les sous-domaines (`git`, `php`,
`minecraft`, `code`, etc.). Si vous ne pouvez pas utiliser de wildcard, créez
un enregistrement pour chaque sous-domaine utilisé.

## Ports à ouvrir

| Port | Protocole | Utilité |
|---|---|---|
| `80` | TCP | Redirection HTTP et validation des certificats |
| `443` | TCP | Sites HTTPS |
| `25565` | TCP | Minecraft Java |
| `19132` | TCP + UDP | Minecraft Bedrock (Geyser) |
| `19133` | UDP | Minecraft Bedrock récent (NetherNet) |

Sans les ports `80` et `443`, les certificats HTTPS ne peuvent pas être créés.

## Premier démarrage

```sh
sudo make up
```

Au premier lancement :

- les images de base sont construites si nécessaire ;
- le dépôt du site PHP est cloné dans `stacks/web/php-site/src` ;
- les mondes Minecraft sont extraits des cartes livrées avec l'image Paper ;
- les bases de données sont initialisées ;
- les certificats HTTPS sont demandés à Let's Encrypt lors du premier accès.

Vérifiez ensuite :

```sh
sudo make ps
sudo make logs
```

Pour créer le compte administrateur Forgejo après le démarrage :

```sh
sudo make forgejo-admin
```

## Sans domaine public (test local)

Avec `DOMAIN_NAME=localhost` et `TLD=` (vide), les adresses ressemblent à
`https://git.localhost`. Let's Encrypt ne peut pas délivrer de certificat pour
`localhost`. Pour un test local, utilisez un vrai domaine, ou adaptez la
configuration TLS de Traefik. Les services restent accessibles en interne, mais
le navigateur affichera un avertissement de certificat.
