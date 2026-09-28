#!/usr/bin/env bash
# Start the four xi_* servers (the ones not already running) and wait for xi_map to finish loading.
# Used at boot by tools/custom/xi-servers.service.example; also fine to run by hand.
#   tools/custom/start_servers.sh
# Same start as deploy.sh (setsid + nohup, output in log/), so deploy.sh and manual restarts keep working as before.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

SERVERS=(xi_connect xi_search xi_world xi_map)
READY_TIMEOUT=180

ready_count() { grep -c "The map-server is ready to work" log/map-server.log 2>/dev/null || echo 0; }

before=$(ready_count)
started_map=0

for name in "${SERVERS[@]}"; do
    if pgrep -x "$name" > /dev/null; then
        echo "$name already running"
        continue
    fi

    setsid nohup "./$name" > /dev/null 2>&1 < /dev/null &
    echo "started $name (pid $!)"
    [[ "$name" == xi_map ]] && started_map=1
    sleep 1
done

if (( started_map )); then
    waited=0
    until (( $(ready_count) > before )); do
        sleep 1
        waited=$((waited + 1))
        if (( waited >= READY_TIMEOUT )); then
            echo "xi_map not ready after ${READY_TIMEOUT}s, check log/map-server.log" >&2
            exit 1
        fi
    done
    echo "xi_map ready after ~${waited}s"
fi

for name in "${SERVERS[@]}"; do
    pgrep -x "$name" > /dev/null || { echo "$name is not running (see log/ and dmp/)" >&2; exit 1; }
done

echo "All four servers up."
