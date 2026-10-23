# DNS et TLS

## Enregistrements A (wildcard recommandé)

Tous les sous-domaines pointent vers le VPS d'Altherneum. Plutôt que de créer
un enregistrement par nom, créer :

| Type | Nom | Valeur | TTL |
|---|---|---|---|
| A | `@` (`altherneum.fr`) | IP du VPS | 300 → 3600 |
| A | `*` (`*.altherneum.fr`) | IP du VPS | 300 → 3600 |
| A | `git.arch` | IP du VPS | 300 → 3600 |
| CNAME | `doc` | `altherneum.github.io` | 3600 |

- le wildcard couvre **tous** les sous-domaines utilisés dans ce dépôt, y
  compris ceux qui ne servent qu'à des redirections ;
- `git.arch.altherneum.fr` est un sous-domaine de second niveau : le wildcard
  `*.altherneum.fr` ne le couvre pas, il faut un enregistrement dédié ;
- `doc.altherneum.fr` est un CNAME vers GitHub Pages : un CNAME explicite
  remplace le wildcard pour ce nom ;
- l'apex (`@`) n'est **pas** couvert par un wildcard, il doit exister ;
- Si le registrar ne propose pas de TTL court, garder `3600` : inutile de
  redémarrer les conteneurs après un changement DNS, Traefik retente seul.

Sous-domaines concernés (rappel) : `www`, `discord`, `vocal`, `docs`, `wiki`,
`info`, `github`, `search`, `ask`, `ai`, `ia`, `lost`, `archterneum`,
`myarch`, `git.arch`, `meme`, `windows`, `microsoft`, `arch`, `linux`, `php`,
`phpdoc`, `minecraft`, `mc`, `play`, `git`, `repo`, `forgejo`, `code`,
`vscode`, `keeweb`, `keepass`, `keys`, `key`, `phpmyadmin`, `traefik`, `mail`,
`webmail`, `mails`.

> Un wildcard DNS n'implique pas un wildcard TLS : Let's Encrypt délivre ici
> un certificat **par hôte**. Pour un certificat unique valable pour
> `*.altherneum.fr`, voir [`07-tls-wildcard.md`](07-tls-wildcard.md).

## Vérification

```sh
apk add bind-tools

dig +short altherneum.fr
dig +short test.altherneum.fr
dig +short doc.altherneum.fr        # doit renvoyer les IP de GitHub Pages

# Toutes les cibles doivent répondre avec l'IP du VPS :
for h in meme php minecraft mc git code keeweb phpmyadmin traefik; do
  printf '%-12s %s\n' "$h" "$(dig +short "$h.altherneum.fr")"
done
```

À faire **avant** `make up` : Let's Encrypt valide chaque nom par HTTP-01, donc
si un nom ne résout pas vers le VPS, Traefik échoue pour ce certificat (les
autres noms ne sont pas affectés). `mc` doit aussi résoudre avant le démarrage
de Velocity : Geyser l'annonce aux clients Bedrock via `advertise-addresses`
(NetherNet).

## TLS (HTTP-01, configuration par défaut)

Dans `stacks/proxy/templates/traefik.yml.template` :

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@altherneum.fr
      storage: "/acme/acme.json"
      caServer: https://acme-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web
```

- le certificat est stocké dans le volume `altherneum_traefik-acme`
  (`acme.json`, permissions `600`) ;
- chaque routeur `websecure` avec `tls.certResolver=letsencrypt` déclenche une
  demande pour ses domaines ;
- `web` (port 80) redirige en HTTPS de façon permanente, sauf pour
  `/.well-known/acme-challenge/` que Traefik gère lui-même.

### Vérifier un certificat

```sh
# Depuis le réseau
openssl s_client -connect meme.altherneum.fr:443 -servername meme.altherneum.fr </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -dates

# Ou avec curl
curl -vI https://meme.altherneum.fr 2>&1 | grep -E 'subject|expire|issuer'
```

### En cas d'échec

| Symptôme | Piste |
|---|---|
| `acme: error: 404` pour un nom | DNS encore en propagation, ou port 80 fermé |
| `too many certificates already issued` | limite Let's Encrypt, attendre ou passer en DNS-01 (voir 07) |
| `timeout during connect` | pare-feu/awall bloque le port 80, ou un autre service occupe le port |
| certificat expiré servi par Traefik | `docker compose restart traefik`, vérifier les logs |
| `acme.json` corrompu | supprimer le volume `altherneum_traefik-acme` et relancer |

```sh
docker compose logs traefik | grep -i acme
```

### Environnement de test

Pour tester sans consommer le quota Let's Encrypt, utiliser l'ACME staging :

```sh
# .env
TRAEFIK_ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

