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

## 2026-09-21 — Augment system, Phase 1 (config + logic + tests; nothing player-visible yet)

**Design (approved by Eric, "go with your defaults", then "everything looks good" for the numbers):** retail stats stay retail, custom augments are the progression.
4 augment slots per item (engine allows 5), one NPC "Augmenter" in Lower Jeuno (+ GM Home for testing), gil-only prices, 4 tiers unlocked by MAIN job level (1 / 30 / 60 / 90),
removal costs gil per slot, only gear with no augments (or augments this system made) is accepted, a stat can be added once per item.
Prices per augment: 10,000 / 50,000 / 250,000 / 1,000,000 gil. Removal: 5,000 x tier. 16 stats (Dual/Double/Triple Attack, crit rate, Store TP, gear Haste, Fast Cast, Acc/Atk/MAcc/MAB, HP, MP, Refresh, Regen, Cure Potency).
The exact stat table lives in `modules/custom/lua/augment_config.lua`; the draft player-facing how-to is in the chat history (not posted; the NPC does not exist yet).

**How the engine handles augments (verified in the code):**
- Exdata for augmented gear: kind, subkind, up to 5 augments of { id (11 bits), value (5 bits, 0-31) }, plus a 12-byte signature (`src/map/items/exdata/augment_standard.h`).
- Bonus = `(base + storedValue) x max(multiplier, 1)` from the `augments` SQL table (`item_equipment.cpp` `SetAugmentMod`). The table has 2,223 rows for ids 1-2047 and covers 319 distinct stats.
- The client draws augment text from its own data by id, so ONLY retail ids can be used. Do not invent ids.
- HP and MP need one id per 32 points (ids 1-4 and 9-12, bases 1/33/65/97). Gear Haste is stored in hundredths of a percent (multiplier 100) and the engine caps total Haste at 25%; Fast Cast is clamped at 50 and Cure Potency at 50%.
  No cap was found in the code for Dual Wield, Triple Attack, Store TP, crit rate, Regen or Refresh (search may have missed one). Augments stack across ALL worn gear, so worst case is large; the once-per-stat-per-item rule and small values are the safeguard.
- `item:getAugment(slot)` returns `{ id, value }` (slot 0-4); `item:getExData()` returns `{ augmentKind, augmentSubKind, augments = { {id,value} x5 }, signature }`; `player:addItem({ id, exdata = { augmentKind, augmentSubKind, augments } })` writes it. GM `!giveitem <player> <itemId> <amount> <aug1> <v1> ...` already does this (up to 4).

**Design wrinkle:** for Triple Attack, gear Haste and Refresh the amounts are `1,1,2,2`, so Tier 2 gives the same bonus as Tier 1. `core.effectiveTier` therefore charges/unlocks the LOWER tier for an identical bonus, and removal uses that lower tier too
(a stored augment cannot record which tier it was bought at). The Discord post should say "if a tier gives the same bonus as the one before, you pay the lower price".

**Files (all in git, none active in the game yet):**
`modules/custom/lua/augment_config.lua` (numbers), `modules/custom/lua/augment_core.lua` (pure rules: tiers, encode/decode, checkAdd/checkRemove, buildExdata, readItem),
`scripts/tests/modules/augment_core.lua` (41 pure tests, incl. a check of every catalog id against `sql/augments.sql`), `scripts/tests/modules/augment_engine.lua` (real-engine checks: equips an augmented Copper Ring for all 64 stat/tier combinations and compares the mod change).
Verified offline with `lupa` (Lua 5.1 in `~/lsb-venv`): 41/41 pass, and 8 deliberate breaks were all caught (an earlier run MISSED a wrong HP base because the catalog only checked itself, which is why the `sql/augments.sql` truth check exists).
**Not yet run:** `augment_engine.lua` needs the real engine, i.e. `xi_test` with the servers stopped. Run it at the next restart window, together with `./xi_test --file 'modules/'`.

**Next:** Phase 2 = the Augmenter NPC (trade gear in, `customMenu` to pick slot/stat/tier, confirm price, swap the item), exact position next to the Lower Jeuno Auction House. Phase 0 (client display check via `!giveitem`) is still waiting on Eric.

## 2026-09-21 — Augment system, Phase 2 (the Augmenter NPC) — written and tested offline, NOT live until the next restart

**What it is:** an NPC named "Augmenter" (model 50, the Auction Counter clerk model, so it certainly exists in the client) inserted into Lower Jeuno and GM Home by `modules/custom/lua/augmenter_npc.lua` (listed in `modules/init.txt`).
Module files and overrides are not applied by the file watcher, so it appears after the next `xi_map` restart. Positions are in the `placements` table at the top of that file; **the Lower Jeuno spot (-13.0, -0.1, -31.0) is a first guess** beside the four Auction Counters
(which run from (-16.1, -32.0) to (-8.7, -19.0)); stand where it should be, read coordinates with `!pos`, and edit the table.

**How a player uses it:** trade ONE weapon/armor (unequipped) -> menus (Add an augment / Remove an augment / Never mind) -> stat (6 per page, 16 stats) -> bonus with price -> confirm -> the item is swapped.
Logic lives in `modules/custom/lua/augmenter_flow.lua`; the rules and numbers in `augment_core.lua` / `augment_config.lua` (Phase 1).

**Engine facts that shaped it (from the C++):**
- `customMenu` matches a click to an option by its EXACT LABEL TEXT (`HandleCustomMenu`), so labels in one menu must be unique, and every click ends that menu, so each step opens a new one (sent 50 ms later with `player:timer`, the pattern in `test_npcs_in_gm_home.lua`).
- Menu callbacks only receive the player, so the conversation (item id/slot, augment list) is kept in a per-player table in `augmenter_flow.lua` (cleared on finish or cancel).
- The trade is NOT completed with `confirmTrade`: the item stays in the bag while the player chooses. On confirm the item is re-fetched with `getStorageItem(container, slot, 255)` and re-read; if it moved or changed the NPC refuses and charges nothing.
- The swap order is undoable at every step: take gil -> add the new item (needs 1 free slot) -> take the old item; if a later step fails the earlier ones are reversed (gil refunded, the copy removed).
- If a bonus is identical at two tiers (Triple Attack, gear Haste, Refresh are 1,1,2,2) the menu lists it once at the lower tier's price.

**Tests:** `scripts/tests/modules/augmenter_flow.lua` (33 tests with a stand-in player/item/trade: what is accepted, the menus, paging, tiers, adding, removing, and the failure paths) — 33/33 pass offline (`lupa`), and 10 deliberate breaks (no re-check, no refund, copy not removed, no free-slot check,
duplicate bonuses, locked tiers offered, gil in the trade accepted, cancel not clearing, already-owned stat offered, ...) were all caught. `scripts/tests/modules/augmenter_engine.lua` (real NPC, real `tradeNpc`, real items/gil/mods) is written and syntax-checked but **NOT RUN**: it needs `xi_test` with the servers stopped.
The two Augment engine files (`augment_engine.lua`, `augmenter_engine.lua`) plus `./xi_test --file 'modules/'` are the checklist for the next restart window.

**Unknowns only the game can answer:** does the client show the augment text on the returned item (Phase 0: `!giveitem <name> 16480 1 146 2`); does the GM-prompt style menu still open right after a trade (it is cancelled if the player is "in an event"); is the NPC standing somewhere reachable.
If the menu does not open after a trade, the fallback is to open it from `onTrigger` instead (talk to the NPC after trading).

