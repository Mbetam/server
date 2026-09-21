# Custom server notes

Running log of what was tried and what broke, so context survives between sessions.

## 2026-09-21 — charutils test (`scripts/tests/systems/charutils.lua`)

**Ask:** "write a test for charutils.cpp".

**Approach:** This repo has no C++ unit-test framework. Tests are Lua suites under `scripts/tests/` run by `xi_test`
(an embedded `xi_map`; see `docs/wiki/Testing.md`). `charutils` is only reachable through `CLuaBaseEntity` bindings, so the suite
drives it that way:

- key items: add/has/del, including the table boundary at 511/512 (`charutils::addKeyItem` uses `id / 512` and `id % 512`)
- titles: add/set/has/del/get, including the byte boundary at 7/8 and clearing of the selected title
- spells: add/has/del and the options table
- EXP: `addExp` (amount, ignores `map.EXP_RATE`, level-up carry-over, level cap, dead player) and `delExp` (amount, `expLost`, de-level, floor at level 1)

Items and gil were left out on purpose: `systems/items/inventory.lua` and `systems/items/transactions.lua` already cover them.

**Status: RUN, 31/31 pass** (`./xi_test --keep-going --file 'systems/charutils'`, ~16 s, 2026-09-21, after the Tier 1 build below).
The first run was 29/31. Both failures were a wrong assumption in the test, not a charutils bug: `spawnPlayer({ level = 50 })` returns a character
already at the top of its level (`exp = next - 1`, e.g. 7799/7800), so `addExp(100)` correctly levelled it up. Fix: `before_each` calls
`player:delExp(5000)` and asserts there is room below the next level. Assertion messages in the EXP tests now print exp/next/level.
Not done: a mutation check (breaking `charutils` on purpose to prove each test can fail); the two initial failures are the only evidence so far that the assertions bite.
`xi_test` uses the same DB as the server (`mbetam_xi`, from `settings/network.lua`); a run left no rows in `chars`/`accounts`/`char_vars`.
Stop the four `xi_*` servers before running it (embedded map server; avoids port/DB interference), then restart them.

**Run it:** `./xi_test --keep-going --file 'systems/charutils'`  (not committed on purpose: still untracked)

**Side observation (not changed):** `CLuaBaseEntity::delExp` does `std::clamp<uint16>(exp, 0, 65535)`. With an explicit `uint16` template
argument the `uint32` is truncated before clamping, so `delExp(65536)` becomes `delExp(0)`, which then falls back to the normal
death-loss formula. Only the `takexp` GM command uses it, so low impact.

## 2026-09-21 — Tier 1 bring-up (Ubuntu 22.04)

- Host is 22.04, not 24.04. Installed g++-15 from `ppa:ubuntu-toolchain-r/test`; CMake 4.4 comes from pip (venv at `~/lsb-venv`).
  Every shell that runs cmake needs: `export PATH=$HOME/lsb-venv/bin:$PATH PKG_CONFIG_PATH=$HOME/.local/libdwarf/lib/pkgconfig`.
- **Broke:** first `cmake` configure failed with `No package 'libdwarf' found`. LSB's `ext/CMakeLists.txt` makes cpptrace use an *external*
  libdwarf via pkg-config on Linux. Ubuntu 22.04's `libdwarf-dev` is 20210528: too old and ships no `.pc` file.
- **Fix (no repo change):** built libdwarf 2.1.0 from source into `~/.local/libdwarf` (the exact libdwarf-lite commit cpptrace pins,
  `5dfb2cd2aacf2bf473e5bfea79e41289f88b3a5f`, static, `-fPIC`, dwarfdump off) and pointed `PKG_CONFIG_PATH` at its `lib/pkgconfig`.
  Configure then reported `Found libdwarf, version 2.1.0`.
  Fallback if this ever breaks: edit the Linux branch of `ext/CMakeLists.txt` to set `CPPTRACE_USE_EXTERNAL_LIBDWARF OFF` so cpptrace fetches its own copy (small tracked-file diff, so note it in the commit).
