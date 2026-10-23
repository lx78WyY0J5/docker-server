# Forgejo

Fournisseur Git auto-hébergé. Version : **16.0.6**
(`codeberg.org/forgejo/forgejo`). Docs : <https://forgejo.org/docs/latest/>.

> Forgejo 17.0.0 est déconseillé par l'équipe Forgejo (bug affectant les
> opérations Git). Rester sur la branche 16.0.x jusqu'à la publication d'un
> correctif 17.0.x.

## Composants

| Élément | Détail |
|---|---|
| `forgejo` | image officielle + configuration par variables `FORGEJO__…` |
| `db-forgejo` | PostgreSQL 18, volume `altherneum_db-forgejo` (dumpé, non archivé) |
| volume de données | `altherneum_forgejo-data` (`/data`) |
| réseaux | `proxy` (Traefik) + `altherneum_forgejo_internal` |

Pas de SSH : Git en HTTPS uniquement (pas de port 22 supplémentaire à gérer).
L'option se trouve dans `compose.yaml` (`FORGEJO__server__DISABLE_SSH=true`).

## Domaines

`git.`, `repo.`, `forgejo.` → site Forgejo.

## Configuration

La configuration est passée en variables d'environnement, converties par
Forgejo en `app.ini` :

- `FORGEJO__section__CLÉ` → `[section]` `CLÉ` (voir
  <https://forgejo.org/docs/latest/admin/config-cheat-sheet/>) ;
- base de données PostgreSQL (`FORGEJO__database__*`) ;
- sécurité (`SECRET_KEY`, `INTERNAL_TOKEN`, `oauth2.JWT_SECRET`) ;
- mail (`FORGEJO__mailer__*`) vers mailcow, désactivé par défaut ;
- inscriptions fermées (`DISABLE_REGISTRATION=true`).

## Compte administrateur

```sh
make forgejo-admin          # utilise FORGEJO_ADMIN_* de .env
```

Si l'utilisateur existe déjà, la commande échoue : modifier le mot de passe
depuis l'interface d'administration. Ajouter d'autres membres :

```sh
docker compose exec -u git forgejo forgejo admin user create \
    --username membre --email membre@altherneum.fr \
    --password '…' --must-change-password=true
```

## LFS

LFS est activé (`LFS_START_SERVER=true`) ; les objets vivent dans le volume
`altherneum_forgejo-data`. Taille par défaut : vérifier les réglages
`FORGEJO__lfs__*` si les dépôts stockent de gros fichiers.

## Activer le SSH (optionnel)

Si le SSH Git devient nécessaire :

1. publier un port sur le conteneur (`FORGEJO__server__SSH_PORT`,
   `START_SSH_SERVER=true`, `SSH_LISTEN_PORT=2222`) ;
2. ouvrir le port correspondant sur l'hôte ;
3. documenter `git@git.altherneum.fr:2222` pour les utilisateurs.

Le choix par défaut (HTTPS uniquement) évite de manipuler un second port et
reste compatible avec les jetons d'accès.

## Sauvegarde

- les **dépôts** sont dans `altherneum_forgejo-data` → `make backup` les
  archive ; arrêter `forgejo` avant l'archivage pour éviter un dépôt modifié
  pendant le `tar` (voir [`05-backup-restore.md`](../05-backup-restore.md)) ;
- la **base** (issues, wiki, comptes) est un dump PostgreSQL
  (`db-forgejo.sql`) ;
- pour un export complet officiel :
  <https://forgejo.org/docs/latest/admin/command-line/> :

```sh
docker compose exec -u git forgejo forgejo dump -c /data/gitea/conf/app.ini -f /data/forgejo-dump.zip
```

## Mise à jour

```sh
# .env : version cible (lire les notes de release avant de changer)
FORGEJO_VERSION=16.0.6

make backup
make build && make up
```

Le `Dockerfile` reçoit `FORGEJO_VERSION` en `ARG` depuis Compose : changer la
variable suffit à changer l'image de base. Ne pas sauter une version majeure
sans lire le guide de mise à jour officiel.

Forgejo applique ses migrations au démarrage ; lire les notes de version avant
une montée majeure (<https://forgejo.org/releases/>).

## Intégrations

- **Runner d'actions** : installer un runner officiel sur l'hôte ou en
  conteneur (<https://forgejo.org/docs/latest/admin/actions/>) et pointer
  l'URL sur `https://git.altherneum.fr` ;
- **Webhooks** : les conteneurs internes peuvent être joints via
  `altherneum_proxy` si nécessaire ;
- **Dépôt miroir** de `Altherneum/server` : configurer un push mirror depuis
  l'ancien GitHub, ou pousser manuellement (`git push --mirror`).
