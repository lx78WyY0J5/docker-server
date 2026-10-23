# mailcow

## Décision

L'ancien serveur utilisait une pile maison (Postfix + Dovecot + Roundcube
inachevés). La nouvelle infrastructure utilise **mailcow**, la stack
officielle : <https://docs.mailcow.email/>.

Conséquences :

- mailcow s'installe et se met à jour avec **son propre outil officiel**, dans
  `/opt/mailcow-dockerized` (variable `MAILCOW_DIR`) ;
- ce dépôt ne contient que l'**intégration Traefik**
  ([`stacks/mail/README.md`](../stacks/mail/README.md)) ;
- mailcow garde ses propres certificats pour SMTP/IMAP ; Traefik ne sert que
  l'interface web (`mail.`, `webmail.`, `mails.`).

## Installation

Installation complète : voir [`stacks/mail/README.md`](../stacks/mail/README.md).
Résumé :

```sh
# 1. dépôt officiel
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
./generate_config.sh          # hostname : mail.altherneum.fr

# 2. mailcow.conf
#    MAILCOW_HOSTNAME=mail.altherneum.fr
#    ACME DNS-01 activé (voir ci-dessous)

# 3. intégration Traefik depuis ce dépôt
cd /opt/altherneum/server-v2
make mail-integrate
make mail-up
```

Points d'attention dans `mailcow.conf` :

| Paramètre | Valeur | Raison |
|---|---|---|
| `MAILCOW_HOSTNAME` | `mail.altherneum.fr` | le nom du serveur mail (MX) |
| `ACME_DNS_CHALLENGE` | `y` | certificat SMTP/IMAP sans port 80 (voir ci-dessous) |
| `ACME_DNS_PROVIDER` | ex. `dns_ovh` | pilote acme.sh du registrar |
| `SKIP_LETS_ENCRYPT` | `n` | laisser mailcow gérer son certificat |
| `ENABLE_SSL_SNI` | `n` | pas de proxy SNI |
| `HTTP_BIND` / `HTTPS_BIND` | retirés par l'override | Traefik publie 80/443 |

L'override généré (`$MAILCOW_DIR/docker-compose.override.yml`) :

