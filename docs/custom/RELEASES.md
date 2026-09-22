# Release notes

One section per weekly patch, newest first. Each section is created by `tools/custom/release.sh notes <tag>`
and is also saved as the message of its git tag, so `git show <tag>` prints the same notes.
How the whole test-to-prod cycle works: [DEPLOY.md](DEPLOY.md).

Keep public IPs and passwords out of this file. It is tracked in git.

<!-- new releases go below this line -->

## patch-2026-09-22

### For players
- **More gil and EXP:** monsters drop 75% more gil (every monster now drops at least 875), and EXP is 30% higher from everything: kills, quests, FoV/GoV pages and Records of Eminence. `!buff` is unchanged and stacks on top.
- **New `!signet` command:** gives Signet, Sanction, Sigil or Ionis, whichever belongs to the area you are standing in.
- **Cheaper Auction House:** the AH bot's prices are now about 1/15 of what they were. Items cost much less, and the bot also pays less when it buys up what you list.
- **`!ahprice` fix:** searching an exact name like `!ahprice cesti` now finds that item instead of saying it matches several.

### For the admin (prod)
- **First patch through this workflow.** Prod has no `tools/custom/` yet, so run the script from the tag
  (see DEPLOY.md "First-time setup on prod"). The commit list below is everything since the fork; prod most
  likely already runs up to `e77cadf8a5`. `deploy.sh --dry-run` shows the real list and whether anything compiles.
- Settings to copy by hand into prod's git-ignored `settings/*.lua` (then restart the servers):
  - `settings/map.lua`: `MOB_GIL_MULTIPLIER = 3.5` (was 2.0), `EXP_RATE = 3.25` (was 2.5)
  - `settings/main.lua`: `EXP_RATE = 3.250`, `BOOK_EXP_RATE = 3.250`, `ROE_EXP_RATE = 3.250` (were 2.500)
- Other manual steps: none required. Before deploying, check that no real account or character has id 10000001
  (migration 0003 moves the AH bot there). If the AH bot timer runs on prod, it picks up the new pricing and id at the checkout.
  Before any `--rollback`, stop it (`sudo systemctl stop ah-bot.timer`), or the old bot code lists under the old id.
- Expect a one-time message from LSB's `char_flags` migration: it adds the AH bot's missing `char_flags` row.
- Rebuild: only if prod is older than the core edits (skill-up cap, augment fix); from `e77cadf8a5` it is a no-op.
- `sql/` files that `dbtool update` will re-import:
  - sql/item_usable.sql
- New custom migrations:
  - tools/custom/migrations/0001_ah_bot_account.sql
  - tools/custom/migrations/0002_ah_bot_reprice_x2.sql
  - tools/custom/migrations/0003_ah_bot_move_to_10000001.sql
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - settings/default/main.lua
  - settings/default/map.lua

### Commits since 4ce94020bf
- Add project notes: CLAUDE.md and docs/custom/NOTES.md (61413db9b0)
- Add !buff command module: EXP +200%, Regen/Refresh/Regain +50 (626ff0f4cb)
- Add QoL command modules: !home, !tele, !telelist, !shop (0f6de0eed3)
- Notes: test baseline, going public, hairpin, +50% speed, retail-stats design (cb0f2cea84)
- Fix !buff effect saving, make it last 10 hours, add starter Survival Guides (ef87a9ada3)
- Add player-facing roadmap (docs/custom/ROADMAP.md) (dabaed11be)
- Add the Augmenter: custom augments on retail gear (32e660d469)
- Add !city: teleport to a nation's main city, for every player (d88a556480)
- Every mob drops at least 500 gil (e1b089a4bd)
- Move the Lower Jeuno Augmenter, update the roadmap, record the gil floor (04f25c3c66)
- Augmenter: stack the same augment up to 4 times, Moogle model; fix equip mod double count (34bf66c7e9)
- Add !status: stats of your target, or yourself, for every player (8511dda878)
- Every monster drops gil, max skill-up rates, lottery NMs always pop (e33beb5516)
- Skill-up amount at the maximum too (0.5 -> 0.9), for crafting as well as combat (2ed1e9cef3)
- Add the AH bot: keeps materials stocked, buys out unsold gear (not yet turned on) (dc33e98821)
- AH bot: stock the whole AH, not just materials (owner override) (f631edfd9a)
- AH bot: equipment quantity 3, stack listings, and a new !ahprice command (2b3ac55785)
- Nexus Cape: 10 second cooldown; verify !ahprice in the real engine (cc26e3dc27)
- AH bot: timer example now 30 seconds (was 15 minutes) (e77cadf8a5)
- Test -> prod workflow: weekly patch tags, deploy script, custom DB migrations (d2efb973e5)
- AH bot prices x30 -> x2; !ahprice finds exact names first (0a4965a4a3)
- Gil floor 500 -> 875 (gil drops +75%) (6d1ead0f14)
- Add !signet: Signet, Sanction, Sigil or Ionis for the area you are in (a81227a001)
- Move the AH bot from id 90000001 to 10000001; notes for this round (42b130d86d)
- deploy.sh: bootstrap-safe first deploy on prod (1c3b252a88)
- deploy.sh: rollback also restores dbtool's db_ver (9c885b355e)