- **Broke (build 1):** every compile failed with `/bin/sh: /home/mbetam/server/ccache: not found`. Cause: I passed
  `-DCMAKE_CXX_COMPILER_LAUNCHER=ccache`, but LSB's `cmake/Cache.cmake` already finds ccache and re-declares both launchers as
  `CACHE FILEPATH`; the untyped bare `ccache` was then resolved against the source dir. Fix: drop that flag and clear the cached value
  (`cmake -S . -B build -UCMAKE_CXX_COMPILER_LAUNCHER -UCMAKE_C_COMPILER_LAUNCHER`); the cache now holds `/usr/bin/ccache`.
  Lesson: the background-task "exit 0" notification was only my wrapper's trailing `echo`; always read the log's `BUILD_EXIT=`.
- Configure line now used (mold accepted; ccache comes from Cache.cmake):
  `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc-15 -DCMAKE_CXX_COMPILER=g++-15 -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=mold`
- The repo's own preset is `default` (Ninja Multi-Config, also `build/`). We use single-config Ninja per CLAUDE.md instead.
- DB `mbetam_xi` / user `mbetam` created and login verified on MariaDB 10.6.23. `settings/network.lua` holds the credentials (git-ignored).

### Build bring-up: everything that broke, in order (all fixed; final build 0 failed steps)

1. **ccache launcher** — see above. Drop `-DCMAKE_CXX_COMPILER_LAUNCHER`.
2. **Wrong libdwarf header** — with libdwarf 2.1.0 installed to `~/.local/libdwarf`, cpptrace still compiled against `/usr/include/libdwarf/libdwarf.h`
   (old API: `dwarf_init_path_a` not declared, `dwarf_finish` arity). LSB's cpptrace includes `<libdwarf/libdwarf.h>`, and libdwarf-lite installs
   headers flat into `include/`. Fix: `mkdir ~/.local/libdwarf/include/libdwarf && cp ~/.local/libdwarf/include/{libdwarf.h,dwarf.h} ~/.local/libdwarf/include/libdwarf/`.
3. **LTO link crash** — `-flto=auto` + mold: "GCC LTO is detected, so falling back to ld.bfd", then `pthread_create has failed: Resource temporarily unavailable`
   (limits were not the cause: 127966 procs, cgroup pids 84457). Fix: `-DENABLE_IPO=OFF` (also matches the fast-rebuild goal).
4. **-Werror vs GCC 15 (LTO off)** — LTO had been hiding these. Categories seen: `null-dereference`, `maybe-uninitialized`, `array-bounds` (61x, all inside bundled sol2),
   `stringop-truncation`, `nonnull`. Downgraded with `-Wno-error=<name>` only.
   - `stringop-truncation` in `src/common/utils.cpp:550,602`: benign, deliberate fixed-width `strncpy` into linkshell/signature fields.
   - `nonnull` in `CLuaBaseEntity::getEVA()` (`src/map/lua/lua_base_entity.cpp:15467`): **real latent upstream bug** — the error path calls
     `m_PBaseEntity->getName()` right after the `if` proved `m_PBaseEntity` null. Dead in normal use. Worth an upstream PR someday; not changed here.
5. **Wrong libdwarf at link** — `-ldwarf` with no `-L` picked the system `libdwarf.so` (no `dwarf_init_path_a`). Fix: `-L$HOME/.local/libdwarf/lib` in `CMAKE_EXE_LINKER_FLAGS`.
6. **Static libdwarf needs zlib** — `undefined symbol ... uncompress` for xi_search/xi_connect/xi_world (xi_map/xi_test already pulled zlib in).
   Fix: `Libs: -L${libdir} -ldwarf -lz -lzstd` in `~/.local/libdwarf/lib/pkgconfig/libdwarf.pc`, then `cmake -S . -B build -ULIBDWARF_*` because `pkg_check_modules` caches the old value.

Final result: `xi_connect xi_map xi_search xi_world xi_test` all present in the repo root. Cold non-LTO compile with an empty ccache took about 12 minutes on 16 cores.
Tooling gotcha: a background task's "exit 0" notification is only the wrapper's trailing `echo`; always trust the log's own `BUILD_EXIT=` line.

### Tier 1 status (2026-09-21)

- DB imported with `cd tools && ~/lsb-venv/bin/python3 dbtool.py update full` (empty DB, local `sql/*.sql`, ~45 s, no errors): 118 tables,
  `item_basic` 23536, `mob_spawn_points` 6642, `zone_settings` 300, `chars`/`accounts` empty. Did not use "Reset DB".
