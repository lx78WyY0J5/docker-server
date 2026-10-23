# TLS wildcard avec DNS-01 (optionnel)

Configuration par défaut : HTTP-01, un certificat **par hôte**. C'est simple,
mais chaque nouveau sous-domaine déclenche une validation HTTP et un
certificat supplémentaire. Cette page décrit l'alternative : un seul
certificat `*.altherneum.fr` (+ l'apex), délivré via **DNS-01**.

Références officielles :

- ACME Traefik : <https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/>
- Providers DNS (lego) : <https://go-acme.github.io/lego/dns/>

Prérequis : le registrar doit exposer une API DNS supportée par lego
(Cloudflare, OVH, Gandi, Scaleway…).

## 1. Jeton DNS dans `.env`

Exemple Cloudflare :

```sh
# .env
CF_DNS_API_TOKEN=…        # jeton avec Zone:DNS:Edit sur altherneum.fr
```

Autres exemples : `OVH_ENDPOINT`, `OVH_APPLICATION_KEY`,
`OVH_APPLICATION_SECRET`, `OVH_CONSUMER_KEY` (voir la page lego du provider).

Le jeton reste dans `.env` (chmod 600) et n'est jamais commité.

## 2. Traefik : activer le challenge DNS

Dans `stacks/proxy/compose.yaml`, ajouter les variables au conteneur `traefik` :

```yaml
    environment:
      # …
      CF_DNS_API_TOKEN: ${CF_DNS_API_TOKEN}
```

Dans `stacks/proxy/templates/traefik.yml.template`, remplacer
`httpChallenge` par `dnsChallenge` :

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: "@@ACME_EMAIL@@"
      storage: "/acme/acme.json"
      caServer: "@@ACME_CA_SERVER@@"
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
        propagation:
          delayBeforeChecks: 15s
```

`resolvers` force Traefik à vérifier la propagation via des DNS publics ;
`delayBeforeChecks` évite les faux négatifs avec les TTL longs.

> Le nom du resolver reste `letsencrypt` : aucun label de service à modifier.

## 3. Demander le certificat wildcard

Toujours dans la configuration dynamique
(`stacks/proxy/templates/dynamic/dynamic.yml.template`), demander le wildcard
sur un routeur existant (par exemple `redirect-root`) :

```yaml
    redirect-root:
      rule: "Host(`@@DOMAIN@@`) || Host(`www.@@DOMAIN@@`)"
      entryPoints: [websecure]
      service: "noop@internal"
      middlewares: [redirect-discord]
      tls:
        certResolver: letsencrypt
        domains:
          - main: "@@DOMAIN@@"
            sans:
              - "*@@DOMAIN@@"
```

Traefik obtient alors un certificat contenant `altherneum.fr` **et**
`*.altherneum.fr`, stocké avec les autres dans `altherneum_traefik-acme`.
Tous les routeurs dont le `Host()` correspond au wildcard sont servis par ce
certificat, y compris les sous-domaines créés plus tard.

## 4. Appliquer et vérifier

```sh
docker compose up -d --build traefik

# Les échanges ACME
docker compose logs -f traefik | grep -i -E 'acme|challenge'

# Le certificat servi
openssl s_client -connect meme.altherneum.fr:443 -servername meme.altherneum.fr </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName
# → subject=CN = altherneum.fr
# → DNS:*.altherneum.fr, DNS:altherneum.fr
```

Vérifier aussi les enregistrements TXT créés puis supprimés :

```sh
dig +short TXT _acme-challenge.altherneum.fr
```

## Points d'attention

| Point | Détail |
|---|---|
| Quota | Let's Encrypt : 5 certificats/semaine pour le même jeu de noms. Le wildcard n'utilise qu'une entrée. |
| TTL DNS | Des TTL très longs peuvent gêner la propagation pendant la validation ; `delayBeforeChecks` aide. |
| Racine + wildcard | Certains providers renvoient deux TXT pour le même nom : si le challenge échoue, ajouter `propagation.disableANSChecks: true`. |
| mailcow | Gère ses propres certificats SMTP/IMAP via DNS-01 (voir `06-mailcow.md`) ; l'override Traefik accepte aussi un certificat auto-signé en secours (`insecureSkipVerify`). |
| Retour en HTTP-01 | Retirer `dnsChallenge`, restaurer `httpChallenge`, relancer Traefik. Les anciens certificats restent valides jusqu'à expiration. |
| Environnement de test | `TRAEFIK_ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory` dans `.env` avant de basculer en production. |

Le fichier `acme.json` (`altherneum_traefik-acme`) est la seule copie des clés
ACME : il est recréé automatiquement en cas de perte, mais une nouvelle
validation sera nécessaire.
