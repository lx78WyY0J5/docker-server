#!/bin/sh
# Prépare les volumes nommés avant de lancer code-server.
# Un volume Docker neuf est créé root ; code-server tourne avec l'utilisateur
# coder et doit pouvoir écrire ses réglages et ses extensions.
set -eu

sudo mkdir -p /home/coder/.local/share/code-server/extensions
sudo chown -R coder:coder \
    /home/coder/.local/share/code-server \
    /home/coder/workspace

# L'ENTRYPOINT de l'image officielle contient « --bind-addr 0.0.0.0:8080 ».
# En le remplaçant, on doit réinjecter cette adresse, sinon code-server
# n'écoute que sur 127.0.0.1 et Traefik renvoie 502.
if [ "$#" -eq 0 ]; then
    set -- --bind-addr 0.0.0.0:8080 .
fi

exec /usr/bin/entrypoint.sh "$@"