- Started from the repo root: `./xi_connect ./xi_search ./xi_world ./xi_map` (detached with `setsid nohup`). `xi_map` ready in ~45 s. All four stay up, no `erro`/`crit` lines.
- One `warn` from `xi_map`: `luautils::GetMobByID Mob doesn't exist (16887851)` — a script references a mob absent from the DB. Cosmetic; upstream data.
- Listening: TCP 54230, 54231, 54001 (xi_connect), 54002 (xi_search), 127.0.0.1:54003 (xi_world); UDP 54230 (xi_map).
- **Not yet done (Tier 1 exit criterion): a real client logging in and creating a character.** Needs the client set up on a PC (Tier 2), the ports above reachable
  from that PC, and the zone IPs pointed at this VM's address instead of 127.0.0.1 (dbtool "Maintenance Tasks" has an external-IP helper).

## 2026-09-21 — Tier 2 progress (LAN client, GM, 99/99)

- Network: VM is `192.168.0.104` (ens33), PC `192.168.0.10`, same /24. Client: Ashita (may switch to Windower).
- An earlier client login was refused by xi_connect: `incorrect client version: got 302602xx_x, expected 302609xx_x` (`VER_LOCK = 2`). Client was then patched and account `Mbetam` (id 1000) / character `Tester` (charid 1) were created.
- **Zone IPs:** every row of `zone_settings.zoneip` was `127.0.0.1`, so xi_connect told the client to reach the map server at `127.0.0.1:54230` (= the PC itself). Set to the VM address with the
  same statement dbtool's "Set zone IP addresses" runs: `UPDATE zone_settings SET zoneip = '192.168.0.104';` (300 rows). Re-run this if the VM's IP ever changes.
- **Firewall:** `ufw.service` is "active" but `/etc/ufw/ufw.conf` has `ENABLED=no`, so the VM filters nothing. The PC already reached TCP 54001/54230/54231/54002.
  Router port forwarding is only needed for players from OUTSIDE the LAN. UDP 54230 (xi_map) is the one port not proven until a client enters the world.
- **GM:** `UPDATE chars SET gmlevel = 4 WHERE charid = 1;` (Post-Install-Guide default). Level 4 adds `exec`, `reloadglobal`, `breaklinkshell`, `setbattlefieldtime`.
  Level 5 adds the hot-reload commands (`reloadquest`, `reloadinteraction`, `reloadrecipes`, `reloadnavmesh`, ...), `rebuildnavmesh`, and `crash` (crashes xi_map).
  Bump later with `UPDATE chars SET gmlevel = 5 WHERE charid = 1;` (takes effect on next zone) — worth doing for Tier 4 module work.
- **99/99 (settings are git-ignored):** `settings/main.lua` `INITIAL_LEVEL_CAP = 99` (was 50); `settings/map.lua` `SUBJOB_RATIO = 3` (equal sub level: 99/99; default 1 = 99/49).
  `INITIAL_LEVEL_CAP` only applies to characters created AFTER the change; the per-character cap lives in `char_jobs.genkai`, so Tester was raised with
  `UPDATE char_jobs SET genkai = 99 WHERE charid = 1;` done while the servers were stopped (a running xi_map would overwrite it on save).
  Note: I stopped the servers with a bad `pgrep` wait loop once and one process was still exiting; re-verified `genkai` afterwards — safe.
- Not touched yet: EXP_RATE (two knobs: `settings/main.lua` for script EXP, `settings/map.lua` for combat EXP), drop rates, `SUBJOB_QUEST_LEVEL`/`ADVANCED_JOB_LEVEL` (NocSouls: advanced jobs from 15), `START_INVENTORY`.
- Servers restarted with these settings: all four up, `xi_map` ready in ~47 s, no erro/crit lines.

## 2026-09-21 — EXP rate 2.5x

- `settings/map.lua` `EXP_RATE = 2.5` (EXP from combat) and `settings/main.lua` `EXP_RATE = 2.500` (EXP from scripts/quests). Both are git-ignored. Restarted `xi_map` only (~43 s).
- Side effect: `charutils.cpp` also multiplies capacity points by `map.EXP_RATE` (in addition to `CAPACITY_RATE`), so capacity points are 2.5x too.
- Also raised to 2.500 in `settings/main.lua` (same day, second restart of `xi_map`): `BOOK_EXP_RATE` (FoV/GoV pages) and `ROE_EXP_RATE` (Records of Eminence).
- Left at 1.0 on purpose: `CAPACITY_RATE`, `EXP_LOSS_RATE`, `TABS_RATE`, `SPARKS_RATE`, `BAYLD_RATE`, `GIL_RATE`.
- Verified in the settings files and by restarting the map server cleanly; not yet verified by killing a mob in-game. First check: kill a mob at a known level and compare EXP against the retail value x 2.5.

