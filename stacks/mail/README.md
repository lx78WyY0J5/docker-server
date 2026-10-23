# Stack mail (mailcow)

La messagerie d'Altherneum est déléguée à **mailcow** (stack officielle,
installée séparément par son propre installateur). Ce dossier ne recrée pas un
serveur mail : il contient uniquement l'**intégration Traefik**.

Documentation du projet : [`docs/06-mailcow.md`](../../docs/06-mailcow.md) et
[`docs/services/mailcow.md`](../../docs/services/mailcow.md).

## Pourquoi une stack séparée

mailcow est composé d'une vingtaine de conteneurs (Postfix, Dovecot, Rspamd,
ClamAV, SOGo, MySQL, Redis, Unbound…) et gère lui-même ses certificats, ses
mises à jour et sa base. La réécrire en Compose serait une source de bugs de
sécurité. L'installation officielle est donc conservée telle quelle, derrière
Traefik pour le web (mailcow gère son propre postfix/dovecot).

## Installation

```sh
# 1. Installer mailcow (script officiel)
umask 0022
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
./generate_config.sh
#    → renseigner le hostname : mail.altherneum.fr

# 2. Adapter mailcow.conf
#    MAILCOW_HOSTNAME=mail.altherneum.fr
#    HTTP_BIND / HTTPS_BIND : l'override retire les ports publiés.
#    TLS SMTP/IMAP : activer ACME DNS-01 (voir ci-dessous), car Traefik
#    occupe déjà les ports 80/443.

# 3. Faire pointer l'installation depuis ce dépôt
#    MAILCOW_DIR dans .env doit correspondre (défaut : /opt/mailcow-dockerized)
make mail-integrate   # écrit docker-compose.override.yml dans MAILCOW_DIR
make mail-up          # démarre mailcow avec l'override
```

`make mail-integrate` génère `$MAILCOW_DIR/docker-compose.override.yml` à
partir de [`traefik.override.yaml.template`](traefik.override.yaml.template) :

- `nginx-mailcow` rejoint le réseau `altherneum_proxy` ;
- les ports `80/443` de mailcow sont supprimés (`ports: !reset []`) puisque
  Traefik les publie déjà ;
- `mail.<domaine>` → interface d'administration mailcow (HTTPS, certificat
  interne accepté côté Traefik) ;
- `webmail.<domaine>` et `mails.<domaine>` → redirection vers `/SOGo/`.

## TLS SMTP/IMAP (DNS-01)

Traefik publie déjà `80`/`443` : le HTTP-01 de mailcow ne peut pas répondre.
Depuis mailcow 2026-03, utiliser le challenge **DNS-01**, qui ne nécessite pas
le port 80 et couvre aussi `mail.<domaine>` pour Postfix/Dovecot :

```ini
# mailcow.conf
ACME_DNS_CHALLENGE=y
ACME_DNS_PROVIDER=dns_ovh        # selon le registrar (acme.sh)
ACME_ACCOUNT_EMAIL=admin@altherneum.fr
# SKIP_LETS_ENCRYPT doit rester à n
```

Configurer les identifiants API dans
`$MAILCOW_DIR/data/conf/acme/dns-01.conf`, puis `make mail-up`. Documentation :
<https://docs.mailcow.email/post_installation/firststeps-ssl-dns/>.

Sans DNS-01, mailcow utilise un certificat auto-signé : les clients IMAP/SMTP
le refusent et les serveurs distants peuvent dégrader la livraison. Ne pas
mettre `SKIP_LETS_ENCRYPT=y` en espérant que Traefik fournisse le certificat
mail : Traefik ne termine que le HTTPS web.

## DNS et ports

À créer chez le registrar (voir <https://docs.mailcow.email/prerequisite/prerequisite-dns/>) :

| Type | Nom | Valeur |
|---|---|---|
| A | `mail.altherneum.fr` | IP du VPS |
| A | `webmail.altherneum.fr` | IP du VPS |
| MX | `altherneum.fr` | `mail.altherneum.fr` (priorité 10) |
| TXT | `altherneum.fr` | `v=spf1 mx ~all` |
| TXT | `dkim._domainkey.altherneum.fr` | clé DKIM générée dans mailcow |
| TXT | `_dmarc.altherneum.fr` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@altherneum.fr` |

Ports à ouvrir sur le pare-feu : `25`, `465`, `587`, `993`, `995`, `110`,
`143`, `4190`. Vérifier que le fournisseur ne bloque pas le port `25`
(procédure de déblocage chez la plupart des hébergeurs).

## Comptes à créer

1. `postmaster@altherneum.fr` (compte administrateur) ;
2. `noreply@altherneum.fr` pour Azuriom ;
3. `git@altherneum.fr` pour Forgejo ;
4. les boîtes réelles des membres.

Puis mettre à jour `.env` :

```sh
AZURIOM_MAIL_MAILER=smtp          # + AZURIOM_MAIL_PASSWORD (compte noreply)
FORGEJO_MAIL_ENABLED=true         # + FORGEJO_MAIL_PASSWORD (compte git)
```

et relancer `make up` pour appliquer.

## Exploitation

```sh
make mail-up      # démarrer mailcow
make mail-down    # arrêter mailcow
make mail-logs    # suivre les logs mailcow
```

Pour les mises à jour, utiliser la procédure officielle :
<https://docs.mailcow.email/deb_ubuntu/#updating-mailcow->. Les sauvegardes
mailcow se font avec `./helper-scripts/backup_and_restore.sh` (bien plus
complet que le `make backup` de ce dépôt, qui ne couvre que les stacks
recréées ici).
