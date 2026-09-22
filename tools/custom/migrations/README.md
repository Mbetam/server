# Custom one-shot SQL migrations

Put a `.sql` file here when a patch has to change data **once** and nothing else carries that change to prod.
`tools/custom/migrate.py apply` runs it once per database and records it in the `custom_migrations` table.
`deploy.sh` runs `apply` on every deploy.

## Where does my DB change go?

| Change | Where | How it reaches prod |
|---|---|---|
| Game data in a table LSB ships (`item_usable`, `mob_droplist`, `item_mods`, ...) | Edit the matching `sql/<table>.sql` | `dbtool.py update` re-imports every `sql/` file changed since the DB's last version, and **replaces that whole table** |
| Game-data tweaks that belong to a module | `modules/custom/sql/*.sql` | `dbtool.py update` re-runs these on **every** update, so they must be safe to repeat (`UPDATE`, `REPLACE`, `INSERT IGNORE`) |
| Player data (`chars`, `char_*`, `accounts`, `auction_house`, ...), new tables, new columns, one-time fixes | **here** | `migrate.py apply`, exactly once |

dbtool never re-imports the player tables (`player_data` in `tools/dbtool.py`), so changes to those tables have to go here.

## Rules

- Name files `NNNN_short_name.sql` with the next free four-digit number, for example `0001_ah_bot_account.sql`. They run in filename order.
- **Never edit a migration after it has run on prod.** `migrate.py status` shows it as `CHANGED` and does not run it again. Write a new migration instead.
- Write migrations so they can run twice without harm wherever you can (`CREATE TABLE IF NOT EXISTS`, `INSERT IGNORE`, `ADD COLUMN IF NOT EXISTS`), in case something was already done by hand.
- If a migration was already done by hand on a server, record it without running it: `migrate.py mark-applied NNNN_name.sql`.
- Test on the test server first: `migrate.py apply`, check the result, then commit.
- No passwords or public IPs in these files. They are tracked in git.

## Example

```sql
-- 0002_example_add_column.sql
ALTER TABLE chars ADD COLUMN IF NOT EXISTS custom_flag TINYINT UNSIGNED NOT NULL DEFAULT 0;
```
