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