## 2026-09-21 — Drops 2.0x, DB backup, `!buff` command

- **Drops:** `settings/map.lua` `DROP_RATE_MULTIPLIER = 2.0` and `MOB_GIL_MULTIPLIER = 2.0` (git-ignored). `ALL_MOBS_GIL_BONUS` left at 0.
- **Backup:** first DB dump, `sql/backups/mbetam_xi-20260921-182232.sql` (9.9 MB, `mysqldump --hex-blob --add-drop-trigger`, same as dbtool; that folder is git-ignored).
  It contains account password hashes, so never commit or share it.
- **`!buff`** (`modules/custom/commands/buff.lua`, listed in `modules/init.txt` as `custom/commands/`; test: `scripts/tests/modules/buff_command.lua`, 6/6 pass):
  available to every player (`permission = 0`), lasts 3600 s, re-running restarts the timer and never stacks. Constants are at the top of the file.
  | Effect | How it is done |
  |---|---|
  | EXP +200% | `xi.effect.DEDICATION`, `power = 200`, `subPower = 99999999`. Dedication pays its bonus out of `subPower` and ends when it is empty, so the pool is huge. |
  | Regen +50 | `xi.effect.REGEN` power 50 (HP per 3 s tick). |
  | Refresh +50 | `xi.effect.REFRESH` power 50 (MP per 3 s tick). |
  | Regain +50 | `xi.effect.REGAIN` **power 5**: `scripts/effects/regain.lua` multiplies power by 10 to get the REGAIN mod, and the mod is TP gained per tick (`status_effect_container.cpp`). |
  - **EXP math:** kill EXP is `base x (1 + bonus%)` in `xi.experiencePoints.calculate`, and the server's `map.EXP_RATE` (2.5) is applied afterwards in C++.
    So the buff is x3 before the rate and about x7.5 in total. If "200%" was meant as x2 (a +100% bonus), change `expPercent` to 100.
  - Dedication does not pay out in Abyssea (`regionId == ABYSSEA` check in `experience_points.lua`).
  - `modules/init.txt` is tracked but its own header says to `git update-index --assume-unchanged` it; we commit our one added line instead, because the module never loads without it.
- **Git:** commit `61413db` (CLAUDE.md + NOTES.md). No git identity is configured on this VM; commits pass `-c user.name -c user.email` (Eric / ericelizondo99@gmail.com) so nothing is written to git config.
  `scripts/tests/systems/charutils.lua` is still untracked on purpose.

## 2026-09-21 — Pushing to the fork (deploy key)

- The VM has no GitHub login, and dbtool-style `!` commands have no TTY, so HTTPS pushes fail (`could not read Username`). Pushing uses a **repo-scoped deploy key with write access**.
- Key: `~/.ssh/mbetam_server_deploy` (ed25519, no passphrase, mode 600). Alias in `~/.ssh/config`: `Host github.com-server` (`IdentitiesOnly yes`).
  `origin` = `git@github.com-server:Mbetam/server.git`; `upstream` = `https://github.com/LandSandBoat/server.git` (fetch only).
- GitHub's host key was pinned in `~/.ssh/known_hosts` after checking it against the fingerprint published at `https://api.github.com/meta` (ED25519 `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`).
- Test: `ssh -T git@github.com-server` should print `Hi Mbetam/server! You've successfully authenticated`. Revoke: delete the key under the fork's Settings -> Deploy keys.
- First push: `custom` -> `origin/custom` at `626ff0f`. `base` on the fork still equals upstream `base` (`4ce94020bf`).
- To pull upstream later: `git fetch upstream && git merge upstream/base` on `custom`, then rebuild and `python3 tools/dbtool.py update`.

## 2026-09-21 — Tier 3 test baseline (full `xi_test`)

