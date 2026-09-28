-----------------------------------
-- Daily hunts: counts, rewards and where the Hunt Board stands. Not a module (loaded by require).
-- Eric's choices (2026-09-26): 5 hunts a day (4 kill hunts and 1 NM hunt), new ones at JST midnight, from a Hunt Board
-- NPC and the !hunt command; they pay EXP, gil and Hunt Marks, and the NM hunt a Legion trophy. The +4 armor tiers cost
-- Hunt Marks and a trophy (af_upgrade_config.lua). The numbers are starting points.
-----------------------------------
local config = {}

config.killHunts = 4
config.nmHunts   = 1

-- Monsters to kill in a kill hunt: random in [min, max]
config.killCount = { min = 10, max = 15 }

-- Level window around the player's main job level: kill hunts whose zone's usual levels overlap
-- [level - below, level + above]. Widened step by step when too few targets fit (high levels have fewer).
config.window = { below = 6, above = 2, widen = 5 }

-- Rewards per finished hunt. EXP is (base + level^2 * perLevel2) x BOOK_EXP_RATE (like Fields of Valor pages);
-- at level 99 it becomes limit points. Gil is level x gilPerLevel.
config.rewards =
{
    kill = { expBase = 50, expPerLevel2 = 0.8, gilPerLevel = 100, marks = 15 },
    nm   = { expBase = 50, expPerLevel2 = 1.6, gilPerLevel = 300, marks = 40 },
    allDoneMarks = 20, -- extra when all of the day's hunts are done
}

-- The NM hunt also gives one Legion trophy (Rare: one of each at a time). The one you don't hold yet, at random;
-- extra Hunt Marks instead if you hold all four.
config.trophies =
{
    3529, -- lofty_trophy
    3530, -- mired_trophy
    3531, -- soaring_trophy
    3532, -- veiled_trophy
}
config.trophyMarksIfFull = 20

-- Rerolling: an unfinished hunt can be swapped for a new one of the same kind, this many times a day
config.rerollsPerDay = 1

-- Char vars. Hunt Marks are kept in a char var (no currency slot is free in char_points).
config.var =
{
    day     = 'HUNT_DAY',     -- the JST midnight the hunts run until
    marks   = 'HUNT_MARKS',
    rerolls = 'HUNT_REROLLS', -- rerolls used today
    bonus   = 'HUNT_BONUS',   -- 1 once the all-done bonus is paid today
    -- per hunt n: HUNT_<n>_KIND (1 kill, 2 NM), _KEY (kill: zone * 1000 + family; NM: the NM's first mob id),
    -- _NEED, _HAVE, _PAID
}

-- The NPC's look (the Moogle the Upgrader, Augmenter and Trust Vendor use) and where it stands (!pos, rotation 0-255)
config.npcModel = 82

config.placements =
{
    -- Norg, near the Armor Upgrader. Chosen by Eric with !pos (2026-09-28).
    { zone = 'Norg', x = -9.3516, y = 1.0977, z = -27.6831, rotation = 126 },

    -- GM Home, for testing
    { zone = 'GM_Home', x = 14.0, y = 0.0, z = 3.0, rotation = 128 },
}

return config
