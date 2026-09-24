# Release notes

One section per weekly patch, newest first. Each section is created by `tools/custom/release.sh notes <tag>`
and is also saved as the message of its git tag, so `git show <tag>` prints the same notes.
How the whole test-to-prod cycle works: [DEPLOY.md](DEPLOY.md).

Keep public IPs and passwords out of this file. It is tracked in git.

<!-- new releases go below this line -->

## patch-2026-09-24

### For players
- **Augmenter:** Rare gear can now be augmented, a full bag no longer blocks it, and you can add all four augments in one trade: after each augment the Augmenter goes straight back to its menu.
- **Beastmaster jug pets deal +50% damage**, both Ready moves and auto-attacks. Call your pet again to get it.
- **Healer trusts no longer spam Protectra / Shellra** (Apururu (UC), Kupipi, Karaha-Baruha, Yoran-Oran (UC), Cherukiki, Mihli Aliapoh). Protectra/Shellra only reach party members within about 10 yalms of the healer; stay close to get them.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none
- Other manual steps: none. One new module in `modules/init.txt` (comes with the tag): `custom/lua/jug_pet_damage.lua`; it loads at the restart `deploy.sh` does.
- Rebuild: no
- `sql/` files that `dbtool update` will re-import:
  - none
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23-6
- Augmenter: Rare gear, and several augments in one trade (7c962ae866)
- Jug pets deal +50% damage (Eric's choice, above retail) (0b46bba039)
- Healer trusts: stop spamming Protectra/Shellra (a3d3a2daa6)

## patch-2026-09-23-6

### For players
- **NM placeholders are now marked:** a monster that can turn into an NM shows **"PH"** in front of its name, e.g. "PH Forest Hare" for Jaggedy-Eared Jack. Kill it and the NM takes its place a few minutes later. Very long names lose their last letters (15-character limit).

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none
- Other manual steps: none. One new module in `modules/init.txt` (comes with the tag): `custom/lua/mark_nm_placeholders.lua`; it loads at the restart `deploy.sh` does.
- Rebuild: no
- `sql/` files that `dbtool update` will re-import:
  - none
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23-5
- Mark NM placeholders with a "PH " name prefix (ea2ca40760)

## patch-2026-09-23-5

### For players
- **Bags and wardrobes are now 80 slots**: Inventory, Mog Satchel, Mog Sack, Mog Case and Mog Wardrobes 1-8. Log out and back in once to get them.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none
- Other manual steps: none. One new module in `modules/init.txt` (comes with the tag): `custom/lua/bags_to_80.lua`; it loads at the restart `deploy.sh` does. This is the first deploy with the fixed `deploy.sh`: no manual server stop needed.
- Rebuild: no
- `sql/` files that `dbtool update` will re-import:
  - none
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23-4
- Bags and wardrobes raised to 80 for every character (e2894687cd)

## patch-2026-09-23-4

### For players
- **New: Leveling Guide** in Norg (the floating book). A free teleport to one good leveling spot per level range: 10-24 Valkurm Dunes, 25-50 Oldton Movalpolos, 50-70 Bhaflau Thickets, 70-80 Kuftal Tunnel, 80-90 Mount Zhayolm, 90-99 Yahse Hunting Grounds. Not usable in battle.
- **The Augmenter and the Trust Vendor moved to Norg**, next to each other (they're no longer in Lower Jeuno).
- **Trust Vendor:** shorter menus, 5 trusts per page with Next / Prev. Before, long pages were cut off and some trusts didn't show.
- **Geomancer:** Collimated Fervor (level 40) now works.
- **Rune Fencer:** Odyllic Subterfuge (level 96) now works: it lowers the target's magic accuracy for 30 seconds (more magic attack down with job points). Tell us how it feels.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none
- Other manual steps: **stop the four servers before this deploy, one last time** (SIGTERM). The servers now running were started by the old `deploy.sh` and still hold `sql/backups/.deploy.lock`; this patch fixes `start_servers()` so later deploys don't need it. One new module in `modules/init.txt` (comes with the tag): `custom/lua/leveling_guide_npc.lua`; it loads at the restart `deploy.sh` does.
- Rebuild: no
- `sql/` files that `dbtool update` will re-import:
  - none
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23-3
- deploy.sh: don't let the started servers inherit the deploy lock (523e0c0ff0)
- Job audit tool; GEO Collimated Fervor and RUN Odyllic Subterfuge (9d5fc5955f)
- Leveling Guide NPC; Augmenter and Trust Vendor moved to Norg; menus fit the 150-byte limit (8e944e219f)

## patch-2026-09-23-3

### For players
- **Trust Vendor** in Lower Jeuno, beside the Augmenter. It sells 69 trusts you can't get anywhere else here, for 100,000 gil each. They come in three groups:
  - **Event and campaign (46):** trusts from login campaigns, Mog Pells and seasonal events, such as Zeid, Lion, Moogle, the Ark Angels and Shantotto II.
  - **Story (12):** trusts whose quest isn't in the game yet, such as Lilisette, Romaa Mihgo, Selh'teus and Iroha.
  - **Unity (11):** Apururu (UC), Yoran-Oran (UC) and the other UC trusts.

  You need a Trust permit (any nation's Trust quest), and the vendor only lists trusts you don't know yet.
- **8 trusts now come from their quests, as in retail:** Gessho (Passing Glory), Gadalar (Embers of His Past), Zazarg (Fist of the People), Klara (Bonds of Mythril), Excenmille [S] (Face of the Future) and Arciela (The Light Within). Cornelia and Matsui-P come free with a Trust permit. If you already finished one of these, you learn the trust the next time you zone.
- **`!shop`** now sells Holy Water (5,000 gil), Prism Powder and Silent Oil (2,500 gil each).

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none
- Other manual steps: none. Two new modules are listed in `modules/init.txt` (tracked, comes with the tag): `custom/lua/trust_quest_grants_login.lua` and `custom/lua/trust_vendor_npc.lua`. New modules load only at a restart, which `deploy.sh` does.
- Rebuild: no
- `sql/` files that `dbtool update` will re-import:
  - none
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23-2
- Trust acquisition: quest grants for 8 trusts, Trust Vendor for 69 (c5098c4a52)
- !shop: Holy Water 5,000 gil, Prism Powder and Silent Oil 2,500 gil each (92abb690fc)

## patch-2026-09-23-2

### For players
- **`!buff` EXP bonus is now +100%** (was +200%). Regen, Refresh, Regain +50 and the 10 hours are unchanged. If you still have the old buff it keeps working until it runs out; using `!buff` again gives the new one.
- **Healer and support trusts fixed:**
  - Apururu (UC) now casts Curaga when 3 or more of you are hurt, and uses Martyr, Devotion and Convert when she is low on MP.
  - Yoran-Oran (UC) now uses Nott to get MP back and keeps Stoneskin up.
  - Monberaux now uses Life Water (party Regen), Samson's Strength, Dragon Shield and his other mixes. Before, he stopped after Guard Drink.
  - Koru-Moru was checked: he already buffs, debuffs and dispels like in retail.
- **Trusts act more reliably:** fixed a bug that made trusts skip abilities they were supposed to use (it locked them out for up to a minute). They now take one action at a time, as in retail.
- **38 trusts now have their retail subjob** (for example Yoran-Oran WHM/BLM, Koru-Moru RDM/WHM, Gilgamesh SAM/WAR). This gives them the subjob's extra HP/MP, stats and traits, so many trusts are a bit sturdier.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua`: none (EXP x1.8 is already set on prod).
- Other manual steps: none. The `!buff` change reaches the EXP pool top-up only after a restart, which `deploy.sh` does anyway.
- Rebuild: yes (C++ changed: `src/map/ai/helpers/gambits_container.cpp`, the trust gambit fix)
- `sql/` files that `dbtool update` will re-import:
  - sql/mob_pools.sql (trust subjobs)
  - sql/mob_spell_lists.sql (Stoneskin for Yoran-Oran (UC))
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - none

### Commits since patch-2026-09-23
- !buff: EXP bonus +200% -> +100% (6fd0c6590a)
- Trusts round 3: Apururu (UC), Yoran-Oran (UC), Monberaux; gambit retry fix (core) (8889ac22f4)
- Trusts: retail subjobs for 38 trusts; engine test for healer/support trusts; notes (9a5e3d38cd)

## patch-2026-09-23

### For players
- **EXP x1.8** from everything: kills, quests, FoV/GoV pages and Records of Eminence (it was retail x1.0). `!buff` still stacks on top.
- **10 trusts now fight properly:** Cid, Gilgamesh, Halver, Ingrid, Kukki-Chebukki, Lilisette II, Makki-Chebukki, Margret, Morimar and Nashmeira use their retail job abilities, spells and weapon skills (before, they only auto-attacked or never cast). Morimar's and Lilisette II's moves have estimated damage: tell us if they feel off.
- **Beastmaster:** every jug pet's Ready moves now work (22 pets had none that worked, mostly the level 99 ones).
- Rhapsody key items were checked: each gives its retail +30% EXP or capacity points.
- Already live on this server before this patch, now part of it: NMs on a timer respawn within 2 minutes (HNMs within 1 hour), the Augmenter's combined Acc/Atk, Rng.Acc/Rng.Atk and Mag.Acc/MAB stats and new prices.

### For the admin (prod)
- Settings to copy by hand into prod's git-ignored `settings/*.lua` (then restart the servers):
  - `settings/map.lua`: `EXP_RATE = 1.8`
  - `settings/main.lua`: `EXP_RATE = 1.800`, `BOOK_EXP_RATE = 1.800`, `ROE_EXP_RATE = 1.800`
  - Keep prod's own `NM_RESPAWN_CAP = 120` / `HNM_RESPAWN_CAP = 3600` (the new `settings/default/map.lua` keys default to 0 = off).
- Other manual steps: none.
- Expected during the deploy: prod is on its local branch `prod-fix/2026-09-23` (commit 5844be0936). That commit reached `custom` squashed and scrubbed (fe016bee15), so `deploy.sh` will say this tag "is not a descendant of the current version". That is expected. The branch no longer exists on GitHub.
- New GM commands: `!dummy` (training dummy), `!allmissions`, `!allkeyitems` (GM level 1+).
- Rebuild: yes (C++ changed: the respawn cap, already built on prod from its own commit; same code)
- `sql/` files that `dbtool update` will re-import:
  - sql/abilities.sql
  - sql/mob_skill_lists.sql
  - sql/mob_skills.sql
  - sql/pet_skills.sql
- New custom migrations:
  - none
- `settings/default/` changed upstream (compare with prod's `settings/*.lua`):
  - settings/default/map.lua

### Commits since patch-2026-09-22
- Add tools/custom/trust_audit.py: what is broken or not coded per trust (25a079f7ab)
- Trusts: retail AI and weapon skills for the 10 obtainable-but-broken trusts (6a1451a467)
- Add tools/custom/bst_jug_audit.py: can each jug pet be called, do its Ready moves work (716e90538d)
- BST: every jug pet's Ready moves work (73 -> 98 of 98 jugs) (98b2cc9b9c)
- Add !dummy: a training dummy for combat testing (GM only); notes for the BST round (aed48ff132)
- Bring in prod's fixes (prod-fix/2026-09-23), scrubbed of player details (fe016bee15)
- Rhapsody key items: test that they give their retail EXP bonus; notes for EXP x1.8 (1c6a113f92)

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