Les certificats staging sont rejetés par les navigateurs ; revenir à la
production après validation, puis supprimer `altherneum_traefik-acme`.

## Changer d'IP ou de domaine

### IP du VPS et TLS

Il n'y a **aucune IP de VPS dans la configuration TLS**. Traefik écoute sur
toutes les interfaces de la machine :

```yaml
# stacks/proxy/templates/traefik.yml.template
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
```

Les certificats Let's Encrypt sont délivrés pour des **noms d'hôte**, pas pour
l'IP du serveur (HTTP-01 : Let's Encrypt appelle `http://<domaine>/.well-known/…`
et vérifie que le DNS pointe bien vers le serveur qui répond). L'IP n'est donc
présente que dans le DNS.

Pour remplacer le VPS par un autre avec une nouvelle IP :

1. créer les enregistrements `A` (IPv4) et, si utilisé, `AAAA` (IPv6) vers la
   nouvelle IP ; conserver les `CNAME` éventuels mais vérifier leurs cibles ;
2. ouvrir les ports nécessaires sur le nouveau VPS : `80/tcp`, `443/tcp`,
   `25565/tcp`, `19132/tcp` et `19132-19133/udp` selon les services ;
3. attendre la propagation DNS (`dig +short altherneum.fr`) et vérifier que
   l'ancien serveur ne répond plus pour le domaine ;
4. ne changer **rien** dans `.env` ni dans Traefik. Traefik redemande les
   certificats automatiquement ; le volume `altherneum_traefik-acme` peut être
   copié pour réutiliser les certificats existants, ou laissé vide pour une
   nouvelle émission.

Aucun redémarrage n'est nécessaire après un simple changement DNS : Traefik
retente les défis ACME et recharge sa configuration tout seul. Si l'ancien
serveur reste allumé et que le DNS pointe encore vers lui, c'est lui qui reçoit
le défi HTTP-01 : arrêter son Traefik avant la bascule.

### Nom de domaine

Le domaine central est `DOMAIN` dans `.env`. Les routeurs Compose et les
templates Traefik l'utilisent, mais certains noms sont écrits explicitement et
doivent être adaptés :

| Fichier / variable | À changer |
|---|---|
| `.env` | `DOMAIN`, `ACME_EMAIL` |
| `.env` | `TRAEFIK_DASHBOARD_HOST` |
| `.env` | `AZURIOM_ADMIN_EMAIL`, `AZURIOM_MAIL_HOST`, `AZURIOM_MAIL_USERNAME`, `AZURIOM_MAIL_FROM_ADDRESS` |
| `.env` | `FORGEJO_ADMIN_EMAIL`, `FORGEJO_MAIL_HOST`, `FORGEJO_MAIL_USER`, `FORGEJO_MAIL_FROM` |
| `.env` | `WEBSITE_DISCORD_REDIRECT_URI` (ou laisser vide pour le calcul automatique) |
| `src/.env` du site PHP | régénérer avec `make php-site-env` |
| mailcow | `MAILCOW_HOSTNAME`, comptes mail, puis `make mail-integrate` |

Après modification :

```sh
make check-env
make php-site-env                 # si le site PHP est utilisé
make up                           # recrée les conteneurs avec les nouveaux labels
```

Les templates `stacks/proxy/templates/dynamic/dynamic.yml.template` et
`stacks/mail/traefik.override.yaml.template` sont rendus au démarrage du
conteneur avec `DOMAIN` : un `make restart-service SERVICE=traefik` suffit pour
les routes dynamiques, mais `make up` est plus sûr pour tous les labels
Compose. Penser aussi à mettre à jour les enregistrements MX, SPF, DKIM et
DMARC si le domaine change ([`06-mailcow.md`](06-mailcow.md)).

## Mailcow


mailcow a ses propres enregistrements (MX, SPF, DKIM, DMARC) : voir
[`06-mailcow.md`](06-mailcow.md). Traefik ne gère que son interface web.
