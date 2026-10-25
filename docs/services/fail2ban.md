# fail2ban

**Rôle :** lit les logs de Traefik et bloque les adresses IP qui font trop
d'erreurs (tentatives de connexion, scans, 404 en masse).

**Conteneur :** `fail2ban`  
**Adresse :** aucune. C'est un service de protection en arrière-plan.

## Mot de passe

Aucun. Il n'y a pas d'interface web.

## Variables `.env`

Aucune variable spécifique, seulement `TZ` (fuseau horaire). La configuration
est dans `stacks/fail2ban/`.

## Démarrer / arrêter

```sh
sudo make up-service SERVICE=fail2ban
sudo make ps-service SERVICE=fail2ban
sudo make logs-service SERVICE=fail2ban
sudo make stop SERVICE=fail2ban
```

## Nettoyer

```sh
sudo CONFIRM=yes make clean-service SERVICE=fail2ban
```

Cela supprime le volume `altherneum_fail2ban-data` (base des bannissements).

## Fonctionnement

- Lit `/var/log/traefik/access.log`.
- Bannit via `iptables` dans la chaîne `DOCKER-USER`.
- `5` erreurs en `24 h` donnent un bannissement de `24 h`.
- Les bannissements sont progressifs, jusqu'à `90` jours.
- La jail `traefik-404` bannit après `10` erreurs 404 en `1 h`.
- Les réseaux privés et la boucle locale ne sont jamais bannis.

## Commandes utiles

Voir l'état des jails :

```sh
docker exec fail2ban fail2ban-client status
```

Voir une jail précise :

```sh
docker exec fail2ban fail2ban-client status traefik-404
```

Débannir une IP :

```sh
docker exec fail2ban fail2ban-client set traefik-404 unbanip 203.0.113.10
```

## Sécurité

- Le conteneur utilise `network_mode: host` et les capacités `NET_ADMIN` et
  `NET_RAW` : il modifie le pare-feu de l'hôte.
- Il est prévu pour Linux.
- Si vous vous bannissez vous-même, utilisez la commande de débannissement
  ci-dessus depuis une autre connexion.

## Dépannage

- **fail2ban ne démarre pas** : vérifiez que le volume de logs Traefik existe et
  que Traefik a déjà écrit `access.log`.
- **Aucun bannissement** : vérifiez que Traefik écrit bien dans
  `/var/log/traefik/access.log` et que le format des logs correspond aux
  filtres.
- **Trafic bloqué à tort** : consultez `fail2ban-client status`, puis débannissez
  l'IP.