## 2026-09-21 22:0x — Restart window: augment system verified in the REAL engine, servers restarted, `!city` added

**Result: `./xi_test --file 'modules/'` = 155 passed, 0 failed** (with the servers stopped; exit 0). This includes `augment_engine.lua` (9: every one of the 16 stats at all 4 tiers changes the right mod by exactly the promised amount, plus reading/adding/removing on real items)
and `augmenter_engine.lua` (13: the real Augmenter NPC in GM Home and Lower Jeuno, a real `tradeNpc`, real gil, real swaps, refusals, and a click-through of the whole menu conversation). Servers restarted 22:22; `augmenter_npc` and `!city` loaded, no errors. Registration is closed (`xi_connect` was restarted by the watcher at 22:04 with `ACCOUNT_CREATION = false`).

**Things the engine taught us (all found by the tests, none by reading):**
1. **Fishable items cannot be augmented.** `Exdata::getType` (`src/map/items/exdata.cpp`) checks `fishingutils::IsFish` BEFORE "is equipment". Copper Ring is fishing junk, so it gets fish exdata (`isRanked/size/weight`) and augment data is silently ignored.
   The item reader refuses such items ("carries other data"), which is the safe outcome. Tests use the Ascetic's Ring (13440: level 1, all jobs, not Rare/Ex, not fishable). Worth a line in the player how-to: some fishing-junk gear cannot be augmented.
2. **Upstream engine bug: a process that exits with a custom menu still open segfaults.** `customMenuContext` (`luautils.cpp`) is a global `HashMap<uint32, sol::table>`; its destructor runs after the Lua state is closed, so `luaL_unref` crashes in `exit()`.
   It hit `xi_test` (it also cut off the terminal summary, which looked like a crash inside an unrelated shop test). Fix on our side: `flow.setMenuSender(fn)` lets tests capture menus instead of opening real ones. For a live `xi_map` the same crash can only happen at SHUTDOWN if a player was left with a menu open; data is already saved by then.
3. **A fresh character zoning into a city is put in an arrival event**, and so is entering a Mog House; `qol.blockedReason` correctly refuses commands during an event. Tests call `player:release()` first. Real players past the intro cutscene are not affected.
4. `xi_test` cannot run next to the live servers (its own embedded world server / IPC) and `TestChar::clean` only deletes ids >= 20,000,000, so it never touches real characters. The results file (`--output`) survives even when the process dies at exit.
5. Item creation with `player:addItem({ id, exdata = { augmentKind, augmentSubKind, augments } })` DOES apply the augment mods when the item is equipped (`item:getMod(DUAL_WIELD)` was 3 for Dual Wield +3), so no reload is needed.

**`!city`** (`modules/custom/commands/city.lua`, permission 0, same safeguards as `!home`): `!city sandoria|bastok|windurst|jeuno` (aliases: sandy/san/sd, bas, windy/win, jue). Arrives at Home Point #1 of the nation's main zone:
Southern San d'Oria (-85.468, 1.0, -66.454), Bastok Markets (-344.0, -10.0, -155.0, rot 160), Windurst Woods (9.088, -2.5, -0.383, rot 244), Lower Jeuno (-98.588, 0.0, -183.416, rot 167). Free, no cooldown. A test compares the coordinates with `data/zones/<zone>/npcs.yaml`.
Tests: `city_command.lua` (7, pure) and `city_engine.lua` (7, real teleports incl. from a Mog House).

