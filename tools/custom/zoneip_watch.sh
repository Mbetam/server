#!/usr/bin/env bash
# Keeps zone_settings.zoneip in step with the home connection's public IP, for a server reached through a DDNS name.
#
# Why: players' loaders use the DDNS name, so login follows an IP change by itself, but the zone address the map server
# hands out must be a raw IP in zone_settings.zoneip (LSB does not take a hostname there), and xi_map caches it when it
# loads its zones. After an IP change, players log in and then hang at their first zone change.
#
# What it does, each run (cron, every 15 minutes):
#   1. Resolves the DDNS name (IPv4). If that fails, or the DB's zoneip already matches, it stops there.
#   2. Otherwise sets zoneip to the new IP (tools/custom/migrate.py set-zoneip) and marks a restart as pending.
#   3. A pending restart happens as soon as no real player is logged in (charid < 20000000; test characters start
#      at 20000000), so nobody is kicked; until then each run checks again. It restarts ALL four servers: xi_world
#      also loads zone_settings once at startup and routes each login to the map server by zoneip; with a stale copy
#      every login hangs on "Downloading data" (seen 2026-10-01 after restarting only xi_map).
#
# Usage: tools/custom/zoneip_watch.sh <ddns-name>
# The name is given on the command line (crontab), not stored here: like the IP, it stays out of the public repo.
# Crontab line (crontab -e, no sudo):
#   */15 * * * * /home/mbetam/server/tools/custom/zoneip_watch.sh <ddns-name> >> /home/mbetam/server/log/zoneip_watch.log 2>&1
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

PY="$HOME/lsb-venv/bin/python3"
PENDING="log/zoneip_restart_pending"
HOST="${1:?usage: $0 <ddns-name>}"

stamp() { date '+%Y-%m-%d %H:%M:%S'; }

# One run at a time (a restart can take a minute)
exec 9> log/zoneip_watch.lock
flock -n 9 || exit 0

new_ip="$(getent ahostsv4 "$HOST" | awk 'NR == 1 { print $1 }')"
if [[ ! "$new_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$(stamp) could not resolve $HOST; nothing changed"
    exit 0
fi

current="$("$PY" tools/custom/migrate.py zoneip)"
if [[ "$current" != "$new_ip" ]]; then
    "$PY" tools/custom/migrate.py set-zoneip "$new_ip"
    echo "$(stamp) zoneip changed: ${current//$'\n'/,} -> $new_ip; restart pending"
    touch "$PENDING"
fi

[[ -f "$PENDING" ]] || exit 0

online="$("$PY" - <<'PY'
import sys
sys.path.insert(0, 'tools/custom')
import migrate
with migrate.MySQL() as db:
    print(db.query("SELECT COUNT(*) FROM accounts_sessions WHERE charid < 20000000")[0][0])
PY
)"

if [[ "$online" != 0 ]]; then
    echo "$(stamp) restart for the new zoneip waits: $online player(s) online"
    exit 0
fi

SERVERS=(xi_map xi_world xi_connect xi_search)
for name in "${SERVERS[@]}"; do
    pkill -x "$name" || true
done
for _ in $(seq 1 60); do
    running=0
    for name in "${SERVERS[@]}"; do
        pgrep -x "$name" > /dev/null && running=1
    done
    (( running )) || break
    sleep 1
done

# 9>&-: the servers must not inherit the lock, or it would be held for as long as xi_map runs
if tools/custom/start_servers.sh 9>&-; then
    rm -f "$PENDING"
    echo "$(stamp) servers restarted with zoneip $new_ip"
else
    echo "$(stamp) restart FAILED, check log/; will retry next run"
fi