**Command:** `./xi_test --keep-going --output <report>.ctrf.json` (servers stopped first; ~11 min on 16 cores). Report + log kept outside the repo in `~/lsb-test-reports/`
(`baseline-2026-09-21.ctrf.json`, 3.6 MB; `.log`). Pre-run DB backup: `sql/backups/mbetam_xi-20260921-185818-pre-baseline.sql`. The run left the DB untouched (1 char, 1 account).

**Result: 915 tests, 911 passed, 4 failed.**

| Area | Passed | Failed |
|---|---|---|
| systems | 643 | 1 |
| missions | 96 | 0 |
| packets | 67 | 1 |
| framework | 53 | 0 |
| jobs (cor dnc geo mnk pup run smn thf war only) | 22 | 2 |
| modules | 19 | 0 |
| quests | 11 | 0 |

**Coverage caveat:** upstream only tests what it has written tests for. NPC scripts, most quests, mob scripts, drops, zone behaviour and every client-side thing are untested here.
"911 pass" does not mean those work; the Tier 3 playthrough and LSB's "What Works" table cover the rest.

**The 4 failures, and what an A/B rerun showed** (same test subset run twice: once with my `settings/main.lua`+`map.lua`, once with the shipped defaults):

| Test | Verdict |
|---|---|
| `jobs::thf::traits::Gilfinder::drops GIL_MIN <> GIL_MAX without Gilfinder` | **Caused by my settings.** Fails with mine, passes with defaults. Test pins a mob to exactly 12000 gil; `MOB_GIL_MULTIPLIER = 2.0` changes that. (Not bisected to the single setting.) |
| `jobs::thf::traits::Treasure Hunter::increases drop rates #long` | **Caused by my settings.** Expected 18.00%, observed 29.45%; passes with defaults. `DROP_RATE_MULTIPLIER = 2.0`. |
| `packets::s2c::0x028_battle2::...Summoner #smn::Garuda Predator Claws sequence` | **Not my settings, cause unknown.** Failed in the full run, but passed in the subset run with BOTH my settings and defaults. Looks order/state dependent or flaky. Not proven. |
| `systems::combat::Ranged Attack Free Phase Delay::cannot perform another ranged attack inside of free phase window` | Same as above: failed once in the full run, passed in both subset runs. |

Also seen: `packets::s2c::0x028_battle2::...Weaponskills #ws::Out of range` passes in the full run but FAILS when only its subset is run (with mine and with defaults) —
direct evidence that some upstream tests depend on test order/state, which fits the two unexplained failures.

**No evidence in this baseline that a real game system is broken.** Two failures are my tuning; two are unexplained and look order-dependent.

**Open follow-ups:**
- Rerun the full suite with default settings (~11 min, servers down) to see whether Garuda/ranged still fail without my tuning, and rerun once with mine to see if they reproduce (flaky vs deterministic).
- Optional: make the Gilfinder and Treasure Hunter tests pin their own settings with `xi.test.world:setSetting('map.MOB_GIL_MULTIPLIER', 1)` / `'map.DROP_RATE_MULTIPLIER'` (as `death_exp_loss.lua` already does), so the suite stays green under custom rates.
- Tooling note: the A/B swap used a script-level `trap` to restore my settings; settings backup was deleted afterwards. Always confirm `grep DROP_RATE_MULTIPLIER settings/map.lua` shows 2.0 after any A/B.

## 2026-09-21 — QoL commands: `!home`, `!tele`, `!telelist`, `!shop`

Modules under `modules/custom/commands/` (loaded by the existing `custom/commands/` line in `modules/init.txt`), shared checks in `modules/custom/lua/qol_common.lua` (a helper, not a module; only loaded by `require`).
Tests: `scripts/tests/modules/qol_commands.lua` (21 tests, all pass; the whole `modules/` folder is 40/40). All four are `permission = 0` (every player). No core scripts or C++ were touched.

| Command | What it does |
|---|---|
| `!home` | `player:warp()`: same as being warped to the home point. |
| `!tele set <name>` / `!tele <name>` / `!tele del <name>` | Player-set teleport points. Max 10, names are letters+digits, <= 12 chars, case-insensitive, `set`/`del` reserved. Overwriting a name never counts against the limit. |
| `!telelist` | Lists points alphabetically with zone and x/z. |
| `!shop` | Opens a general-supplies shop anywhere via `xi.shop.general`. Stock is a table at the top of `shop.lua` (potions, ethers, remedy, antidote, echo drops, pickaxe/hatchet/sickle, arrows, bullets, shuriken); prices are the ones existing NPC vendors in this repo use. |

