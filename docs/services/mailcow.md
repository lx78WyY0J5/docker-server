# mailcow (service)

La messagerie est fournie par **mailcow**, installé officiellement dans
`$MAILCOW_DIR` (défaut `/opt/mailcow-dockerized`). Ce dépôt ne gère que son
intégration Traefik.

- installation et configuration : [`stacks/mail/README.md`](../../stacks/mail/README.md)
- DNS, comptes, migration, dépannage : [`../06-mailcow.md`](../06-mailcow.md)

## Fichiers de l'intégration

| Fichier | Rôle |
|---|---|
| `stacks/mail/traefik.override.yaml.template` | override Compose généré |
| `scripts/mail-integrate.sh` | écrit `$MAILCOW_DIR/docker-compose.override.yml` |
| `Makefile` | `mail-integrate`, `mail-up`, `mail-down`, `mail-logs` |

## Ce que fait l'override

```sh
make mail-integrate
# → $MAILCOW_DIR/docker-compose.override.yml
```

- `nginx-mailcow` est connecté à `altherneum_proxy` et ses ports `80/443`
  sont supprimés (`ports: !reset []`) : Traefik devient l'entrée web ;
- routeur `mail.<domaine>` : interface d'administration mailcow en HTTPS
  (certificat mailcow via DNS-01 ; `insecureSkipVerify` accepte aussi le
  certificat auto-signé de secours) ;
- routeur `webmail.<domaine>` + `mails.<domaine>` : redirection permanente vers
  `https://mail.<domaine>/SOGo/…` ;
- les middlewares globaux (`secure-headers`) sont réutilisés depuis la
  configuration dynamique de Traefik.

SMTP/IMAP gardent leurs propres ports et leurs certificats : Traefik n'y
touche pas.

## Commandes

```sh
make mail-integrate     # (re)génère l'override
make mail-up            # docker compose up -d dans MAILCOW_DIR
make mail-down          # arrêt de mailcow
make mail-logs          # logs en direct
```

Après `git pull` de ce dépôt, relancer `make mail-integrate` puis
`make mail-up` pour propager les éventuelles évolutions de l'override.

## Ordre de démarrage recommandé

1. `make up` (Traefik et le reste) ;
2. installer/configurer mailcow ;
3. `make mail-integrate && make mail-up` ;
4. créer les comptes `noreply@` et `git@` avec les mots de passe déjà
   générés dans `.env` (`AZURIOM_MAIL_PASSWORD`, `FORGEJO_MAIL_PASSWORD`) ;
5. activer le SMTP dans `.env` (`AZURIOM_MAIL_MAILER=smtp`,
   `FORGEJO_MAIL_ENABLED=true`) et `make up`.

## Vérifications

```sh
curl -sI https://mail.altherneum.fr | head -n1
curl -sI https://webmail.altherneum.fr | head -n1   # 301 vers /SOGo/

docker compose logs traefik | grep -i mailcow
```

Un `502` signifie que `nginx-mailcow` n'est pas joignable sur
`altherneum_proxy` : vérifier que mailcow est démarré **avec** l'override
(`docker compose -f docker-compose.yml -f docker-compose.override.yml up -d`).
