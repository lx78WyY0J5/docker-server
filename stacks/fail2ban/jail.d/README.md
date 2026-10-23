# Jails fail2ban

Chaque fichier active un **jail** pour un filtre de [`../filter.d/`](../filter.d/)
et définit la durée de bannissement, le nombre d'essais et la fenêtre de
détection. Les réglages communs (bantime incrémental, réseau Docker ignoré,
action `DOCKER-USER`) sont dans [`../jail.local`](../jail.local).

| Jail | Filtre |
|---|---|
| `traefik-400.conf` | `traefik-400` |
| `traefik-401.conf` | `traefik-401` |
| `traefik-403.conf` | `traefik-403` |
| `traefik-404.conf` | `traefik-404` |
| `traefik-405.conf` | `traefik-405` |
| `traefik-env.conf` | `traefik-env` |
| `traefik-wp.conf` | `traefik-wp` |

## Ajouter un jail

Créer le filtre dans `../filter.d/`, puis un fichier `traefik-<nom>.conf` ici
avec au minimum :

```ini
[traefik-<nom>]
enabled = true
filter = traefik-<nom>
```

Les valeurs `maxretry`, `findtime` et `bantime` peuvent être héritées de
`jail.local` ou surchargées. Redémarrer ensuite la stack et vérifier :

```sh
docker exec fail2ban fail2ban-client status
docker exec fail2ban fail2ban-client status traefik-<nom>
```

Documentation : [fail2ban](../../../docs/services/fail2ban.md),
[jails](https://fail2ban.readthedocs.io/en/latest/configuration.html#jails) et
[README de la stack](../README.md).
