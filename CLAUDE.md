# FFXI Private Server (LandSandBoat) — Project Context

This repo is a fork of LandSandBoat (LSB), an open-source FFXI server emulator.
The owner (Eric) is a senior sysadmin and is building a fresh custom server.
Design baseline: the defunct "Nocturnal Souls" (NocSouls) server, described below.

## Working rules

- Host is an Ubuntu **22.04** VM (16 cores, 31 GB RAM, ~48 GB disk). Never run anything as root unless a step requires sudo. `sudo` needs a password, so Claude cannot run sudo steps itself: give Eric the exact command to run with the `!` prefix, and never ask for or store the sudo password.
- Ask before destructive actions: `dbtool` Reset DB, dropping tables, `git reset --hard`, deleting files outside `build/`.
- Never commit `settings/*.lua` files containing DB passwords. Only `settings/default/` is tracked upstream.
- Prefer putting custom content in `modules/` (Lua/C++ modules), SQL migrations, and `scripts/` overrides over editing core `src/`. This keeps upstream merges cheap. When core C++ must change, keep the diff small and note why in the commit message.
- Work on a `custom` branch. Remotes: `origin` = Eric's fork (`https://github.com/Mbetam/server`), `upstream` = LandSandBoat/server (branch `base`). See the LSB wiki page "Maintaining Your Fork". Do not push or commit unless asked; `scripts/tests/systems/charutils.lua` is deliberately left uncommitted for now.
- DB: user `mbetam`, database `mbetam_xi` (non-default names). The password lives only in the git-ignored `settings/network.lua` and never in tracked files, docs, or commit messages.
- Verify before claiming success: build passes, all four `xi_*` processes stay up, `log/` is clean, and a client can log in.
- Record what was tried and what broke in `docs/custom/NOTES.md` (create it) so context survives between sessions.

## Fast build setup (goal: fastest possible rebuilds)

The previous server took 15-20 minutes to build. Target: a few minutes cold, seconds incremental.
These speed tools are suggestions, not from LSB docs — confirm they work with LSB's CMake and fall back to plain `cmake`/`make` if not.

LSB now requires a **C++23 compiler and CMake 3.25+** (`CMakeLists.txt`; Quick Start Guide: CI builds with `g++-15` and `clang-22`, older `g++` is expected to fail).
Ubuntu 22.04's own repos only reach g++-12 and CMake 3.22, so `g++-15` comes from the `ubuntu-toolchain-r/test` PPA and CMake comes from pip.

```
# Needs sudo: run with the `!` prefix
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test && sudo apt update
sudo apt install -y git python3 python3-pip python3-venv g++-15 ninja-build pkg-config \
  libluajit-5.1-dev libzmq3-dev libssl-dev zlib1g-dev libzstd-dev libdwarf-dev \
  mariadb-server libmariadb-dev-compat libmariadb-dev binutils-dev ccache mold

# No sudo: CMake >= 3.25 from pip, ideally inside a venv (also used for tools/requirements.txt)
pip3 install cmake

export PATH=$HOME/lsb-venv/bin:$PATH PKG_CONFIG_PATH=$HOME/.local/libdwarf/lib/pkgconfig
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=gcc-15 -DCMAKE_CXX_COMPILER=g++-15 -DENABLE_IPO=OFF \
  "-DCMAKE_CXX_FLAGS=-Wno-error=null-dereference -Wno-error=maybe-uninitialized -Wno-error=array-bounds -Wno-error=stringop-truncation -Wno-error=nonnull" \
  "-DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=mold -L$HOME/.local/libdwarf/lib"
cmake --build build -j16
```

- Keep one persistent `build/` directory. Never rebuild from scratch unless CMake config changed.
- ccache: disk is small (~35 GB free), so use `ccache -M 10G`, not a huge cache.
- **Working build recipe (verified 2026-09-21, all five `xi_*` binaries link):** the block above. Why each non-obvious flag exists:
  - `-DENABLE_IPO=OFF`: Release turns LTO on by default. Under LTO mold falls back to ld.bfd, the link crashed (`pthread_create` failed), and every relink is slow. Off = fast mold links.
  - The five `-Wno-error=...`: with LTO off, GCC 15 emits these in third-party headers (asio, sol2, libstdc++) and `-Werror` made them fatal. Only these categories are downgraded; `-Werror` stays on for everything else.
  - `-L$HOME/.local/libdwarf/lib`: cpptrace links a bare `-ldwarf`, which otherwise resolves to the old system libdwarf.
  - Do NOT pass `-DCMAKE_CXX_COMPILER_LAUNCHER=ccache`: LSB's `cmake/Cache.cmake` already enables ccache, and a bare `ccache` on the command line gets resolved relative to the source dir (`/home/mbetam/server/ccache: not found`).
- **libdwarf on 22.04:** the distro `libdwarf-dev` (`20210528`) has no `.pc` file and is too old for cpptrace. Workaround: libdwarf 2.1.0 built from source into `~/.local/libdwarf`, plus two fixes to that prefix (a `libdwarf/` header subdir so `<libdwarf/libdwarf.h>` beats `/usr/include`, and `-lz -lzstd` added to its `libdwarf.pc` `Libs:`). Full steps in `docs/custom/NOTES.md`. If you change the `.pc`, clear the cache with `cmake -S . -B build -ULIBDWARF_*`.
- Check `cmake --list-presets` (repo has CMakePresets.json) and compare against the flags above.
- Lua, SQL, and module script changes do NOT need a recompile. Only C++ changes do.
- Debug builds are for debugging only; use Release for normal iteration speed unless stepping through code.

