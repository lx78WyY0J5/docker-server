# fail2ban

fail2ban lit les **logs JSON de Traefik** et bannit les adresses IP abusives
via iptables sur l'hôte. Docs : <https://github.com/fail2ban/fail2ban>.

## Pourquoi ici plutôt que sur l'hôte

Depuis que les applications tournent en conteneurs, les logs Apache/SSH lus par
un fail2ban classique n'existent plus. Traefik centralise tous les accès HTTP
dans un access log JSON partagé via le volume `altherneum_traefik-logs` ; la
stack fournit les filtres correspondants.

## Composants

| Élément | Détail |
|---|---|
| image | `alpine:3.24` + `fail2ban` (paquet officiel Alpine) |
| `network_mode: host` | nécessaire pour que fail2ban modifie iptables sur l'hôte |
| `cap_add` | `NET_ADMIN`, `NET_RAW` |
| volumes | `altherneum_traefik-logs` (lecture seule), `altherneum_fail2ban-data` (base d'état) |

## Jails

| Jail | Déclencheur | `maxretry` / `findtime` |
|---|---|---|
| `traefik-400` | requêtes malformées | 3 / 24 h |
| `traefik-401` | échecs d'authentification (basic auth, API) | 3 / 96 h |
| `traefik-403` | accès interdits | 1 / 24 h |
| `traefik-404` | scans de chemins inexistants | 10 / 1 h |
| `traefik-405` | méthodes non autorisées | 1 / 24 h |
| `traefik-env` | tentatives d'accès à `.env` | 1 / 24 h |
| `traefik-wp` | scans WordPress classiques | 1 / 96 h |

Réglages généraux (`jail.local`) : bannissement **toutes ports** pendant 24 h,
escalade progressive (`bantime.increment`, max 90 jours), et exception pour
les plages Docker (`10/8`, `172.16/12`, `192.168/16`) afin de ne jamais couper
un conteneur.

Toutes les jails de ce dépôt surveillent Traefik, dont les ports sont publiés
par Docker. Le trafic externe est DNAT vers le conteneur et traverse
`FORWARD`/`DOCKER-USER`, **pas** `INPUT` : les règles sont donc insérées dans
`DOCKER-USER`. Vérification :

```sh
docker exec fail2ban iptables -S f2b-traefik-401
docker exec fail2ban iptables -S DOCKER-USER
```

> `chain = DOCKER-USER` est défini dans `[DEFAULT]` de `jail.local`. Le placer
> dans `banaction[...]` ne fonctionne pas : l'action par défaut de fail2ban
> passe déjà `chain="%(chain)s"` et écrase cette valeur (retour à `INPUT`).
> Pour une future jail visant un service de l'hôte (SSH…), définir
> `chain = INPUT` dans cette jail.

## Exploitation

```sh
docker exec fail2ban fail2ban-client status
docker exec fail2ban fail2ban-client status traefik-404
docker exec fail2ban fail2ban-client get traefik-404 banip

# débannir une IP
docker exec fail2ban fail2ban-client set traefik-404 unbanip 203.0.113.7

# recharger après modification d'un filtre
docker compose up -d --build fail2ban
```

## Ajouter un jail

1. créer `filter.d/traefik-<nom>.conf` (regex sur les champs `ClientHost` et
   `DownstreamStatus` du JSON) ;
2. créer `jail.d/traefik-<nom>.conf` (mêmes clés que les fichiers existants) ;
3. rebuilder la stack.

`fail2ban-regex` permet de tester un filtre sur un extrait de log :

```sh
docker exec fail2ban fail2ban-regex /var/log/traefik/access.log /etc/fail2ban/filter.d/traefik-404.conf
```

## Limites et précautions

- avec `network_mode: host`, le conteneur partage la pile réseau de l'hôte :
  les règles s'appliquent à `DOCKER-USER`, car les ports publiés par Docker
  passent par `FORWARD` ; une jail visant un service de l'hôte doit utiliser
  `chain = INPUT` ;
- derrière un CDN/proxy (Cloudflare…), l'IP source peut être celle du proxy :
  configurer `forwardedHeaders` dans Traefik pour voir l'IP réelle ;
- un utilisateur légitime qui rate plusieurs fois son mot de passe peut être
  banni : utiliser `unbanip` ;
- ajuster `maxretry`/`findtime` dans `jail.d/` plutôt que dans `jail.local`
  pour garder les seuils par type d'erreur.