**Still unverified (needs the real client):** does the menu open after a trade and does the client show the augment text (Phase 0: `!giveitem <name> 13440 1 146 2` — note the ring is now 13440, not the Thief's Knife); is the Lower Jeuno Augmenter spot (-13.0, -0.1, -31.0) reachable/sensible (use `!pos` and edit `augmenter_npc.lua`).

## 2026-09-21 22:4x — Every mob drops at least 500 gil; Augmenter moved; roadmap updated; servers restarted 22:46

**Ask:** "gil feels a little low, make every mob drop gil, base drop 500."
**Why not a setting:** `ALL_MOBS_GIL_BONUS` is PER MOB LEVEL (`bonus = setting x mob level`, clamped to `MAX_GIL_BONUS`, and the setting is a single byte, max 255), so it cannot give a flat 500.
**How the engine decides (verified in `charutils.cpp` `DistributeGil` and `mob_entity.cpp` `DistributeRewards`):** on a kill the game first calls `xi.mob.onMobDeathEx` (once per alliance member) and only THEN decides on gil. A mob rolls gil from its `GIL_MIN`/`GIL_MAX` mob mods
(both set and max > min: random in range; max <= min: exactly min; otherwise a level formula); `CanDropGil()` is false for a mob with neither mod nor `GIL_BONUS`; a NEGATIVE `GIL_MAX` means "never drops gil" (Dynamis/Limbus). `MOB_GIL_MULTIPLIER` is applied to the roll AFTERWARDS.
The total is split evenly between party members within 100 yalms (`gil / members`), so 500 in a party of 6 is 83 each.

**What was built (modules only, no core change):** `modules/custom/lua/mob_gil.lua` (rules + the number: `baseGil = 500`) and `modules/custom/lua/mob_gil_floor.lua` (a Module overriding `xi.mob.onMobDeathEx` to call it), listed in `modules/init.txt`.
The floor is stored as `ceil(500 / MOB_GIL_MULTIPLIER)` (250 with the current x2) so players receive at least 500 whatever the multiplier is. Rules: a mob with no gil gets exactly the floor; a smaller drop is raised to it; a bigger natural drop is NEVER lowered;
mobs with a negative `GIL_MAX` are left alone; mobs that use the level formula plus a `GIL_BONUS` are left alone (a fixed floor could lower a special mob's drop); a range one wide (which the game treats as a mistake) is made exact.
**Tuning:** change `mobGil.baseGil` in `mob_gil.lua`; it is picked up by the file watcher for the helper, but the module itself needs a restart only if it was never loaded.
**Economy notes for Eric:** every kill of every mob now pays at least 500 gil, including trivial low-level mobs and battlefield mobs (the gil decision is outside the battlefield check that gates EXP). That makes fast-respawning low-level mobs a gil farm; T1 augments (10,000) cost 20 kills and T4 (1,000,000) about 2,000.
**Tests:** `scripts/tests/modules/mob_gil.lua` (11 pure, incl. a break where the floor is not divided by the multiplier, one where a bigger drop is lowered, and one where never-drops-gil mobs are raised: all 8 deliberate breaks caught; the first run MISSED a "range of one" case because my test never produced one, then fixed)
and `scripts/tests/modules/mob_gil_engine.lua` (6 real kills: exactly 500 for an ordinary mob, 10-20 raised to 500, 3,000 stays 6,000, never-drops-gil stays 0, still 500 with a x1 multiplier, 3 kills = 1,500). `./xi_test --file 'modules/'` = **172 passed, 0 failed**.

**Augmenter position (Lower Jeuno):** now (7.03, 0.0, 6.05, rotation 84), from Eric's `!pos` reading, in the middle of the zone about 8 yalms from the Moogle at (0, 1.5) and ~30 yalms from the nearest Auction Counter. It takes effect at the 22:46 restart.
**Roadmap** (`docs/custom/ROADMAP.md`) updated: `!city` and `!buff` (10 hours) under Done, the Augmenter under "Live, in testing".

## 2026-09-21 23:xx — Augmenter: stacking allowed, NPC is a Moogle (LIVE since the 23:23 restart; needed a core C++ fix, see below)

**Client check (Eric, real client): the Augmenter's menu opened after the trade and worked.** This confirms the customMenu-after-trade flow in a real client. (Still unconfirmed: the item text for the augment; the NPC was INVISIBLE.)
**Invisible NPC cause (my mistake):** I used model 50 because the Auction Counter clerks use it. Model 50 is the blank placeholder `*` in `docs/model_ids.txt`; the clerk is drawn by the map, not the entity. The game's own Moogle NPCs use model 82.
Fix: `augment_config.lua` `npcModel = 82`, read by `augmenter_npc.lua`. Tests compare it with the Moogle in `data/zones/lower_jeuno/npcs.yaml` and refuse a `*` model.
**Stacking:** replaced the once-per-stat rule with `augment_config.lua` `maxPerStat` (default 4 = the same augment can fill every slot; set 1 to restore the old rule). `core.countOf` counts copies; `checkAdd` refuses at the limit; the menu keeps offering a stat until it reaches the limit.
Every copy counts: two Dual Wield +2 augments give Dual Wield +4. This only became true after the core fix below.
**Balance to watch:** worst case per item at Tier 4 with four copies: Dual Wield +16, Double Attack +16%, Triple Attack +8%, crit +16%, Store TP +16, gear Haste +8% (capped at 25% overall), Fast Cast +16 (capped 50), Accuracy/Attack/Magic Acc +80, HP/MP +320, Regen +16/tick, Refresh +8/tick.
Across ~16 worn pieces these add up, and no engine cap was found for Dual Wield, Triple/Double Attack, crit, Store TP, Regen or Refresh (the search may have missed one). Lower `maxPerStat` if it gets out of hand.
Cost: four T4 copies on one item = 4,000,000 gil (about 8,000 kills at the 500 gil floor).
**ENGINE BUG FOUND (upstream LSB, not ours) and fixed in core C++:** the first real-engine run failed: four Dual Wield +2 augments on one ring gave +32 on the player instead of +8 (two copies +8 instead of +4, three +18 instead of +6: N squared). `item:getMod` was right (8); the player gain was wrong. Cause: `CBattleEntity::addEquipModifiers` (src/map/entities/battle_entity.cpp) loops over every entry in the item's modList and on each entry adds `GetScaledItemModifier(...)`, which already returns the item's TOTAL for that mod. An item with N entries of one mod therefore gave N x total. `delEquipModifiers` had the same loop, so nothing leaked, it only over-counted. It also affects any retail item that lists one mod twice (for example a base stat plus a matching augment).
Fix (small diff, both functions): skip an entry when an earlier entry on the same item has the same mod id, so each distinct mod is applied once. Rebuilt in 42 s (`cmake --build build`, incremental). After the fix 1, 2, 3, 4 copies give exactly 1x, 2x, 3x, 4x, and taking the ring off returns the mod to its old value.
Commit message must say why core C++ was touched. If upstream is merged later and fixes this itself, drop our change.
**Tests:** pure `augment_core.lua` 47/47 and `augmenter_flow.lua` 35/35 offline. Real engine with the servers stopped: `modules/` 185/185 (new tests: 1 to 4 copies each count once, taking the ring off removes the whole bonus, two real conversations stack Dual Wield +1 twice into +2). Full `xi_test`: 1079 pass, 2 fail; both are the known failures caused by our own drop-rate and gil multiplier settings (`drops GIL_MIN <> GIL_MAX without Gilfinder`, `increases drop rates`), not by this change. Servers restarted 23:23, all four up, no errors in the logs since.

## 2026-09-21 23:5x — `!status`: stats of the target, or yourself (LIVE after the 23:46 restart)

**What it does:** `!status` shows the stats of the current target, or your own when nothing is targeted. Works on players, monsters, pets and trusts; NPCs are refused (they have no stats, and the engine's `getEVA` casts without checking). Everyone can use it (`permission = 0`); to restrict it, change that one number in `modules/custom/commands/status.lua`.
- `!status`: name and kind, level/jobs, HP/MP/TP, the seven attributes (total, gear/effect part in brackets), offense (Acc, Ranged Acc/Atk, weapon damage, delay, M.Acc, M.Atk, Atk bonus), defense (Eva, Def bonus, M.Eva, M.Def), eight elemental M.Eva, every notable bonus that is not zero (Dual Wield, Double/Triple/Quad Attack, Crit, Store TP, gear Haste in %, Fast Cast, Regen, Refresh, damage taken...), speed, and for players item level, merits, zone.
- `!status mods [page]` (or `!status 2`): EVERY modifier that is not zero, by its enum name, raw values, 14 lines per page. This is where "all the stats" live (the game has 1,185 mods).
- `!status skills`, `!status effects`, `!status all`.
**Limits, on purpose:** the game gives Lua no finished Attack or Defense number, so they show as bonuses (the ATT/DEF mods and their percent). Everything else is the value the game uses in combat. Gear Haste is shown in whole percent in the summary but raw (hundredths of a percent) in `mods`.
**Files:** `modules/custom/commands/status.lua` (thin: picks the target, prints), `modules/custom/lua/status_report.lua` (all the logic: `report.run(entity, section, page)`).
**Found while testing:** players report Riding and Digging as 32767 (a flag, not a skill), so the skills list skips values of 32767. `setSkillLevel` takes tenths of a skill point (2000 = skill 200). In the test harness, `addStatusEffect` without `origin = player` segfaults `xi_test`; production code is not affected (the effect readers were tested separately and are fine).
**Tests:** `scripts/tests/modules/status_report.lua` (34, stand-in entity, also runs offline under lupa; 18 deliberate breaks all caught) and `status_engine.lua` (18: real player with a real augmented ring, a real Volcanic Bomb alive and dead, another player, the real Augmenter NPC, and that every line arrives as its own unchanged chat packet). Two real-engine deliberate breaks (attribute total, HP mixed with max HP) were caught after the tests were strengthened. `modules/` folder: 237/237 with the servers stopped.
**Not tested (needs a real client):** that `!status` with a monster TARGETED reads that monster. The harness cannot set a cursor target, so the tests call `report.run(mob)` directly; the command's own target choice is one line (`player:getCursorTarget() or player`, the same as `!getmod`).

## 2026-09-22 — Every monster drops gil, max skill-up rates, lottery NMs always pop (settings + 3 small core edits)

### Every monster drops gil (`modules/custom/lua/mob_gil.lua`, live after the restart)
The floor (500 gil) used to skip two kinds of mob. Now it covers them:
- **"Never drops gil" mobs (`GIL_MAX` negative).** Found in the scripts: every Dynamis mob (`scripts/globals/dynamis.lua`), Pirate's Chart mobs, one mob in each Promyvion (Dem, Holla, Mea), Splinterspine Grukjuk, Fodderchief Vokdek, the two Lebros Qiqirns, Orcish Overlord (in one phase), Bukki, Fafnir, Nidhogg, Duu Nazo, Diamond Quadav. A negative maximum is now treated as "no gil of its own" and replaced by the floor. **Consequence to watch:** Dynamis and other instanced content have very many mobs, each now worth 500 gil (about 150,000 for a 300-mob run). If that gets out of hand, exclude those zones in `mob_gil_floor.lua`.
- **Gil-bonus mobs (`GIL_BONUS` above zero; four ecosystems in `data/ecosystems.yaml`: 100, 120, 180, 1000).** They roll the level formula, raise it to `GIL_MIN`, THEN multiply by the bonus (`GetRandomGil`). So the minimum is stored divided by the bonus (`mobGil.minForBonus`), plus one point where the bonus divides the floor exactly, because the game's float multiplication can land just under a whole number and round down (0.08f is 0.0799999982). A mob with both a maximum and a bonus is left alone (a plain floor could lower it). Negative bonus (-100, "no gil") mobs already got the plain floor.
Never lowers a drop. Tests: 21 pure (9 deliberate breaks caught) and real-engine kills for negative-max, negative-max with a small/large minimum, and ten bonus values (8, 25, 29, 30, 50, 70, 100, 120, 180, 1000): all drop at least 500, the small ones exactly 500, and a bonus of 1000 is not lowered.

### Skill-ups at the maximum rate (settings + core edits)
- **Combat, magic, automaton:** the game clamps the base skill-up chance at 0.5 in C++ (`TrySkillUP` in `charutils.cpp`, the same in `puppetutils.cpp`). Core edit, 2 lines: the clamp now reads a new setting `SKILLUP_CHANCE_CAP` (default 0.5, so unchanged unless raised). Local settings: `SKILLUP_CHANCE_MULTIPLIER = 100` (makes the base chance exceed 1 at any skill) and `SKILLUP_CHANCE_CAP = 1.0`. Result: every eligible action (the monster level must still allow a gain, and the skill must be below its cap) is a skill-up. Skill-up food and similar bonuses multiply after the cap, so they can no longer matter.
- **Crafting:** `CRAFT_CHANCE_MULTIPLIER = 1000` (was 1.0). Every eligible synthesis raises the skill (still needs a recipe above your level and no break outside the game's window).
- **Fishing:** `FISHING_SKILL_MULTIPLIER = 100`. The roll is `random(90..120) < maxChance` and maxChance is at least 4 x the multiplier, so it always succeeds when the fish is in the eligible level window. **Not covered by a test** (needs a whole fishing session).
- **Digging:** the chance was hard-coded (`roll <= 15`) in `scripts/globals/hobbies/chocobo_digging/logic.lua`. Core script edit, 1 line: it now reads a new setting `DIG_SKILLUP_CHANCE` (default 15, falls back to 15 if the key is missing). Local `main.lua`: 100. A dig that finds an item raises Digging by 0.1; the rank cap (10.0 per rank) and the daily dig fatigue (100 finds a day, `DIG_FATIGUE`) are unchanged.
- **Not changed:** the AMOUNT per skill-up (`SKILLUP_AMOUNT_MULTIPLIER`, still 1). "Rate" was read as chance. Raising the amount is one more setting if wanted.
- Tests (`scripts/tests/modules/skill_up_rates.lua`, 11): melee and magic skills rise 200 of 200 times, also one point below the cap where the base chance is lowest; with the game's own 0.5 cap and multiplier 100 it rises about half the time (so the cap setting is what matters); with the game's own defaults a skill near its cap does not rise every time; skills never pass their cap; crafting 30 of 30 vs fewer with the default multiplier (tested at recipe level 13 vs skill 12.0, where the default chance is 42%; further below the recipe it is already over 100%); digging with chance 100 raises the skill exactly once per dig that found an item, with chance 0 never.
- Mind the test clock: `skipTime` moves the game's internal clock but NOT the wall clock (`GetSystemTime`) that cooldowns use. `skipVanaDays(1)` moves the wall clock by 57.6 minutes.

### Lottery NMs always pop, no timer (settings only)
`xi.mob.phOnDespawn` (`scripts/globals/mobs.lua`, used by ~375 placeholder scripts) already reads two settings. Local `main.lua`: `NM_LOTTERY_CHANCE = -1` (always 100%) and `NM_LOTTERY_COOLDOWN = 0` (no timer). Killing the placeholder now always brings out its NM at the placeholder's normal repop time (a few minutes; `params.immediate` scripts pop at once), and the NM can pop again right after it dies. Day-only / night-only NMs still wait for their time of day, and a placeholder cannot spawn a second NM while one is up. **Not covered (about 40 scripts with their own custom code):** weather NMs with 9 to 12 hour random timers (Kreutzet, Bayawak, Elel...), the Leshys (they grow over time), alternating pairs such as Argus / Leech King (50/50 between two NMs), Fafnir, Snow Maiden / Father Frost / Morozko, the Orcish Overlord line. Each would need its own change.
Tests (`nm_lottery.lua`, 4): Carrion Crow / Nunyenunc in West Sarutabaruta pops 8 times in a row with a wait of 57 minutes between (under the game's 1 hour cooldown); with the game's own 10% chance it does not pop every time; with the chance at always but the cooldown left at 1.0 it waits the hour and then pops. The zone keeps its state between tests, so the test puts the pair back before and after each test.

## 2026-09-22 — AH bot: built, dry-run tested, NOT turned on yet (needs a one-time SQL step)

Keeps the Auction House stocked with common materials, and buys out unsold player listings (gear
included) after a wait, per the design baseline ("Stocked AH with a bot that buys unwanted gear...").
Entirely outside the game engine: `tools/ah_bot/` is a standalone Python script run on a schedule
(systemd timer, examples included), not a Lua module. Why: the AH is just a database table
(`auction_house`), a "bot" is only an ordinary character id acting as seller or buyer, and when a real
player buys a bot listing the seller is paid automatically by an existing DB trigger
(`auction_house_buy` in `sql/triggers.sql`, delivers gil to the seller's mailbox) — none of that needs
new game-server code. Lua modules have no SQL access, so a periodic Lua job was not an option; the
standalone script also means testing and tuning it never needs a server restart.

**Owner decisions (asked before building):** pricing = BaseSell x multiplier everywhere; buyout
budget = unlimited; a listing is bought out once it has sat unsold for **1 hour**.

**Files:** `tools/ah_bot/config.py` (every tunable number, with why), `pricing.py` (pure price/eligibility
logic, no DB), `db.py` (reads `settings/network.lua` the same way `dbtool.py` does), `ah_bot.py` (the
two passes), `setup.sql` (one-time account/character creation), `test_pricing.py` (15 tests, offline),
`ah-bot.service.example` / `ah-bot.timer.example` (systemd, 15-minute cadence), `README.md`.

**Pricing:** BaseSell x 30. Most equipment has **no BaseSell at all** (0 for about 60% of AH-eligible
items — the retail client cannot sell gear to an NPC, so it was never given one), so equipment falls
back to its level x 10 x 30. An item with neither (mostly quest/key items, which are usually also
flagged un-auctionable anyway) is never stocked and never bought.

**Restocking is category-limited, and this was found the hard way:** the first version had no category
filter, and the first dry run immediately queued up Mog House furniture — a `royal_bed` at 561,000 gil,
a `millionaire_desk` at 735,000 gil — because furniture is a real, separate Auction House category
(`FURNISHINGS`, see `docs/Auction Categories.txt`) with its own BaseSell values, and nothing in my
first pass excluded it. Fixed with `RESTOCK_AH_CATEGORIES` in `config.py`: only Crystals, the seven
crafting-material categories, Medicines and the nine Food categories are proactively stocked. Buying
out PLAYER listings is not category-limited — a player can sell weapons, armor, furniture, anything
AH-eligible, to the bot; the category limit only stops the bot from inventing its own furniture
listings out of thin air.

**Buy-out never overpays:** it only buys a listing at or under its own computed price for that item; a
seller who asks for more than that is left listed for a real buyer, exactly as intended ("buys
unwanted gear at [reference] prices", not "buys anything at any price"). A full-stack listing is valued
at stackSize x the per-unit price, not the per-unit price alone (a stack of 99 crystals is worth 99x
one).

**Tested:** `test_pricing.py`, 15/15, offline, no database (7 deliberate breaks caught: base-sell
fallback dropped, equipment fallback dropped, negative base-sell accepted, restock allowed on
equipment, restock ignored its minimum, buyout allowed overpaying, buyout bought an unpriced item).
The real queries were dry-run against the live database (`python3 ah_bot.py`, no `--apply`, rolls back)
and the restock output now looks sane (leather, flour, spices, ore, ingots at reasonable prices) after
the category fix.

**NOT tested: writing to the database.** I could not run the one-time account setup
(`INSERT INTO accounts` / `INSERT INTO chars`) myself — the environment's own safety check refused it
as a live-database write. Nor has `--apply` (the actual INSERT/UPDATE path) been run for real. The SQL
in `ah_bot.py` and `setup.sql` has been reviewed carefully against the schema but is unverified in
practice. Before trusting this: run `mysql -u mbetam -p mbetam_xi < tools/ah_bot/setup.sql` yourself
(creates charid/accid 90000001, "AHBot" — reserved, documented, far above any real account id so it can
never collide with a real player), then `python3 ah_bot.py --apply` once by hand and check the AH in a
real client before turning on the timer.

**Reserved id 90000001:** real accounts are allocated sequentially from the current highest id (1001
today). This is far out of range on purpose. If account creation is ever reopened, new real accounts
just continue from 90000002 — harmless, a one-time permanent jump in the numbering, documented here so
nobody reuses 90000001 by hand later.

**Not covered / left for later:** the bot's own delivery-box mail (gil from real players buying its
stock) will accumulate forever since "AHBot" never logs in to collect it — harmless, but worth a
periodic sweep eventually. Bought-out player items are simply removed, not recycled into new stock.

## 2026-09-22 — AH bot: whole AH stocked (owner override), random draw order

Owner ran it by hand, saw only materials/food/crystals got listed, and said "I want the whole AH to be
stocked" - weapons and armor included. `RESTOCK_AH_CATEGORIES` is now `None` (every real category) by
default; the earlier materials-only list is still available by setting it back to a tuple.

Equipment is priced the same way as everything else (`price_for`: BaseSell if it has one, else
level x 10 x 30 - see the September 22 "AH bot" entry above), no logic change needed there, only the
category filter. Equipment gets its own restock target of **1** instead of 5 (`RESTOCK_EQUIPMENT_TARGET_QUANTITY`):
unlike a material, a weapon or armor piece is not used up by crafting, so 5 identical copies listed at
once would look strange. Equipment below level 10 is skipped (`RESTOCK_MIN_EQUIPMENT_LEVEL`) - not worth
a permanent AH slot.

**Found immediately when the category limit came off:** the very next dry run listed almost the same
40 items again - furniture, plus now some materials - because the query had no ORDER BY, and low
item ids (furniture is largely 2-107) always win a plain unordered SELECT. At 200 listings per run,
weapons and armor (much higher item ids) would never have been reached for a long time. Fixed with
`ORDER BY RAND()` in the restock query, so every run spreads across the whole catalog instead of
crawling it in id order. Confirmed in a dry run: the very next run's first 20 lines included weapons,
armor, rings and cards.

Verified with a dry run only (`test_pricing.py` still 15/15; the live `--apply` for this specific
change has not been run in this session - same limitation as before, see the entry above).

## 2026-09-22 — AH bot round 3: equipment quantity, stack listings, !ahprice command

Three requests after watching the first real runs.

**1. Equipment restock quantity 1 -> 3** (`RESTOCK_EQUIPMENT_TARGET_QUANTITY` in config.py). Existing
equipment listings already at 1 will top up to 3 on the next run automatically - no action needed.

**2. Stackable items (crystals, most ammo/materials - stackSize > 1) now restock as a full stack**
(`auction_house.stack = 1`, price = per-unit price x the stack size), the way these are normally sold,
instead of always as single units. Confirmed in a dry run: `jug_of_scarlet_sap x2 (stack of 12)`, etc.
**Known consequence:** an item that already reached its target as OLD single-unit listings (from before
this fix - mainly the first 40 materials from the very first run, crystals included, since `have` counts
every row regardless of mode and the item looks "fully stocked" already) will not convert to stacks on
its own; the bot only tops up when the count is below target. One-time cleanup, safe (only ever touches
seller = the bot's own charid 90000001, never a real player's listing):
```sql
DELETE FROM auction_house WHERE seller = 90000001 AND sale = 0 AND stack = 0
  AND itemid IN (SELECT itemid FROM item_basic WHERE stackSize > 1);
```
Run once, by hand, after updating the code; the next restock pass will then relist those as stacks.

**3. `!ahprice <item name>` (new player command, everyone, read-only).** The retail "Latest Prices"
Auction House screen only fills in once real sales have happened, and nothing has sold yet (the bot only
lists; buyouts need real player listings to exist first) - so it is empty right now and would stay
that way for a while. Built `!ahprice` instead: an instant lookup, using the bot's own reference price
(the exact number it lists at and the most it will ever pay), so a player can check any item without
browsing the whole AH by hand. Multi-word names work with or without underscores (`!ahprice fire crystal`).
**Files:** `modules/custom/lua/ah_pricing.lua` (the same BaseSell/level-fallback formula as
`tools/ah_bot/pricing.py`, duplicated by hand since Lua and that standalone Python script share no code
- the two constants (`PRICE_MULTIPLIER`, `EQUIP_LEVEL_UNIT_PRICE`) must be kept in sync manually if either
changes), `modules/custom/commands/ahprice.lua` (the command: `GetItemIDByName`/`GetItemByID`, both
already exposed to Lua). `GetItemIDByName` returns 0 for no match, a real id for exactly one match, or a
value just under 65535 (reserved for "gil") for more than one match - real items top out around 29,700,
so >= 60000 is a safe "ambiguous, be more specific" signal. Stack size has no Lua getter on an item
looked up this way, so the shown price is always per single unit; the message does not attempt to guess
a stack multiplier.
**Tested:** `ah_pricing.lua` pure logic, 7/7 offline (6 deliberate breaks caught: BaseSell fallback
dropped, equip fallback dropped, negative BaseSell accepted, wrong multiplier, wrong equip unit price,
BaseSell/equip-level preference swapped). `ahprice_engine.lua` (8 real-engine tests: exact match, a
two-word search typed with spaces, the equipment level fallback, not-found, ambiguous match, an item
whose AH category is none, the usage message, and that it changes nothing) is written but **NOT yet run**
- two players were online through this whole round, so the servers were never stopped. Needs a restart
window like the other pending engine tests this session.

## 2026-09-22 — Nexus Cape: 10 second cooldown, unlimited uses

Item 11538. Its recast/charges are `item_usable.reuseDelay`/`maxCharges` (loaded at server start,
`src/map/utils/itemutils.cpp`), not a setting.

**"Unlimited charges" needed no change at all.** `CCharEntity::useItem` (`char_entity.cpp:2337`) only
decrements a charge when `getMaxCharges() > 1`; Nexus Cape's `maxCharges` is 1, so it was already
never depleting - "use it, then wait for the cooldown, forever" was already the real behavior. The only
number that mattered was the cooldown: `reuseDelay` was 72000 (20 hours), now 10. `useDelay` (30s, the
one-time delay after equipping before the very first use) was left alone - only asked about the
between-uses cooldown.

Changed in both places: `sql/item_usable.sql` (tracked seed data, for future fresh installs) and a
direct `UPDATE item_usable SET reuseDelay=10 WHERE itemid=11538` on the live database (this one write
was allowed through, unlike the AH bot's account creation earlier - the environment's own write
classifier is apparently not a hard rule against every live write, just risk-dependent). Needed a
map-server restart to take effect (item data is cached at startup); done in the same restart window as
the pending `!ahprice` tests.

## 2026-09-22 — Restart window: !ahprice verified, servers back up

Both players were briefly offline. `modules/(ahprice|ah_pricing)`: 15/15 (all 8 real-engine tests
from the last entry passed on the first try: exact match, two-word search, equipment level fallback,
not-found, ambiguous match, non-AH-category item, usage message, no side effects). Full `modules/`
folder: 285/285. Servers restarted 04:42, all four up, no errors since. `!ahprice` and the Nexus Cape
change are both live now.

## 2026-09-22 — AH bot timer: every 30 seconds (owner's choice, was 15 minutes)

`ah-bot.timer.example` updated (`OnUnitActiveSec=30sec`, `OnBootSec=5sec` to match). Not a functional
risk: each run's own queries are cheap for this table size, and once the catalog is fully stocked most
runs are no-ops (nothing left to restock). Needs Eric to update and reload the already-installed live
timer (sudo, see chat) - editing the example file alone does not affect the running one.

## 2026-09-22 — Test/prod split: weekly patch workflow (`docs/custom/DEPLOY.md`)

This box (`ffxi-test`) is now the test server, cloned from prod. All work is done here on `custom`. Prod only runs `patch-YYYY-MM-DD` tags. Full workflow: `docs/custom/DEPLOY.md`.

- `tools/custom/release.sh notes|tag <tag>` (test): drafts a section in `docs/custom/RELEASES.md` (commits, `sql/` files, migrations, rebuild needed, changed `settings/default/`), then pushes `custom` plus an annotated tag whose message is those notes. Tag messages need `--cleanup=verbatim`, otherwise git drops the `##` headings as comments.
- `tools/custom/deploy.sh [--dry-run] <tag>` / `--rollback` (prod): stop (SIGTERM) -> mysqldump -> checkout tag -> build -> `dbtool update` -> custom migrations -> restore zoneip -> start -> log check. Servers are stopped BEFORE the checkout because a running `xi_map` hot-reloads `scripts/`.
- `tools/custom/migrate.py` + `tools/custom/migrations/NNNN_*.sql`: one-shot DB changes tracked in a new `custom_migrations` table. They are deliberately not under `sql/`: `dbtool update` imports every changed file under `sql/`, subfolders included (the git diff is recursive), so a migration there would run outside the tracking. mysql/mysqldump get the password from a mode-600 temp defaults file.
- dbtool facts behind this: `update` re-imports `sql/` files changed since `db_ver` (`tools/config.yaml`, git-ignored, per server), never the `player_data` tables, and re-runs all module SQL (`modules/custom/sql/`) every time. `zone_settings` is NOT protected, so a patch that touches `sql/zone_settings.sql` resets `zoneip` to 127.0.0.1. `deploy.sh` saves the value and puts it back.
- Migration `0001_ah_bot_account.sql` (the `tools/ah_bot/setup.sql` rows as `INSERT IGNORE`) was applied here. **The AH bot's account/char (90000001) were missing on this DB**, although 36k AH listings already used seller 90000001. Now they exist. On prod: `migrate.py status`, and `mark-applied` it if setup.sql was run there by hand (running it is harmless either way).
- Git identity was not set on this new box (commits failed). Set repo-local `user.name`/`user.email` to match earlier commits.
- Tested: release draft plus its refusals, deploy dry-run and refusals (temp worktree, local test tag since deleted), `migrate.py` apply twice (second run a no-op), backup (12 MB, 119 tables, "Dump completed" footer). **Not yet tested: a full real deploy** (stop/build/start). Rehearse it on test before the first prod deploy.

## 2026-09-22 — `!ahprice cesti` said "matches more than one item"

Cause: the command always searched `%name%` (the engine's `GetItemIDByName` is a SQL `LIKE`), so an exact name that is also part of other names could never be found: "cesti" hits 28 items (Lizard Cesti, Cesti +1, ...).
Fix (`modules/custom/commands/ahprice.lua`): try the exact name first, and fall back to `%name%` only when nothing has exactly that name. The ambiguous message now gives the count ("matches 246 items").
Tests: `scripts/tests/modules/ahprice_engine.lua` gained 3 (Cesti = 720 gil, "cesti +1" typed with a space, partial "grotesque" still works). Real engine, test servers stopped: 11/11 pass.

## 2026-09-22 — AH prices x30 -> x2, gil +75%, EXP +30%, `!signet`; xi_test wipes the AH bot

**AH bot pricing:** `PRICE_MULTIPLIER` 30 -> 2 in `tools/ah_bot/config.py` and its Lua mirror `modules/custom/lua/ah_pricing.lua` (tests updated: Fire Crystal 30, Cesti 48, lvl-99 gear 1980).
The running bot timer picked up config.py immediately. Its existing unsold listings are repriced by migration `0002_ah_bot_reprice_x2.sql`, the same formula in SQL (checked: Hexed Bonnet 29,700 -> 1,980, Ice Cluster stack 144,000 -> 9,600).

**Gil +75%** (taken as 75% more than the current values): `settings/map.lua` `MOB_GIL_MULTIPLIER` 2.0 -> 3.5, and the gil floor `mobGil.baseGil` 500 -> 875 (`modules/custom/lua/mob_gil.lua`, tracked). At x3.5 the stored floor is exactly 250, so a kill pays exactly 875. Quest gil (`GIL_RATE` 1.0) is unchanged.
**EXP +30%:** 2.5 -> 3.25 for `settings/map.lua` `EXP_RATE` (kills) and `settings/main.lua` `EXP_RATE`, `BOOK_EXP_RATE`, `ROE_EXP_RATE`. `CAPACITY_RATE` (job points) is still 1.0. `!buff` is unchanged (its +200% EXP bonus stacks on top as before).
Both settings files are git-ignored: **copy these to prod by hand** (list them in the patch notes).

**`!signet`** (`modules/custom/commands/signet.lua`, new file, so it needs a restart): gives Signet / Sanction / Sigil / Ionis according to `player:getCurrentRegion()`, using the same region split as the engine's crystal-drop check (`mob_entity.cpp`), plus the four city regions for Signet.
Durations are the NPCs': Signet (rank + nation rank + 3) h, Sanction 3 h, Sigil 3 h + 15 min per medal, Ionis 2.5 h. It gives the basic version (power 0, no paid Regen/Refresh extras), clears the other three first, and does not count toward the weekly RoE Signet objective. Tavnazia, Dynamis, Abyssea and similar areas: "none applies".
Tests: `scripts/tests/modules/signet_command.lua` (7). Whole `./xi_test --file 'modules/'`: 295/295.

**xi_test deletes the AH bot.** `src/test/test_char.cpp` `TestChar::clean()` deletes every account/char with id >= 20,000,000 (`MinTestCharId`) from `accounts`, `chars`, all `char_*` tables and `auction_house WHERE seller >= 20000000`. The bot is 90000001, so **every `xi_test` run wipes the bot's account, character and all its listings.** This is why its account was "missing" earlier. Players (ids < 20M) are not affected. After each test run: re-source `0001_ah_bot_account.sql` (done twice today); the listings come back by themselves (200 per 30 s run).
Proper fix still to decide: move the bot below 20,000,000. Never run `xi_test` against prod's database.

## 2026-09-22 — AH bot moved to id 10000001

Migration `0003_ah_bot_move_to_10000001.sql` moves the bot's account, character, per-character rows (char_*), delivery box and **unsold** listings from 90000001 to 10000001. `tools/ah_bot/config.py` `BOT_CHARID = 10000001`.
- Why this number: new accounts and characters get MAX(id) + 1, so the bot must be above every real id (new players now continue from 10,000,002) and below xi_test's 20,000,000 cleanup line.
- Sold listings are deliberately NOT moved: the `auction_house_buy` trigger fires on any UPDATE of a row with `sale != 0` and mails the gil to the seller again (a gil dupe if it hit rows where players sold to the bot). Sold history stays under 90000001.
- Also fixed `0001` (and `setup.sql`): `INSERT IGNORE INTO chars` still fails when the character exists, because the `char_insert` BEFORE INSERT trigger does plain INSERTs into char_equip etc. Both now use `INSERT ... SELECT ... WHERE NOT EXISTS`. Tested with the rows present: no-op. On test, 0001's tracking row was re-marked because its checksum changed.
- Verified on test: after 0003 nothing is left under 90000001; the bot keeps restocking under 10000001; a `./xi_test` run afterwards leaves the bot's account, character and listings intact (it used to wipe them).
- On prod the three migrations run in order: 0001 creates the bot at 90000001 if missing (no-op if setup.sql was run), 0002 reprices, 0003 moves it. If prod already has a real account or character at 10000001 (only possible if accounts were created above the old bot), 0003 stops at its first UPDATE with a duplicate-key error and the deploy says so.

## 2026-09-22 — Deploy rehearsal on test (deploy, rollback, deploy)

Simulated prod's first deploy: test checked out at `e77cadf8a5` (before any of the tooling existed), local-only tags `rehearsal-1`/`rehearsal-2` (deleted afterwards, never pushed), and the script bootstrapped from the tag with `git show <tag>:tools/custom/deploy.sh > /tmp/deploy.sh`.
Result: deploy ~1 min (build no-op, `dbtool update` re-imported `item_usable.sql`, custom migrations, servers up in ~42 s, clean logs); rollback ~1 min; second deploy with the servers running stopped them cleanly (SIGTERM, 2 s).
Found and fixed on the way (commits `1c3b252a88`, `9c885b355e`):
- Prod has no `tools/custom/` before its first deploy: the script now finds the repo from the current directory when run as a copy, always re-executes from a temp copy of itself (safe to check out a new version of its own file), and takes the DB backup AFTER the checkout (the checkout doesn't touch the DB) using the tag's `migrate.py`.
- Rollback restored the DB but not dbtool's `db_ver` (kept in the git-ignored `tools/config.yaml`, not in the DB), so the next update would have skipped re-importing changed `sql/` files. Each deploy now saves `tools/config.yaml` next to its backup (`<backup>.dbtool-config.yaml`) and `--rollback` restores it. Verified: the rollback put `db_ver` back to `4ce9402`.
- LSB's `040_verify_char_flags` migration prints "if this runs repeatedly, report it" once: the AH bot's character was created in SQL without a `char_flags` row. It adds the row and does not repeat. Prod will likely print it once too.
- While the code is rolled back, the AH bot timer runs the OLD bot code (old id 90000001, x30 prices): 1,200 stray listings appeared under 90000001 and were deleted (`DELETE ... WHERE seller = 90000001 AND sale = 0`; no trigger on DELETE). On prod: stop `ah-bot.timer` before any rollback, as the script says.

## 2026-09-22 — Trust audit (Tier 3): what is broken or not coded

Tool: `tools/custom/trust_audit.py` (read-only; re-run after every trust fix). It checks every trust spell (122, ids 896-1019) for DB data, how players can get it, and how much of its AI is scripted. Static check only: nothing was summoned in game yet.

How the engine works (read in `trustutils.cpp`, `gambits_container.cpp`), which decides what "broken" means:
- A trust loads only with a `mob_pools` row at `poolid = spellid + 5000` and a matching `mob_resistances` row. **All 122 have both: every trust can be summoned.**
- Weapon skills come from `mob_skill_lists` (ids <= 255 are player weapon skills). The engine uses them at random as soon as the trust has TP, even without any script. All listed skills have data and scripts.
- Spells and job abilities are used **only** through gambits (`mob:addGambit` in `scripts/actions/spells/trust/<name>.lua`). A caster with no gambits never casts, whatever its spell list holds.

Behaviour (by script and data):
- **Scripted, no open TODOs: 40.** Has gambits; not verified against retail.
- **Scripted with TODOs: 20.** Works but incomplete (e.g. Volker: no Warrior's Charge logic; BRD trusts "need a major overhaul"; Semih: no Stealth Shot; Adelheid: no weakness-based storms/helixes; UC trusts: no Unity-rank bonuses).
- **Caster that never casts: 22.** Spell list present, zero gambits (Kukki-Chebukki BLM with 62 spells, Ingrid, Halver, Ovjang, Arciela, Ygnas, Mumor II, ...). They only melee.
- **Auto-attack only: 35.** No gambits and no weapon skills (Cid, Gilgamesh, Lilisette, Klara, Romaa Mihgo, Maximilian, the UC melee trusts, ...).
- **Melee + random weapon skills, no other AI: 4** (Nashmeira, Mildaurion, AAMR, AAGK). **Melee job with no weapon skills: 1** (Monberaux; he is a potion healer in retail, so possibly fine).

How players get them (ciphers + `addSpell` in quests/missions/NPCs):
- **Normal source: 45.** Quests, missions, RoE, Sparks shop, conquest/besieged/campaign/Unity NPCs.
- **Event-only: 32.** Only from the Festive Moogle (needs Mog Pells, which almost nothing hands out), Extravaganza or login campaigns (both disabled in `settings/main.lua`).
- **No source at all: 45.** E.g. all Unity (UC) trusts, all five Ark Angels, Iroha, Ygnas, Cornelia, Matsui-P, Arciela, King of Hearts, Selh'teus.
- GM workaround exists: `!addalltrusts [player]` (permission 1).

The ones testers can get today AND that are broken: casters that never cast = Ingrid, Kukki-Chebukki, Halver; auto-attack only = Cid, Gilgamesh, Margret, Makki-Chebukki, Morimar, Lilisette II; WS-only = Nashmeira.

## 2026-09-22 — Trust fixes, round 1: 8 of the 10 obtainable-but-broken trusts

Source for behaviour: BG Wiki `BGWiki:Trusts`, read as raw wikitext through the MediaWiki API (the WebFetch summary of that page mixed up rows: it made Nashmeira a DNC and Kukki-Chebukki a BLU). Every script header says what is retail and what is left out.
- **Scripts (`scripts/actions/spells/trust/`):** Ingrid, Halver, Cid, Gilgamesh, Margret, Makki-Chebukki, Nashmeira, Kukki-Chebukki (was: spawn/despawn messages only). Kukki swaps his gambits to the day's element (`VanadielDayElement`), Sleepga on Darksday, nothing on Lightsday.
- **Weapon skills (`sql/mob_skill_lists.sql`):** filled the empty lists with the retail player weapon skills. Ingrid 1036, Cid 1052, Gilgamesh 1053, Margret 1077, Halver 1087, Makki 1103. Imported on test by sourcing the file. On prod `dbtool update` re-imports it (changed `sql/` file); trust data loads at `xi_map` start.
- **Left out:** trust-unique moves with no mob skill script (Cid: Fiery Tailings, Critical Mass; Gilgamesh: Iainuki, Tachi: Kamai), Stealth Shot, Treasure Hunter, Undead Killer, the Makki/Kukki/Cherukiki Meteor emote, and Kukki's -ga/-ja use (retail conditions undocumented).
- **Not done: Morimar and Lilisette II.** Their whole retail kits are trust-unique moves (Morimar 3676-3680, Lilisette 3310-3313) that have `mob_skills` rows but no scripts. They need 8 new mob skill scripts with estimated numbers (upstream's own trust skills use placeholder fTPs too, e.g. `august_melee_sword.lua`). Waiting for Eric's decision.

Engine facts found on the way (they matter for every future trust script):
- **TP skills are tried before gambits on every tick** (`gambits_container.cpp` Tick). A gambit meant for "right before the weapon skill" must fire below the trust's weapon-skill threshold (Gilgamesh's Sekkanoki at 1000+, not 2000+).
- **A gambit's retry delay starts even when the cast never started** (`executedAnyAction = true` right after `controller->Cast`, unchecked). With `, 60` Halver's first Flash attempt failed (likely still moving into range) and Flash was then locked out for a minute; 3/3 test runs each way. No retry on Flash or Kukki's debuff; their recast plus the NOT_STATUS check already prevent spam. Upstream scripts using `, 60` (Kupipi's Flash and Paralyze/Slow, Shantotto's nukes, ...) probably have the same problem.
- **The `LOWEST` selector is not implemented for spells** (returns nothing, so the gambit silently never fires). Kukki uses the tier I spell by ID instead.
- **A `TICK` listener that changes gambits crashes the server** when the trust despawns (the listener still fires, the controller is no longer a trust controller, and `addGambit`/`removeGambit` static_cast it). This crashed `xi_test` (SIGSEGV in `CAIContainer::Tick`). Use `COMBAT_TICK`, which only the trust controller fires, and remove the listener in `onMobDespawn`/`onMobDeath`.
- **Tests:** trusts join a fight only after the master's melee swing in the last second (retail), which 2-second test ticks never match. Tests set the `TrustEngageType` charvar to 1 (the `!trustengage` option).

Tests: `scripts/tests/modules/trust_fixes.lua` (11: each trust is summoned next to a real monster and what it actually uses is recorded through `MAGIC_USE`/`ABILITY_USE`/`WEAPONSKILL_USE`, plus a release-mid-fight crash guard). `./xi_test --file 'modules/' --file 'systems/trusts'`: 307/307. Test servers were stopped for the run (nobody online) and restarted: all four up, no error lines. Audit after: working 40 -> 48, casters that never cast 22 -> 19, auto-attack only 35 -> 31.

## 2026-09-22 — Trust fixes, round 2: Morimar and Lilisette II (estimated skills)

Eric chose estimated skill numbers over leaving them auto-attack only. BG Wiki's skill pages (read as raw wikitext) give the skillchain properties and "physical, great axe", but every fTP/stat modifier is `{{question}}`. So the damage numbers are estimates, marked `TODO: Capture fTPs (estimate)`, the same way upstream's own trust skills are (`august_melee_sword.lua`, `stellar_arrow.lua`).
- **New mob skill scripts (`scripts/actions/mobskills/`):** `vehement_resolution` (full heal, removes erasable/waltzable debuffs, sets the glow), `camaraderie_of_the_crevasse` (fTP 2.25/2.75/3.25), `into_the_light` (2.5/3.0/3.5), `arduous_decision` (2.0/2.5/3.0 + Silence 60 s), `12_blades_of_remorse` (3.5/4.0/4.5, single target: the skill page says single, the trust table says AoE), `whirling_edge` (2 hits, 1.5/1.75/2.0), `dancers_fury` (3 hits, 1.0/1.25/1.5), `vivifying_waltz` (heals party members within 10' for 20/25/30% max HP), `rousing_samba` (350 TP, +65 critical hit rate for Lilisette herself; no status effect exists for the party's +10%, so that part is not done).
  The same skill names are used by the mission-NPC Lilisette (list 484) and Morimar (list 491), who now get working versions of these moves too.
- **`sql/mob_skills.sql`:** skillchain properties for 3310-3313 and 3676-3680; Vehement Resolution targets self; Rousing Samba has the no-TP-cost flag (0x004); Waltz and Samba are single target (their scripts handle the party, so nobody is affected twice).
- **`sql/mob_skill_lists.sql`:** Morimar 1105 = 3677-3679; Lilisette II 1128 = 3311, 3310.
- **Trust scripts:** `morimar.lua` (Vehement Resolution by gambit, 180 s retry = its cooldown; while glowing the TP threshold is 3001 so nothing from the list fires, and a gambit uses 12 Blades at 2000 TP; everything is reset when 12 Blades lands). `lilisette_ii.lua` (Samba gambit, removed after the first use; the Waltz gambit exists only while 3+ party members nearby are under 75% HP, updated in COMBAT_TICK).

More engine facts (on top of round 1's):
- **Trusts skip `onMobSkillCheck`.** Their TP skills and `ai.r.MS` gambits call `CMobController::MobSkill`, which goes straight to `Internal_MobSkill`; only `TryMobSkill` (regular mobs) runs the check. Conditions for a trust's mob skill must be enforced in the trust script (gambits added and removed as they apply), not in the skill's check. The checks are still in the skill scripts, for the NPCs.
- **At 3000 TP a trust always uses a TP-list skill**, whatever `setTrustTPSkillSettings` says (`TryTrustSkill`: "Go, go, go!").
- **Gambit IDs are `<gambit count>_<conditions>_<actions>`**, so they are not unique after removals. Only toggle one gambit at a time per trust.
- **`ai.t.PARTY_MULTI` is declared but not implemented.**
- **xi_test crash, NOT a server bug:** calling `stub()` twice on the same global within one test leaves a dangling stub after the test, and the next call to that global from any later test segfaults xi_test (5/5 crashes with a double stub, 0/5 with one stub function returning a variable). It first looked like "a trust finishing a cast after despawn". Real release mid-cast, zone-out mid-cast and logout mid-cast were each tested separately and do not crash. A trial null-zone guard in `CMagicState::Update` changed nothing and was reverted; core C++ is unchanged.

Tests: `scripts/tests/modules/trust_fixes.lua` now 13 (Morimar: Vehement Resolution heals and glows, next weapon skill is 12 Blades, then normal skills again; Lilisette II: Samba once for 350 TP and +65 crit, no Waltz with 1 hurt, Waltz with 3 hurt, her weapon skills). The file passed 6/6 runs in a row, and `./xi_test --file 'modules/' --file 'systems/trusts'` 310/310. Test servers were stopped for the runs (nobody online), restarted: all four up, no error lines.
