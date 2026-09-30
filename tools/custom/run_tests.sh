#!/usr/bin/env bash
# Runs xi_test against its own database, mbetam_xi_test, never the live mbetam_xi.
#
# Why: every map process deletes accounts_sessions rows at startup, and xi_test starts with IP/port 0, which LSB treats
# as "delete ALL sessions" (src/map/map_engine.cpp: DELETE FROM accounts_sessions WHERE IF(ip = 0 AND port = 0, ...)).
# On the shared live database a test run logged every online player out of the database while their client stayed
# connected: "Cannot load session_key", then a hang on "Downloading data" at their next zone change (2026-09-30).
# Tests also create characters and items; they belong in a throwaway copy.
#
# Usage:
#   tools/custom/run_tests.sh [xi_test arguments...]     e.g. tools/custom/run_tests.sh --keep-going --file modules/htbf
#   tools/custom/run_tests.sh --refresh [xi_test args]   first copy the live database over the test one (after SQL /
#                                                        module SQL changes, dbtool updates, migrations)
# The test database was created once by Eric with sudo (see docs/custom/NOTES.md, 2026-09-30).
set -euo pipefail
cd "$(dirname "$0")/../.."

TEST_DB=mbetam_xi_test

if [[ "${1:-}" == --refresh ]]; then
    shift
    ~/lsb-venv/bin/python3 - "$TEST_DB" <<'PY'
import os, subprocess, sys, tempfile
sys.path.insert(0, 'tools/custom')
import migrate

test_db = sys.argv[1]
with migrate.MySQL() as db:
    if db.database == test_db:
        sys.exit('refusing: settings/network.lua already points at the test database')

    fd, dump = tempfile.mkstemp(prefix='xi-test-db-', suffix='.sql')
    os.close(fd)
    try:
        db.dump(dump)
        # Wipe the test database, then load the copy
        tables = [r[0] for r in db.query(f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{test_db}'")]
        if tables:
            drop = 'SET FOREIGN_KEY_CHECKS=0; ' + ' '.join(f'DROP TABLE IF EXISTS `{t}`;' for t in tables)
            r = db._run('mysql', ['--batch', test_db, '-e', drop])
            if r.returncode != 0:
                sys.exit(f'mysql error: {r.stderr.strip()}')
        with open(dump) as f:
            r = db._run('mysql', ['--batch', test_db], stdin=f)
        if r.returncode != 0:
            sys.exit(f'mysql error: {r.stderr.strip()}')
        # No live sessions in the copy
        db._run('mysql', ['--batch', test_db, '-e', 'DELETE FROM accounts_sessions;'])
    finally:
        os.remove(dump)
print(f'{test_db} refreshed from the live database')
PY
fi

export XI_NETWORK_SQL_DATABASE="$TEST_DB"
exec ./xi_test "$@"
