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

## Mailcow

mailcow a ses propres enregistrements (MX, SPF, DKIM, DMARC) : voir
[`06-mailcow.md`](06-mailcow.md). Traefik ne gère que son interface web.