**Blocked when:** KO'd, in an event, engaged in battle, or inside a battlefield/instance (`qol.blockedReason`). `!tele set` also refuses in a Mog House (`player:inMogHouse()`), since the coordinates there are meaningless in the city zone.

**Storage (no new tables):** a point is five char vars `tele_<name>_<zone|x|y|z|rot>`. Gotchas that shaped this:
- Char vars are integers, so coordinates are stored x100.
- `setCharVar(name, 0)` DELETES the row (`PersistCharVar`), and x, z and rotation are often exactly 0. Every field is therefore shifted by +100000000 so a stored value is never 0. A field reading 0 means deleted/missing, and incomplete points are ignored.
- `getCharVarsWithPrefix('tele_')` is how points are found; the name lives in the var name (varname is 64 chars).

**Test quality check:** two deliberate breaks (offset set to 0; KO check removed) made 6 and 3 tests fail respectively, so the assertions do bite. Files restored byte-identical afterwards.
Test-writing notes: chat text is read from 0x017 packets at byte 23 (same as `test_npcs_in_gm_home.lua`); the shop path is exercised end to end with `player.actions:shopBuy`.

**`!ah` findings (NOT built):**
- `scripts/commands/ah.lua` already exists upstream as a GM-only (`permission = 1`) command that calls `player:sendMenu(xi.menuType.AUCTION)`; GM 4 characters (Tester) can already use it.
- The AH packet handler (`src/map/packets/c2s/0x04e_auc.cpp:32`) requires `hasZoneMiscFlag(ZoneMisc::AuctionHouse)`, so the server only lets AH actions happen in zones flagged for it: 21 city zones, authored in `data/zones/*/zone.yaml` (`misc: [..., auction_house, ...]`) and compiled at build time. A module or SQL cannot change that.
- Options: (A) leave the GM `!ah` as is (works in the 21 AH zones); (B) remove the zone check in that one C++ line (small core diff + rebuild; note it in the commit); (C) add `auction_house` to the misc list of every zone yaml (300 files, painful upstream merges). Not yet known whether the client itself opens the AH window outside a city; a quick test is `!ah` as Tester in a field zone.
- Also existing: `!homepoint` (GM, sends a target to their home point), unrelated to `!home`.

**Not verified:** anything client-side (the shop window, the chat text, how a teleport looks). Tests exercise the server side only.

## 2026-09-21 — Going public for a friend to test

- Pre-public DB backup: `sql/backups/mbetam_xi-20260921-193754-pre-public.sql`.
- **The public IP is deliberately NOT recorded in any file** (this file is pushed to GitHub). To see what zone IPs are currently handed out:
  `SELECT zoneip, COUNT(*) FROM zone_settings GROUP BY zoneip;`
