#!/usr/bin/env bash
# Deploy a tagged weekly patch on this server (meant for prod; works on any clone).
#
#   tools/custom/deploy.sh --dry-run patch-2026-09-29   show what would change, touch nothing
#   tools/custom/deploy.sh patch-2026-09-29             deploy it
#   tools/custom/deploy.sh --rollback                   go back to the version before the last deploy
#
# Steps: fetch + checks (servers still up) -> stop the four xi_* -> DB backup -> checkout tag
#        -> submodules -> build -> dbtool update -> custom migrations -> restore zone IP -> start -> log check
#
# Warn players BEFORE running it: stopping xi_map disconnects everyone.
# If a step fails the servers stay STOPPED and the script says how to roll back.
# Nothing here needs sudo. See docs/custom/DEPLOY.md.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

PY="${PYTHON:-$HOME/lsb-venv/bin/python3}"
export PATH="$HOME/lsb-venv/bin:$PATH"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-$HOME/.local/libdwarf/lib/pkgconfig}"

BACKUP_DIR="$REPO/sql/backups"          # git-ignored
HISTORY="$BACKUP_DIR/deploy-history.log" # one line per deploy: time from to backup
SERVERS=(xi_connect xi_search xi_world xi_map)
STOP_TIMEOUT=90
READY_TIMEOUT=240

red()   { printf '\e[31m%s\e[0m\n' "$*"; }
green() { printf '\e[32m%s\e[0m\n' "$*"; }
step()  { printf '\n\e[1m== %s\e[0m\n' "$*"; CURRENT_STEP="$*"; }
die()   { red "ERROR: $*"; exit 1; }

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

# --- server process helpers -------------------------------------------------------------------

# PIDs of our xi_* processes (only ones running from this repo, in case another copy exists).
server_pids() {
    local name pid
    for name in "${SERVERS[@]}"; do
        for pid in $(pgrep -x "$name" || true); do
            if [[ "$(readlink "/proc/$pid/cwd" 2>/dev/null)" == "$REPO" ]]; then echo "$pid"; fi
        done
    done
}

stop_servers() {
    local pids
    pids="$(server_pids)"
    if [[ -z "$pids" ]]; then
        echo "No xi_* servers running."
        return
    fi
    echo "Sending SIGTERM (clean shutdown, players are saved) to: $(echo $pids)"
    kill -TERM $pids
    local waited=0
    while [[ -n "$(server_pids)" ]]; do
        (( waited >= STOP_TIMEOUT )) && die "servers still running after ${STOP_TIMEOUT}s: $(echo $(server_pids)). Not touching anything."
        sleep 2; (( waited += 2 ))
    done
    green "All servers stopped after ${waited}s."
}

