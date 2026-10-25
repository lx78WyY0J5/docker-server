#!/bin/sh
# =============================================================================
# Supprime les conteneurs d'un service et les volumes nommés qui lui sont
# exclusifs. Un volume partagé avec un autre service, ou encore utilisé par un
# autre conteneur, est conservé.
# =============================================================================
set -eu

SERVICE=${1:-}
[ -n "$SERVICE" ] || {
    echo "Usage : $0 SERVICE" >&2
    exit 1
}

cd "$(dirname "$0")/.."
ENV_FILE=${ENV_FILE:-.env}
[ -f "$ENV_FILE" ] || {
    echo "Erreur : $ENV_FILE introuvable. Lancer make init." >&2
    exit 1
}

# Volumes nommés déclarés pour le service dans la configuration Compose.
# Les volumes partagés avec un autre service sont signalés par un préfixe "!".
VOLUMES=$(
    docker compose --env-file "$ENV_FILE" config |
        awk -v svc="$SERVICE" '
            /^services:$/ { in_services = 1; next }
            in_services && /^[^ ]/ { in_services = 0 }
            in_services && /^  [^ ]/ {
                current = $1
                sub(/:$/, "", current)
                in_service = (current == svc)
                in_volumes = 0
                next
            }
            in_services && /^    volumes:$/ { in_volumes = 1; next }
            in_services && in_volumes && /^    [^ ]/ { in_volumes = 0 }
            in_services && in_volumes && /^      - type: / { type = $3 }
            in_services && in_volumes && /^        source: / && type == "volume" {
                if (in_service)
                    target[$2] = 1
                else
                    other[$2] = 1
            }
            END {
                for (volume in target) {
                    if (volume in other)
                        print "!" volume
                    else
                        print volume
                }
            }
        '
)

docker compose --env-file "$ENV_FILE" rm -sfv "$SERVICE"

for volume in $VOLUMES; do
    case "$volume" in
        '!'*)
            echo "! volume conservé (partagé avec un autre service) : ${volume#!}" >&2
            continue
            ;;
    esac

    docker volume inspect "$volume" >/dev/null 2>&1 || continue

    if [ -z "$(docker ps -aq --filter "volume=$volume")" ]; then
        docker volume rm "$volume" >/dev/null
        echo "→ volume supprimé : $volume"
    else
        echo "! volume conservé (utilisé par un autre conteneur) : $volume" >&2
    fi
done