- Router forwards (done by Eric, to the VM at `192.168.0.104`): TCP 54001, 54002, 54230, 54231 and UDP 54230. Port 22 must NOT be forwarded. The VM address should be a DHCP reservation.
- Switched every `zone_settings.zoneip` to the current public IPv4 (fetched from api.ipify.org at switch time), then restarted all four servers. All up, no erro/crit.
  xi_connect hands one zone address to every client, so **LAN clients also get the public IP**. If the router lacks NAT loopback/hairpin, a client on the LAN cannot enter the world while it is set.
  An inside-the-LAN TCP test to the public IP failed on all four ports both before and after the forwards were made, so hairpin is probably not supported (not proven; the friend's outside test is the real proof).
- **Switch back to LAN-only** (to play from the LAN when the router has no loopback), then restart `xi_map` (or all four):
  `UPDATE zone_settings SET zoneip = '192.168.0.104';`   Switch to public again: the same statement with the public IP.
- **If the home IP changes** (ISP dynamic address) the friend can no longer enter the world: update `zoneip` to the new public IP and restart.
- UDP 54230 (map) cannot be tested from inside; only a real outside login proves it.
- `settings/login.lua`: `ACCOUNT_CREATION = true` (anyone who finds the address can register). Plan: set it to `false` and restart `xi_connect` once the friend has an account. `LOGIN_LIMIT = 0`, `LOG_USER_IP = false`.
- Docs indicate the login connection uses SSL (an old xiloader fails with "wrong version number (SSL routines)"), so passwords are not sent in clear, but the friend was still told to use a unique password.
- Only game ports are on 0.0.0.0. MariaDB (3306) and xi_world (54003) are bound to 127.0.0.1. SSH (22) listens on all interfaces, so the firewall should limit it to the LAN.

### VM firewall (ufw) — needs sudo, run by Eric (was `ENABLED=no`)
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow from 192.168.0.0/24 to any port 22 proto tcp comment 'SSH from LAN only'
    sudo ufw allow 54001/tcp comment 'FFXI login'
    sudo ufw allow 54002/tcp comment 'FFXI search'
    sudo ufw allow 54230/tcp comment 'FFXI data'
    sudo ufw allow 54231/tcp comment 'FFXI view'
    sudo ufw allow 54230/udp comment 'FFXI map'
    sudo ufw enable
    sudo ufw status verbose
The SSH rule MUST come before `enable`. Recovery if locked out: from the VM console run `sudo ufw disable`.

### `--hairpin` (xiloader) — how to play from the LAN while zone IPs are public
Read from the xiloader source (`src/main.cpp`, LandSandBoat/xiloader): `--hairpin` is documented as "use this if connecting to a local server which you have exposed publicly".
It hooks `FFXiMain.dll` (found by byte pattern) so the map/zone address the client uses is replaced with the address given to `--server`.
- Eric's PC (LAN): `xiloader.exe --server 192.168.0.104 --hairpin` (Ashita: same text in the `command =` line of the boot `.ini`). No DB change needed.
- Remote testers: `xiloader.exe --server <public ip>` and NO `--hairpin`.
- If it prints `Failed to locate main hairpin hack address!`, the client build no longer matches the pattern; fall back to `UPDATE zone_settings SET zoneip = '192.168.0.104'` while playing locally.
- Not tested by me (no Windows client on this VM).
- Firewall: `/etc/ufw/ufw.conf` shows `ENABLED=yes` (Eric turned it on). The rule list itself needs sudo to read (`sudo ufw status verbose`).

## 2026-09-21 — Movement speed +50% (on foot and mounted)

Settings only, no code (`settings/map.lua`, git-ignored): `BASE_SPEED 50 -> 75`, `SPEED_LIMIT 80 -> 120`, `MOUNT_SPEED 80 -> 120`. `ANIMATION_SPEED_DIVISOR` left at 1.0.
- Run and walk are one number in this engine: final speed = `BASE_SPEED` + gear/song mods, then clamped to `SPEED_LIMIT` (`CBattleEntity::UpdateSpeed`, `battle_entity.cpp`).
  **Raising only `BASE_SPEED` would have been wrong:** the cap of 80 would swallow almost every bonus (75 + 10 = 85 -> 80). The cap scales by the same 1.5x (80 -> 120) to keep the same headroom.
- Mounts: output is `MOUNT_SPEED / 2` (so 80 -> 40, 120 -> 60) and is NOT limited by `SPEED_LIMIT`.
- Animation speed is derived from `baseSpeed / ANIMATION_SPEED_DIVISOR` (`base_entity.cpp:65`), so the run animation speeds up on its own; no separate change needed.
- `BASE_SPEED` is the default `baseSpeed` of any base entity. Mobs and NPCs override it from their DB rows, so only players change; mobs are NOT faster. Engaged mobs still chase at `MOB_RUN_SPEED_MULTIPLIER` (2.5x their own speed).
- The position-packet handler (`0x015_pos.cpp`) does not compare movement to speed, so there is no server-side rubber-banding. The GM `!speed` command already sets up to 255, so the client copes with values above 80.
- Verified with a throwaway `xi_test` against the real settings (5/5, file deleted afterwards): 75 on foot; base 75 + 10 = 85 (past the old cap); +100 caps at 120; `animation = CHOCOBO` -> 60.
- **Not verified:** how it feels or looks in the real client (animation smoothness, zone-edge behaviour, event/cutscene movement). Rollback = set the three values back to 50 / 80 / 80 and restart `xi_map`.
- Only takes effect after a restart and re-login (settings are read at startup / entity creation).

## 2026-09-21 — Starter kit (maps, outposts, 100k gil, survival guides) + a `!buff` bug I caused

**How to give an EXISTING online character the kit (no new character, no DB edits):** as a GM in game chat:
`!addallmaps <name>`, `!addallwarps <name>` (all Survival Guides AND all Home Points), `!givegil 100000 <name>` (adds; `!setgil` only sets the caller's own gil).
Never edit `chars`/`char_jobs`/... rows while the character is online: the running map server overwrites them on its next save (this already bit us once with `genkai`).

**New characters:** `settings/main.lua` `START_GIL = 100000` (was 10), `ALL_MAPS = 1` (was 0), `UNLOCK_OUTPOST_WARPS = 2` (was 0; 2 = all outposts incl. Tu'Lia and Tavnazia).
`START_GIL`/`ALL_MAPS` are applied once, in `xi.player.charCreate` (`scripts/globals/player.lua`); START_GIL is a top-up (only if below the value), so it never lowers anyone's gil.
`UNLOCK_OUTPOST_WARPS` is read live every time an outpost is used (`conquest.lua` `hasOutpost` / `getAllowedTeleports`), so it covers existing characters too.
Nothing covers Survival Guides, so `modules/custom/lua/starter_survival_guides.lua` overrides `xi.player.charCreate` and registers all 32x3 guides (the loop from `addallwarps.lua`, without its Home Points).
Tests: `scripts/tests/modules/starter_kit.lua`.

**Bug: `!buff` broke effect saving.** `char_effects.subpower` is a SIGNED smallint (max 32767) but `!buff` set Dedication's pool to 99,999,999. Every autosave of a player holding the buff failed:
`Out of range value for column 'subpower'` then `Transaction failed, rolling back` (critical), about every 20-30 s, until the buff ended. Effects could not persist; nothing permanent was lost.
Fix: pool = 32000 (`modules/custom/lua/buff_config.lua`, shared by `buff.lua` and the top-up), and `modules/custom/lua/buff_pool.lua` overrides `xi.experiencePoints.calculate` to refill the pool after every kill, so it never runs dry.
New tests in `buff_command.lua`: the pool must be <= 32767, and it must be full again after 5 kills.
Lesson: check the column type before choosing a "big" value for anything that is saved to the DB.

**File watcher (important):** the live map server hot-reloads `scripts/`, `modules/` and `settings/` on save. The `!buff` fix and the new settings went live the moment they were saved (log: `RE-RUNNING MODULE FILE modules/custom/commands/buff.lua`, `RELOADING ALL LUA SETTINGS FILES`).
Not applied by the watcher: the two NEW module files (`buff_pool.lua`, `starter_survival_guides.lua`); Module overrides need a restart. Saving a test file under `scripts/tests/` logs a harmless `describe` load error.
Anyone who used the OLD `!buff` still holds the big pool in memory until it ends or they run `!buff` again (the reloaded command replaces it with the safe pool), or the server restarts.

## 2026-09-21 — `!buff` now lasts 10 hours

`modules/custom/lua/buff_config.lua` `duration = 36000` (was 3600). The chat message now reads "Buff active for 10 hours" (`%g` of `duration / 3600`).
`buff.lua` also clears its cached copy of the config (`package.loaded[...] = nil`) before requiring it, so re-running the file (the file watcher does that on save) picks up an edited config; without it a changed number would only apply after a restart.
- Live immediately (file watcher: `RE-RUNNING MODULE FILE` for `buff.lua` and `buff_config.lua`, no errors). Effects cast BEFORE the change keep their old 1-hour timer until they end or `!buff` is used again.
- Verified offline, not with `xi_test`: `xi_test` embeds its own world server (own ZMQ IPC) and must not run next to the live `xi_world`. The change was built in a scratch folder, syntax-checked and run against a fake player with `lupa` (Lua 5.1, installed in `~/lsb-venv`): all four effects 36000 s, pool 32000, message "10 hours".
  The real test (`scripts/tests/modules/buff_command.lua`, now "lasts ten hours") still has to be run in the next restart window, together with `starter_kit.lua` and the pool tests.
- `char_effects.duration` is an unsigned int, so 10 hours fits whether it is stored in seconds or milliseconds.
- Player-facing text that says "1 hour" and needs updating: the Discord changelog draft, and the message already sent to the friend.
