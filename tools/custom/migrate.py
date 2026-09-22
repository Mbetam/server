#!/usr/bin/env python3
"""
One-shot SQL migrations for our custom changes, plus the DB backup/restore used by deploy.sh.

Migrations live in tools/custom/migrations/NNNN_short_name.sql and each one runs exactly once per
database. What has run is recorded in the `custom_migrations` table. Deliberately NOT under sql/:
`dbtool.py update` imports every changed file under sql/ (subfolders included), which would run a
migration a second time, outside this tracking.

Usage (from anywhere; uses the git-ignored settings/network.lua for credentials):
    migrate.py status                 list migrations and whether each has run
    migrate.py apply                  run every pending migration, in filename order
    migrate.py mark-applied NAME      record NAME as done without running it (it was applied by hand)
    migrate.py backup PATH            mysqldump the whole database to PATH (same flags as dbtool)
    migrate.py restore PATH           load a dump made by `backup` back into the database
    migrate.py zoneip                 print the DISTINCT zone_settings.zoneip values (one per line)
    migrate.py set-zoneip IP          UPDATE zone_settings SET zoneip = IP (all rows)

The password never appears on a command line: mysql/mysqldump read it from a mode-600 temp file.
"""

import hashlib
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ah_bot'))
from db import REPO_ROOT, network_settings  # noqa: E402

MIGRATIONS_DIR = os.path.join(REPO_ROOT, 'tools', 'custom', 'migrations')

TRACKING_TABLE = """
CREATE TABLE IF NOT EXISTS `custom_migrations` (
  `name` varchar(128) NOT NULL,
  `checksum` char(64) NOT NULL,
  `applied_at` datetime NOT NULL DEFAULT current_timestamp(),
  `applied_by` varchar(32) NOT NULL DEFAULT 'apply',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"""


class MySQL:
    """Runs the mysql/mysqldump clients with credentials from a temp defaults file."""

    def __enter__(self):
        s = network_settings()
        self.database = s['SQL_DATABASE']
        fd, self.defaults = tempfile.mkstemp(prefix='xi-mysql-', suffix='.cnf')
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, 'w') as f:
            f.write('[client]\n')
            f.write(f"host={s.get('SQL_HOST', '127.0.0.1')}\n")
            f.write(f"port={s.get('SQL_PORT', '3306')}\n")
            f.write(f"user={s['SQL_LOGIN']}\n")
            f.write(f"password=\"{s['SQL_PASSWORD']}\"\n")
        return self

    def __exit__(self, *exc):
        os.remove(self.defaults)

    def _run(self, tool, args, stdin=None, stdout=subprocess.PIPE):
        cmd = [tool, f'--defaults-extra-file={self.defaults}', *args]
        return subprocess.run(cmd, stdin=stdin, stdout=stdout, stderr=subprocess.PIPE, text=True)

    def query(self, sql):
        """Returns rows as lists of strings (tab-separated batch output, no header)."""
        r = self._run('mysql', ['--batch', '--skip-column-names', self.database, '-e', sql])
        if r.returncode != 0:
            sys.exit(f'mysql error: {r.stderr.strip()}')
        return [line.split('\t') for line in r.stdout.splitlines()]

    def source(self, path):
        """Runs a .sql file. Stops at the first error (mysql's default in batch mode)."""
        with open(path) as f:
            r = self._run('mysql', ['--batch', self.database], stdin=f)
        return r.returncode == 0, r.stderr.strip()

    def dump(self, path):
        with open(path, 'w') as f:
            r = self._run('mysqldump', ['--hex-blob', '--add-drop-trigger', '--single-transaction',
                                        '--routines', self.database], stdout=f)
        if r.returncode != 0:
            sys.exit(f'mysqldump error: {r.stderr.strip()}')


def sha256(path):
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def migration_files():
    if not os.path.isdir(MIGRATIONS_DIR):
        return []
    return sorted(n for n in os.listdir(MIGRATIONS_DIR) if n.endswith('.sql'))


def applied(db):
    db.query(TRACKING_TABLE)
    return {name: checksum for name, checksum in db.query('SELECT name, checksum FROM custom_migrations')}


def cmd_status(db):
    done = applied(db)
    pending = 0
    for name in migration_files():
        path = os.path.join(MIGRATIONS_DIR, name)
        if name not in done:
            print(f'  PENDING  {name}')
            pending += 1
        elif done[name] != sha256(path):
            print(f'  CHANGED  {name}  (edited after it ran; the change was NOT applied, write a new migration)')
        else:
            print(f'  done     {name}')
    for name in sorted(set(done) - set(migration_files())):
        print(f'  done     {name}  (file no longer in the repo)')
    print(f'{pending} pending')
    return 0


def cmd_apply(db):
    done = applied(db)
    todo = [n for n in migration_files() if n not in done]
    if not todo:
        print('No pending custom migrations.')
        return 0
    for name in todo:
        path = os.path.join(MIGRATIONS_DIR, name)
        print(f'Applying {name} ...')
        ok, err = db.source(path)
        if not ok:
            print(f'FAILED: {name}\n{err}', file=sys.stderr)
            print('Stopped. Later migrations were not run. Fix it, or restore the pre-deploy backup.', file=sys.stderr)
            return 1
        db.query(f"INSERT INTO custom_migrations (name, checksum) VALUES ('{name}', '{sha256(path)}')")
    print(f'Applied {len(todo)} migration(s).')
    return 0


def cmd_mark_applied(db, name):
    path = os.path.join(MIGRATIONS_DIR, name)
    if not os.path.isfile(path):
        sys.exit(f'No such migration: {name}')
    applied(db)
    db.query(f"INSERT INTO custom_migrations (name, checksum, applied_by) VALUES ('{name}', '{sha256(path)}', 'mark') "
             f"ON DUPLICATE KEY UPDATE applied_by = applied_by")
    print(f'Marked {name} as applied (not run).')
    return 0


def main(argv):
    if len(argv) < 2 or argv[1] not in ('status', 'apply', 'mark-applied', 'backup', 'restore', 'zoneip', 'set-zoneip'):
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd in ('mark-applied', 'backup', 'restore', 'set-zoneip') and len(argv) != 3:
        sys.exit(f'{cmd} needs exactly one argument')

    with MySQL() as db:
        if cmd == 'status':
            return cmd_status(db)
        if cmd == 'apply':
            return cmd_apply(db)
        if cmd == 'mark-applied':
            return cmd_mark_applied(db, argv[2])
        if cmd == 'backup':
            db.dump(argv[2])
            return 0
        if cmd == 'restore':
            ok, err = db.source(argv[2])
            if not ok:
                sys.exit(f'restore failed: {err}')
            return 0
        if cmd == 'zoneip':
            for (ip,) in db.query('SELECT DISTINCT zoneip FROM zone_settings'):
                print(ip)
            return 0
        if cmd == 'set-zoneip':
            ip = argv[2]
            if not all(c.isdigit() or c == '.' for c in ip):
                sys.exit('set-zoneip expects a dotted IPv4 address')
            db.query(f"UPDATE zone_settings SET zoneip = '{ip}'")
            return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
