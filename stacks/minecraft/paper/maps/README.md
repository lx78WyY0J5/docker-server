# Cartes Minecraft

- Cartes de départ copiées depuis `Serveurs/<Carte>/Spawn.zip`
- L'image Paper les embarque dans `/opt/maps` et `paper/entrypoint.sh` extrait la carte correspondant au serveur dans son volume `/data`.

| Serveur | Carte |
|---|---|
| `hub` | `Hub` |
| `survie` | `Survie` |
| `anarchie` | `Survie` |
| `test` | `Survie` |
| `skyblock` | `SkyBlock` |
| `opprison` | `OPPrison` |

`creatif` et `rpg` n'ont pas de carte : Paper génère un monde vanilla.

- Les archives contiennent un monde nommé `Spawn`, d'où `MINECRAFT_LEVEL_NAME=Spawn` 
- Après avoir remplacé une archive, reconstruire l'image Paper (`sudo make paper-base`) puis recréer le serveur concerné (`sudo make up-service SERVICE=mc-hub`) 
- Le nouveau condensat déclenche la réinstallation du monde ; les modifications locales de ce monde sont alors remplacées