## Standard LSB install steps (from the LSB Quick Start Guide)

1. MariaDB (Ubuntu 22.04 repo ships 10.6; the Quick Start suggests 10.11 — if `dbtool` or the server complains about the version, note it in NOTES.md), then `sudo mysql_secure_installation`.
2. Create DB user and database (change all three defaults; ours are user `mbetam`, database `mbetam_xi`):
   `CREATE USER 'mbetam'@'localhost' IDENTIFIED BY '<pw>'; CREATE DATABASE mbetam_xi CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; GRANT ALL PRIVILEGES ON mbetam_xi.* TO 'mbetam'@'localhost';`
   Feed the SQL to `sudo mysql < file` from a mode-600 temp file so the password never appears on a command line, then delete the file.
3. Repo is already cloned (with submodules). `pip3 install -r tools/requirements.txt` (venv on 22.04), `cp settings/default/* settings`
4. Edit `settings/network.lua` (`SQL_LOGIN`, `SQL_PASSWORD`, `SQL_DATABASE`) and `settings/main.lua`.
5. Build (above), then `cd tools && python3 dbtool.py` and choose Reset DB.
6. Start the executables in the repo root: `xi_connect`, `xi_map`, `xi_search`, `xi_world`. Check `log/` and `dmp/` if any exit.
7. Updating: stop all processes, `git stash; git pull; git submodule update --init --recursive --progress; git stash pop`, rebuild, then `python3 dbtool.py update`.

Notes: submodules `navmeshes` and `ximeshes` are required (`--recursive`). A Docker setup exists but is unofficial; not used here.

## Tier plan

- **Tier 1 — Vanilla LSB running.** Fast build, DB, four processes up. Done when a client connects and creates a character.
- **Tier 2 — Usable server.** Client setup (xiloader with Ashita or Windower), GM character, `settings/main.lua` tuning (level cap, exp/drop rates), remote access.
- **Tier 3 — Triage.** Compare the build against the LSB wiki "What Works" table. Log every broken system in `docs/custom/NOTES.md`, then fix by priority.
- **Tier 4+ — NocSouls-style features**, one at a time, as modules (see baseline). Suggested order: QoL commands and teleports, XP/drop tuning, daily hunts, daily BCNMs, custom augments, gear progression, Adventure Quest, Dynamis-style raid, custom Synergy crafting.

## Design baseline: Nocturnal Souls (from its archived site)

Philosophy: for solo and small-group adults with limited time. Custom story, faster progression, big crits, less grind. Tough mobs, active combat (constant casting/weaponskill chains), no 12-hour camps.

- Level cap 99/99 with full subjobs; Maat and moogle fetch quests skipped; advanced job quests from level 15; custom master job quests; a "Heroics" system.
- XP boosted to roughly retail-with-all-Rhapsodies; FoV/GoV buffed; level sync and gear sync working; trusts enabled; solo/duo-friendly scaling content.
- Bags/wardrobes unlocked to 80 including wardrobes 5-8; mission battlefields uncapped.
- Daily hunts (XP, gil, gear currency) and daily BCNMs (from level 20) with level-appropriate rare/HQ gear.
- Stocked AH with a bot that buys unwanted gear at ffxiah-based prices; increased drops on significant items; easier crystals/seals/currencies.
- Custom augments: up to 4 per item from one NPC; focus on secondary stats (dual wield, haste, triple attack, fast cast) because base stats are bumped; tiers unlock with progression; removal costs gil.
- Custom artifact/relic/empyrean progression; goal of starter relics by 75 and reforging by 99 via solo/duo tasks and daily hunts.
- Custom commands: !tele, !telelist (player-set teleport points), !shop, !gotoexp, !ah, !mh, !home, !escape, !signet, and more (over a dozen).
- Adventure Quest: custom intro questline that unlocks Heroics, endgame zones, and armor upgrades; fights scale with party size.
- Endgame: Dynamis Divergence (small-group custom raid, 2-hour window, 36-hour lockout per zone), reworked Abyssea (large cruor from NMs), streamlined Besieged, Voidwatch campaign.
- Custom Synergy crafting, crafting/harvesting bonuses, custom recipes, seasonal events, monthly bonus day.
- Buffed magic relative to stock DSP; tweaked mob AI and drops.

Unknown from public sources: exact XP/drop multipliers, server rules, roadmap, and why it closed. Treat numbers as tunable starting points, not facts to match.

## Owner decisions (these override the NocSouls baseline where they differ)

- **Retail stats and skills.** Base stats, skills, gear, mobs and job data stay as retail (as shipped by LSB). Extra power comes from **custom augments layered on top of retail items**, not from buffing base values.
  This replaces the baseline line "base stats are bumped, so augments focus on secondary stats". Do not change item/mob/job base data to make things stronger without asking.
  The repo already has augment plumbing to build on: item extra data in `src/map/items/exdata/` (`augment_standard`, `augment_trial`, ...), `scripts/enum/augment.lua`, and the `Exdata` Lua spec (`scripts/specs/core/Exdata.lua`).
- **Rates and caps chosen so far (all in git-ignored `settings/`):** level cap 99 with subjob at the main job's level, EXP x2.5 (kills, quests, books, RoE), drops x2 and mob gil x2, movement speed +50% (on foot and mounted). Record every change in `docs/custom/NOTES.md`.
- **Server is public for a small group of testers.** The public IP must never be written to a tracked file, and never posted publicly. Account creation should be closed once testers have accounts.

## Style

- Explain briefly what you changed and why. Show the exact commands you ran for anything that affects the system.
- When a fix is uncertain, say so and describe how you tested it.