start_servers() {
    local name
    [[ -z "$(server_pids)" ]] || die "servers already running, refusing to start a second copy"
    local map_log="log/map-server.log" f
    for f in log/connect-server.log log/search-server.log log/world-server.log "$map_log"; do
        if [[ -f $f ]]; then LOG_START[$f]=$(wc -l < "$f"); else LOG_START[$f]=0; fi
    done
    local before=${LOG_START[$map_log]}

    for name in "${SERVERS[@]}"; do
        [[ -x "./$name" ]] || die "./$name missing, build did not produce it"
        setsid nohup "./$name" > /dev/null 2>&1 < /dev/null &
        echo "started $name (pid $!)"
    done

    echo "Waiting for xi_map to finish loading (usually ~45s) ..."
    local waited=0
    until tail -n +"$((before + 1))" "$map_log" 2>/dev/null | grep -q 'ready to work'; do
        (( waited >= READY_TIMEOUT )) && die "xi_map not ready after ${READY_TIMEOUT}s, check log/map-server.log"
        sleep 3; (( waited += 3 ))
    done
    sleep 10  # let anything that crashes right after loading do so

    local missing=()
    for name in "${SERVERS[@]}"; do
        pgrep -x "$name" > /dev/null || missing+=("$name")
    done
    (( ${#missing[@]} == 0 )) || die "not running after start: ${missing[*]} (see log/ and dmp/)"
    green "All four servers up; xi_map ready after ~${waited}s."
}

# erro/crit lines written since start_servers ran.
check_logs() {
    local f bad=0
    for f in "${!LOG_START[@]}"; do
        [[ -f $f ]] || continue
        local lines
        lines=$(tail -n +"$(( ${LOG_START[$f]} + 1 ))" "$f" | grep -E '\]\[(error|erro|critical|crit)\]' || true)
        if [[ -n "$lines" ]]; then
            red "$f has error lines since start:"
            echo "$lines" | head -20
            bad=1
        fi
    done
    if (( bad == 0 )); then green "No error/critical lines in log/ since start."; else red "Review the lines above; the servers are up."; fi
}

# --- DB helpers ---------------------------------------------------------------------------------

backup_db() {
    local out="$1"
    mkdir -p "$BACKUP_DIR"
    "$PY" tools/custom/migrate.py backup "$out"
    [[ -s "$out" ]] || die "backup $out is empty"
    tail -1 "$out" | grep -q 'Dump completed' || die "backup $out looks incomplete (no 'Dump completed' footer)"
    green "DB backup: $out ($(du -h "$out" | cut -f1))"
}

build() {
    [[ -f build/build.ninja || -f build/Makefile ]] || die "no configured build/ dir; run the cmake configure step from CLAUDE.md first"
    cmake --build build -j"$(nproc)"
}

# --- failure reporting --------------------------------------------------------------------------

CURRENT_STEP="checks"
declare -A LOG_START=()
FROM_REF=""
BACKUP_FILE=""
on_exit() {
    local rc=$?
    (( rc == 0 || rc == 2 )) && return
    red ""
    red "DEPLOY FAILED during: $CURRENT_STEP"
    if [[ -n "$BACKUP_FILE" ]]; then
        red "The servers are STOPPED (unless the failure was at the final log check)."
        red "Previous version: $FROM_REF    DB backup: $BACKUP_FILE"
        red "Options: fix the problem and re-run the same deploy, or run: tools/custom/deploy.sh --rollback"
    else
        red "Nothing was changed; servers were not stopped."
    fi
}
trap on_exit EXIT

# --- modes --------------------------------------------------------------------------------------

do_rollback() {
    [[ -f "$HISTORY" ]] || die "no deploy history ($HISTORY), nothing to roll back to"
    local line when from to backup
    line="$(tail -1 "$HISTORY")"
    read -r when from to backup <<< "$line"
    [[ "$backup" != ROLLBACK ]] || die "the last entry is already a rollback ($line); roll forward with deploy.sh <tag> instead"
    [[ -f "$backup" ]] || die "backup $backup from the last deploy is gone"

    echo "Last deploy: $when  $from -> $to"
    echo "This will: stop the servers, restore the DB to $backup (taken right before that deploy),"
    echo "check out $from, rebuild, and start the servers."
    red  "Everything players did since that deploy (EXP, items, gil, AH sales) will be LOST."
    red  "If the AH bot timer runs on this box, stop it first:  sudo systemctl stop ah-bot.timer"
    read -r -p "Type 'rollback' to continue: " answer
    [[ "$answer" == "rollback" ]] || die "aborted"

    BACKUP_FILE="$backup"; FROM_REF="$to"
    step "Stop servers";        stop_servers
    step "Safety backup of the current DB"
    backup_db "$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)-before-rollback-from-$to.sql"
    step "Restore DB from $backup"; "$PY" tools/custom/migrate.py restore "$backup"
    step "Check out $from";     git checkout --quiet --detach "$from"; git submodule update --init --recursive
    step "Build";               build
    step "Start servers";       start_servers
    step "Log check";           check_logs
    echo "$(date -Is) $to $from ROLLBACK" >> "$HISTORY"
    green "Rolled back to $from."
}

do_deploy() {
    local tag="$1" dry="$2"

    step "Fetch and check"
    git fetch --quiet origin --tags
    git rev-parse -q --verify "refs/tags/$tag" > /dev/null || die "tag $tag not found on origin (did you push it from test?)"
    [[ -z "$(git status --porcelain --untracked-files=no)" ]] || { git status --short --untracked-files=no; die "tracked files are modified on this server. Prod must not be edited by hand; make the change on test instead"; }
    FROM_REF="$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)"
    local target; target="$(git rev-parse --short "$tag^{commit}")"
    [[ "$(git rev-parse HEAD)" != "$(git rev-parse "$tag^{commit}")" ]] || die "already at $tag"
    git merge-base --is-ancestor HEAD "$tag" || red "Note: $tag is not a descendant of the current version ($FROM_REF). That is expected for a rollback-by-tag, otherwise check the tag."

    echo "Current: $FROM_REF    Target: $tag ($target)"
    echo; echo "Commits:"; git log --oneline --no-merges "HEAD..$tag" | head -50
    local changed; changed="$(git diff --name-only HEAD "$tag")"
    echo; echo "Changed areas:"
    for area in src/ sql/ modules/ scripts/ settings/default/ tools/custom/migrations/ CMakeLists.txt; do
        local n; n=$(grep -c "^$area" <<< "$changed" || true)
        if (( n > 0 )); then printf '  %-28s %s file(s)\n' "$area" "$n"; fi
    done
    if grep -q '^src/\|CMake\|^cmake/\|^ext/' <<< "$changed"; then
        echo "  -> C++ changed: the build step will compile (ccache helps)"
    else
        echo "  -> no C++ changes: the build step should be a no-op"
    fi
    if grep -q '^settings/default/' <<< "$changed"; then
        red "  -> settings/default/ changed: compare with settings/*.lua after the deploy (see RELEASES.md for this patch)"
    fi
    if grep -q '^tools/custom/migrations/.*\.sql$' <<< "$changed"; then
        echo "  -> new/changed custom migrations:"; grep '^tools/custom/migrations/.*\.sql$' <<< "$changed" | sed 's/^/       /'
    fi

    if [[ "$dry" == 1 ]]; then
        green "Dry run: nothing changed."
        exit 0
    fi

    local running; running="$(server_pids)"
    [[ -z "$running" ]] || red "Servers are running. Stopping xi_map disconnects every player."
    read -r -p "Deploy $tag now? [y/N] " answer
    [[ "$answer" == [yY] ]] || die "aborted"

    exec 9> "$BACKUP_DIR/.deploy.lock"
    flock -n 9 || die "another deploy is running"

    step "Stop servers";   stop_servers
    step "Back up DB"
    BACKUP_FILE="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)-pre-$tag.sql"
    backup_db "$BACKUP_FILE"
    local zoneips; zoneips="$("$PY" tools/custom/migrate.py zoneip)"

    step "Check out $tag"
    git checkout --quiet --detach "$tag"
    git submodule update --init --recursive
    echo "$(date -Is) $FROM_REF $tag $BACKUP_FILE" >> "$HISTORY"

    step "Build";          build
    step "dbtool update";  (cd tools && "$PY" dbtool.py update)
    step "Custom migrations"; "$PY" tools/custom/migrate.py apply

    # zone_settings is not a protected table: if a patch changed sql/zone_settings.sql, dbtool re-imported it
    # and every zoneip went back to 127.0.0.1, which would stop anyone entering the world. Put it back.
    step "Zone IP"
    if [[ $(wc -l <<< "$zoneips") == 1 && "$("$PY" tools/custom/migrate.py zoneip)" != "$zoneips" ]]; then
        "$PY" tools/custom/migrate.py set-zoneip "$zoneips"
        green "zone_settings.zoneip was reset by the update; restored the previous value."
    else
        echo "Zone IP unchanged."
    fi

    step "Start servers";  start_servers
    step "Log check";      check_logs
    green ""
    green "Deployed $tag. Log in with a client to confirm, then post the patch notes."
}

# --- main ---------------------------------------------------------------------------------------

case "${1:-}" in
    --rollback) do_rollback ;;
    --dry-run)  [[ -n "${2:-}" ]] || usage; do_deploy "$2" 1 ;;
    ""|-h|--help) usage ;;
    -*) usage ;;
    *)          do_deploy "$1" 0 ;;
esac
