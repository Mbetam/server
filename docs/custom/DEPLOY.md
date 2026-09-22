# Test → prod: weekly patches

Two servers run from the same repo (`origin` = `Mbetam/server`):

- **Test** (`ffxi-test`): all work happens here, on branch `custom`. Commit and push freely.
- **Prod**: runs only tagged releases (`patch-YYYY-MM-DD`) and is never edited by hand. A hotfix is made on test and shipped as a tag like any other patch (`patch-2026-10-01-hotfix`).

Upstream LandSandBoat merges happen on test only and reach prod with the next patch.

## What travels through git, and what doesn't

| Thing | In git? | How it reaches prod |
|---|---|---|
| `scripts/`, `modules/`, `src/`, `sql/`, `tools/`, `docs/` | yes | `deploy.sh` checks out the tag |
| Game-data tables (`sql/*.sql`, `modules/custom/sql/`) | yes | `dbtool.py update`, run by `deploy.sh` |
| One-time DB changes, player-table changes, new tables | yes, as `tools/custom/migrations/NNNN_*.sql` | `migrate.py apply`, run by `deploy.sh` ([rules](../../tools/custom/migrations/README.md)) |
| `settings/*.lua` (rates, passwords, IPs) | **no** (git-ignored) | Copied by hand. Each patch's notes list what to copy |
| Characters, accounts, AH contents | **no** | Stay in prod's DB |
| `zone_settings.zoneip` (the public IP) | **no** | `deploy.sh` saves it before the update and puts it back afterwards |
| systemd units (AH bot timer, ...) | only as `*.example` files | Installed by hand with sudo; listed under "manual steps" in the notes |

**Rule:** never change the database by hand on test for something prod also needs. Write a migration, or edit the `sql/` file, and run it on test the same way prod will.

## Weekly cycle

### On test

```bash
# 1. Finish and test the week's work; everything committed on `custom`.
# 2. Draft the notes (commit list, sql/ files, migrations and rebuild need are filled in for you)
tools/custom/release.sh notes patch-2026-09-29
# 3. Edit docs/custom/RELEASES.md: write "For players", list the settings and manual steps, remove the DRAFT line
git add docs/custom/RELEASES.md && git commit -m "Release notes for patch-2026-09-29"
# 4. Push custom, then create and push the tag (asks before pushing)
tools/custom/release.sh tag patch-2026-09-29
```

### On prod

Warn players first (stopping `xi_map` disconnects everyone), then:

```bash
cd ~/server
tools/custom/deploy.sh --dry-run patch-2026-09-29   # commits, changed areas, rebuild needed?  Touches nothing.
tools/custom/deploy.sh patch-2026-09-29
```

`deploy.sh` runs these steps in order and stops at the first failure:

1. Fetch, check that the tag exists and that prod has no edits to tracked files. The servers are still up at this point.
2. Ask for confirmation, then stop the four `xi_*` with SIGTERM (a clean shutdown that saves players) and wait for them to exit.
   The servers must be down before the checkout: a running `xi_map` hot-reloads `scripts/` the moment git writes them.
3. `git checkout --detach <tag>`, then submodules.
4. `mysqldump` the whole DB to `sql/backups/<time>-pre-<tag>.sql`. The checkout doesn't touch the DB, so this is still the pre-patch state; it runs after the checkout so the tag's own `migrate.py` takes it. The password is read from `settings/network.lua` and never goes on a command line.
5. `cmake --build build`. With no C++ changes this does nothing; otherwise ccache keeps it short.
6. `dbtool.py update`: re-imports the `sql/` files changed since the DB's version, re-runs module SQL, and runs LSB's own migrations.
7. `migrate.py apply`: runs our custom migrations.
8. Puts `zone_settings.zoneip` back if the update reset it.
9. Starts the servers, waits for `xi_map`'s "ready to work" line, checks that all four processes stay up, and prints any error or critical log lines.

Then copy the settings listed in the notes into prod's `settings/*.lua` (the watcher reloads them, but a restart is safer for most settings), log in with a client, and post the "For players" part of the notes.

### If something goes wrong

- **Failure before the servers stop:** nothing has changed. Fix the problem and run the deploy again.
- **Failure after the servers stop:** they stay stopped. The script prints the old version and the backup file. Either fix the problem and run the same deploy again, or roll back:
  ```bash
  tools/custom/deploy.sh --rollback
  ```
  This restores the pre-deploy DB, checks out the previous version, rebuilds, and starts the servers.
  **Anything players did since that deploy is lost**, so right after a failed deploy it costs nothing, but a day later it does.
  In that case prefer a hotfix patch. Stop the AH bot timer before a rollback (`sudo systemctl stop ah-bot.timer`).
- `sql/backups/deploy-history.log` has one line per deploy: time, old version, new version, backup file.

## First-time setup on prod

1. Prod must already build with the recipe in `CLAUDE.md` (a configured `build/`, `~/lsb-venv` with `tools/requirements.txt` and `mariadb`), and `settings/network.lua` must be in place.
2. The deploy key or HTTPS access must allow `git fetch origin --tags`.
3. Nothing to prepare for the migrations: 0001 skips the AH bot rows if `tools/ah_bot/setup.sql` was already run by hand, and 0003 moves the bot to id 10000001.
   Check beforehand that no real account or character has id 10000001; if one does, 0003 stops with a duplicate-key error.
   For a later migration that was already done by hand: `~/lsb-venv/bin/python3 tools/custom/migrate.py mark-applied NNNN_name.sql`.
4. The first time, `deploy.sh` isn't in prod's checkout yet. Take it from the tag and run the copy from the repo root:
   ```bash
   cd ~/server && git fetch origin --tags
   git show patch-2026-09-22:tools/custom/deploy.sh > /tmp/deploy.sh
   bash /tmp/deploy.sh --dry-run patch-2026-09-22
   bash /tmp/deploy.sh patch-2026-09-22
   ```
   After that, `tools/custom/deploy.sh` is in the checkout. It always runs from a temporary copy of itself, so it can check out a new version of its own file safely.
5. The first deploy switches prod from the `custom` branch to a detached tag. That is expected: `git describe --tags` shows which patch prod is on.
6. Check that `tools/config.yaml` on prod has a `db_ver`. Without it, `dbtool update` does a full re-import of every non-player table (slower, still safe).

**Never run `xi_test` on prod.** It uses the server's own database and, when it finishes, deletes every account and character with an id of 20,000,000 or more (`src/test/test_char.cpp`).

## Checks before tagging (on test)

- `./xi_test` (servers stopped) or at least `./xi_test --file 'modules/'`. Known failures are listed in NOTES.md.
- Any new migration has been applied on test with `migrate.py apply` and the result checked.
- Settings changed this week are in the notes.