- retire les ports `80/443` de `nginx-mailcow` (`ports: !reset []`) ;
- connecte `nginx-mailcow` au réseau `altherneum_proxy` ;
- crée les routeurs `mail.`, `webmail.`, `mails.` (redirection vers `/SOGo/`) ;
- ajoute un `serversTransport` qui accepte aussi le certificat auto-signé de
  mailcow (utile avant l'émission du certificat DNS-01).

### Certificat SMTP/IMAP

Traefik ne termine que le HTTPS web : il ne peut pas fournir le certificat
utilisé par Postfix (465/587) et Dovecot (993/995). Comme Traefik occupe déjà
le port 80, le HTTP-01 de mailcow ne peut pas fonctionner. Activer le
challenge DNS-01 de mailcow (version 2026-03 ou plus récente) :

```ini
# mailcow.conf
ACME_DNS_CHALLENGE=y
ACME_DNS_PROVIDER=dns_ovh          # pilote acme.sh correspondant au registrar
ACME_ACCOUNT_EMAIL=admin@altherneum.fr
SKIP_LETS_ENCRYPT=n
```

Renseigner les identifiants API dans
`$MAILCOW_DIR/data/conf/acme/dns-01.conf`, puis recréer les conteneurs
concernés (`make mail-up`). Le certificat couvre `MAILCOW_HOSTNAME` et les
noms ajoutés dans mailcow. Documentation officielle :
<https://docs.mailcow.email/post_installation/firststeps-ssl-dns/>.

Sans DNS-01, mailcow sert un certificat auto-signé : les clients IMAP/SMTP le
refusent et la délivrabilité peut se dégrader. Ne pas mettre
`SKIP_LETS_ENCRYPT=y` en comptant sur Traefik pour le mail : il ne gère que le
web.

## DNS

En plus des enregistrements de [`03-dns.md`](03-dns.md) :

| Type | Nom | Valeur |
|---|---|---|
| A | `mail.altherneum.fr` | IP du VPS |
| A | `webmail.altherneum.fr` | IP du VPS |
| MX | `altherneum.fr` | `mail.altherneum.fr` (10) |
| TXT | `altherneum.fr` | `v=spf1 mx ~all` |
| TXT | `dkim._domainkey.altherneum.fr` | clé générée dans mailcow (UI → Domains → DKIM) |
| TXT | `_dmarc.altherneum.fr` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@altherneum.fr` |

Vérifications :

```sh
dig +short MX altherneum.fr
dig +short TXT altherneum.fr
dig +short TXT dkim._domainkey.altherneum.fr
```

Tester la délivrabilité : <https://www.mail-tester.com/>.

## Ports et port 25

Ouvrir `25`, `465`, `587`, `110`, `143`, `993`, `995`, `4190`. La plupart des
fournisseurs VPS bloquent le port 25 sortant par défaut :

- demander le déblocage (procédure chez OVH/Hetzner/Scaleway selon
  l'hébergeur) ;
- ou configurer un **relais sortant** (`SMTP_RELAYHOST` dans mailcow) vers un
  service transactionnel.

Sans port 25 sortant, les mails partent mais n'arrivent pas : vérifier
`/var/log/mail.log` dans le conteneur `postfix-mailcow`.

## Comptes

Créer dans l'interface d'administration (<https://mail.altherneum.fr>) :

| Alias / boîte | Usage | Configuration |
|---|---|---|
| `postmaster@altherneum.fr` | administration mailcow | mot de passe fort |
| `noreply@altherneum.fr` | envoi depuis Azuriom | `AZURIOM_MAIL_*` |
| `git@altherneum.fr` | envoi depuis Forgejo | `FORGEJO_MAIL_*` |
| boîtes des membres | usage courant | — |

Créer les comptes `noreply@` et `git@` avec les mots de passe **déjà générés**
par `make init` (ne pas les remplacer dans `.env`) :

```sh
grep '^AZURIOM_MAIL_PASSWORD=' .env
grep '^FORGEJO_MAIL_PASSWORD=' .env
```

Puis activer l'envoi SMTP dans `.env` :

```sh
AZURIOM_MAIL_MAILER=smtp
FORGEJO_MAIL_ENABLED=true
```

```sh
make up          # recrée Azuriom et Forgejo avec le SMTP
```

Pour tester immédiatement : créer un compte sur Azuriom (inscription) puis
utiliser « mot de passe oublié ». Les mails doivent partir avec une
authentification SPF/DKIM valide.

## Migration des boîtes depuis l'ancien serveur

Les anciennes boîtes (si existantes) se transfèrent avec `imapsync`, la
procédure officielle : <https://docs.mailcow.email/migration/>. En résumé :

```sh
imapsync --host1 ancien.altherneum.fr --user1 user@… --password1 '…' --ssl1 \
         --host2 mail.altherneum.fr  --user2 user@… --password2 '…' --ssl2
```

Les boîtes sont à créer dans mailcow **avant** la synchronisation. Relancer
`imapsync` une seconde fois juste avant de couper l'ancien serveur permet de
rattraper les derniers messages.

## Exploitation

```sh
make mail-up / mail-down / mail-logs

# sauvegarde officielle
cd "$MAILCOW_DIR"
./helper-scripts/backup_and_restore.sh backup all

# mise à jour
cd "$MAILCOW_DIR"
git pull
docker compose pull
docker compose up -d
```

Après une mise à jour mailcow, vérifier que
`docker-compose.override.yml` est toujours compatible ; en cas de doute,
relancer `make mail-integrate`.

## Dépannage

| Symptôme | Piste |
|---|---|
| `mail.` renvoie 502 | mailcow éteint (`make mail-up`) ou mauvais port interne dans l'override |
| mail rejeté : « not authenticated » | SPF/DKIM manquants ou port 25 bloqué |
| pas de reception depuis l'extérieur | MX absent ou port 25 entrant fermé |
| « connection refused » depuis Azuriom | SMTP pas encore configuré : laisser `AZURIOM_MAIL_MAILER=log` en attendant |
| certificat mail (SMTP) expiré | vérifier `SKIP_LETS_ENCRYPT=n`, `ACME_DNS_CHALLENGE=y` et les logs `acme-mailcow` |
