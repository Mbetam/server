-----------------------------------
-- Boss arenas for Rem's Tales (HTBF v2): every number in one place. Not a module (loaded by require).
-- Eric's design (2026-09-30): the Battle Archivist in Western Adoulin -> pick a tier -> a private copy of Maquette
-- Abdhaljs-Legion A for the party -> the Arena Moogle inside spawns that tier's bosses one at a time.
-- Free, no cooldown, 30 minutes per boss, party / alliance and trusts welcome.
-- Drops: `personal` goes straight to every player inside; `loot` goes to the treasure pool (players roll).
-----------------------------------
local config = {}

-- copy_of_rems_tale,_chapter_1 (4064) ... chapter_10 (4073)
local function chapter(n)
    return 4063 + n
end

config.chapter = chapter

-- Rem's Tale chapters: 2-3 of each per player
config.dropMin = 2
config.dropMax = 3

-- The Battle Archivist: Eric's !pos in Western Adoulin (Y is height). The arena exit brings you back here.
config.archivist =
{
    zoneId   = xi.zone.WESTERN_ADOULIN,
    x        = 12.0314,
    y        = -0.1500,
    z        = 20.3859,
    rotation = 46,
    look     = 82, -- the Moogle model the other custom NPCs use
}

-- Party / alliance members within this many yalms of the Archivist come along
config.partyRange = 15

-- The arena: one wing of Maquette Abdhaljs-Legion A (a walkable square x 130..190, z -188..-128, height 12),
-- as a private instance per party. The instance_list row: modules/custom/sql/htbf_arena.sql.
config.arena =
{
    zoneId       = xi.zone.MAQUETTE_ABDHALJS_LEGION_A,
    instanceId   = 18300,
    entry        = { 142.0, 12.0, -142.0, 32 },
    moogle       = { name = 'HTBF_Moogle', packetName = 'Arena Moogle', look = 82, pos = { 137.0, 12.0, -146.0, 32 } },
    exit         = { name = 'HTBF_Exit', packetName = 'Arena Exit', look = 51, pos = { 145.0, 12.0, -136.0, 32 } },
    bossSpawn    = { 162.0, 12.0, -162.0, 160 },
    spawnDelay   = 5,       -- seconds between picking a boss and it appearing
    fightSeconds = 30 * 60, -- per boss
    wipeSeconds  = 180,     -- everyone inside KO'd this long: the boss leaves
    emptySeconds = 30,      -- nobody inside this long: the arena closes
}

-- Monster scaling on spawn: level, HP multiplier, attack / magic attack bonus (%). Eric confirmed 2026-09-30.
-- hp: only for bosses without their own `hp` below (Tier 1). Eric, later that day: bosses with a known retail HP use
-- it as their final HP, with no multiplier.
-- macc / stat: magic accuracy and INT / MND added, so the bosses' spells and magic TP moves land against real
-- 119 gear (without them Ou's Aero V was quarter-resisted to 301 against 608 magic evasion, with 0 bonus).
-- regen / regain: added on top (Tier 5 only).
-- acc: (superseded by `floors` below; kept at 0) melee accuracy added on 2026-10-04.
-- damage: attack % (no longer used for physical attack, see floors) and magic attack bonus.
config.tiers =
{
    { name = 'Tier 1', level = 125, hp = 4, damage = 50,  macc = 50,  stat = 0   },
    { name = 'Tier 2', level = 128, hp = 5, damage = 75,  macc = 150, stat = 60  },
    { name = 'Tier 3', level = 130, hp = 5, damage = 75,  macc = 200, stat = 80  },
    { name = 'Tier 4', level = 139, hp = 6, damage = 100, macc = 300, stat = 120 },
    { name = 'Tier 5', level = 139, hp = 8, damage = 125, macc = 350, stat = 150, regen = 300, regain = 100 },
}

-- Combat stat floors: each boss is raised to at least these FINAL values on spawn (a boss already above one keeps
-- its own, e.g. Adamantoise's defense). Eric 2026-10-04: Tier 1 at least 30% harder, an iLvl 117 player should
-- struggle there, the other tiers scaled up, real defensive stats (Khimaira had 568 Eva, 606 Def, 373 M.Eva, 0 M.Def).
-- BG Wiki has no DEF / EVA / M.EVA numbers for these bosses or the comparable iLvl 117-119 content (Escha Zi'Tah,
-- Reisenjima, Omen: the stat tables are empty) apart from the Omen bosses' ~1,400-1,425 evasion (Kyou, Glassy
-- Thinker), which proved far too much here once the level gap (139 vs 99) stacks on it: an unbuffed iLvl 117 stand-in
-- (1,150 Acc, 1,300 Att, 1,100 Def / Eva) hit Tier 4 5% of the time. So the floors were tuned by measurement
-- against that stand-in (4-minute melee runs, docs/custom/NOTES.md 2026-10-04):
--   Tier 1: it deals 39% less than before, the boss lands ~50% (was ~24%) and deals 2.3x the damage
--   Tier 4: it deals 54% less, the boss lands ~93% and deals 4.6x the damage
-- Tiers 2-3 sit between, Tier 5 a step above Tier 4. Buffs (food, songs, rolls) move the player back up.
-- Magic evasion does not rise with the tier: the level gap already makes spells land less often, and at level 139
-- 800 M.Eva turned an iLvl 117 mage's Fire V into 1/8 resists almost every cast. Fire V from that mage, average
-- (with the M.Def floor): Tier 1 3,218 -> ~2,490 (750); Tier 4 2,606 -> ~1,540 (600).
config.floors =
{
    { acc = 950,  att = 1050, def = 850,  eva = 850, meva = 750, mdb = 60  },
    { acc = 975,  att = 1100, def = 900,  eva = 875, meva = 775, mdb = 90  },
    { acc = 1000, att = 1150, def = 950,  eva = 900, meva = 775, mdb = 120 },
    { acc = 1025, att = 1200, def = 1000, eva = 950, meva = 600, mdb = 150 },
    { acc = 1050, att = 1250, def = 1050, eva = 975, meva = 600, mdb = 180 }, -- Ou resists fire heavily already: 650 M.Eva cut Fire V ~70%
}

-- Magic damage taken, in 1/100 % (DMGMAGIC): retail endgame bosses pair a magic defense bonus with magic damage
-- reduction. Eric 2026-10-05: an iLvl 117 nuker still hit Tier 1 for 6,000+.
-- Removed by Eric 2026-10-05 (was -1500 / -2000 / -2500 / -3000 / -3500); the magic defense floors stay.
config.magicTaken = nil

-- Every boss's final HP (tier multiplier or retail `hp`) is multiplied by this (Eric 2026-10-04: more HP for all)
config.hpScale = 1 -- was 1.5 (2026-10-04); every boss now has its final HP in `hp` (Eric, 2026-10-05)

-----------------------------------
-- Items
-----------------------------------
local item =
{
    PLUTON_BOX  = 6183,
    BEITETSU_BOX = 6184,
    BOULDER_BOX = 6185,
}

-- Boxes: 1-3 per player (Eric)
local anyBox = { oneOf = { item.PLUTON_BOX, item.BOULDER_BOX, item.BEITETSU_BOX }, min = 1, max = 3 }

-- Paragon job cards (paragon_warrior_card 9281 ... paragon_rune_fencer_card 9302, in job order): 3-6 of the card of
-- the player's current main job (Eric)
config.paragonCard = function(job)
    return 9280 + job
end

local jobCards = { jobCard = true, min = 3, max = 6 }

-- Treasure pool entries: { item = id, rate = per mille } or { oneOf = { ids }, rate = per mille } (one of them).
-- Rates are fixed (no Treasure Hunter); the server's DROP_RATE_MULTIPLIER (x2) still applies.
local function always(id)
    return { item = id, rate = 1000 }
end

local function oneOf(ids, rate)
    return { oneOf = ids, rate = rate or 1000 }
end

-----------------------------------
-- The bosses
-----------------------------------
-- group: the mob_groups row the copy is built from (groupId, zoneId). Tier 1: Nyzul Isle's copies of the famous NMs.
-- Tier 2: the Unity "little brothers" in Rala Waterways [U] (same families: Achuka is a Gabbrath like Tojil, and so
-- on), renamed. Tiers 3-5: custom rows in the arena zone (modules/custom/sql/htbf_bosses.sql).
-- script: the retail mob script whose fight hooks the copy borrows (see htbf_arena.lua); skip: hooks not to borrow.
-- skillList / spellList: override the group's lists. specials: job two-hours ({ skill, hpp }).
-- hp: final HP, from BG Wiki (Eric, 2026-09-30: retail HP, no multiplier). Ou ~1.4M, Tojil ~1.2M, Dakuwaqa 1.25M,
-- Muyingwa 750k; ranges taken at the middle: Wopket 400k-1.2M -> 800k, Utkux 485-776k -> 630k, Glassy 500k-1M ->
-- 750k. No number on BG Wiki, estimated: Cailimh 900k (its Delve tier-mates), Kin / Gin / Kei / Kyou / Fu 600k.
-- Tier 1 has no retail figure either and keeps the tier multiplier.
-- 2026-10-05 Eric set final HP ranges after looking over every boss: Tier 1 200-250k, Tier 2 300-350k, Tier 4
-- 1.4-1.6M, Tiers 3 and 5 unchanged (Glassy 1.125M, Ou 2.1M). Within a range the sturdier bosses sit higher.
-- spellBonus: { [spellId] = base damage added while casting that spell } (Eric: boost Holy, whose NPC base is only 125
-- next to Aero V's 738; Kin and Kyou's Holy hit ~270 in 119 gear).  21 = Holy.
local nyzul  = xi.zone.NYZUL_ISLE
local rala   = xi.zone.RALA_WATERWAYS_U
local arenaZ = xi.zone.MAQUETTE_ABDHALJS_LEGION_A

config.bosses =
{
    -- Tier 1: chapters 1-5 personal (2-3 each), a crafting material in the pool; Khimaira: a Pluton Box
    [1] =
    {
        { key = 'Behemoth', hp = 220000,    name = 'Behemoth',    group = { 161, nyzul }, script = 'Behemoths_Dominion/mobs/Behemoth',   personal = { { chapter = 1 } }, loot = { always(844) } },  -- Phoenix Feather
        { key = 'Adamantoise', hp = 250000, name = 'Adamantoise', group = { 260, nyzul }, script = 'Valley_of_Sorrows/mobs/Adamantoise', personal = { { chapter = 2 } }, loot = { always(837) } },  -- Malboro Fiber
        { key = 'Fafnir', hp = 240000,      name = 'Fafnir',      group = { 162, nyzul }, script = 'Dragons_Aery/mobs/Fafnir',           personal = { { chapter = 3 } }, loot = { always(1110) } }, -- Black Beetle Blood
        { key = 'Cerberus', hp = 230000,    name = 'Cerberus',    group = { 165, nyzul }, script = 'Mount_Zhayolm/mobs/Cerberus',        personal = { { chapter = 4 } }, loot = { always(836) } },  -- Damascene Cloth
        { key = 'Hydra', hp = 230000,       name = 'Hydra',       group = { 164, nyzul }, script = 'Wajaom_Woodlands/mobs/Hydra',        personal = { { chapter = 5 } }, loot = { always(1311) } }, -- Oxblood
        { key = 'Khimaira', hp = 200000,    name = 'Khimaira',    group = { 163, nyzul }, script = 'Caedarva_Mire/mobs/Khimaira',        personal = { { item = item.PLUTON_BOX, min = 1, max = 3 } } },
    },

    -- Tier 2: chapters 6-10 personal, one of two Adoulin materials in the pool; Utkux: a Beitetsu Box
    [2] =
    {
        { key = 'Tojil', hp = 345000,    name = 'Tojil',    group = { 59, rala }, personal = { { chapter = 6 } },  loot = { oneOf({ 8720, 3977 }) } }, -- Maliyakaleya Orb / Gabbrath Horn
        { key = 'Wopket', hp = 315000,   name = 'Wopket',   group = { 62, rala }, personal = { { chapter = 7 } },  loot = { oneOf({ 8722, 4014 }) } }, -- Hepatizon Ingot / Yggdreant Bole
        { key = 'Muyingwa', hp = 310000, name = 'Muyingwa', group = { 58, rala }, personal = { { chapter = 8 } },  loot = { oneOf({ 8724, 3980 }) } }, -- Beryllium Ingot / Bztavian Stinger
        { key = 'Cailimh', hp = 330000,  name = 'Cailimh',  group = { 61, rala }, personal = { { chapter = 9 } },  loot = { oneOf({ 8726, 4012 }) } }, -- Exalted Lumber / Waktza Rostrum
        -- Tchakka's SQL pool carries Achuka's skill list (461); the Rockfin list is 452
        { key = 'Dakuwaqa', hp = 350000, name = 'Dakuwaqa', group = { 60, rala }, skillList = 452, personal = { { chapter = 10 } }, loot = { oneOf({ 8728, 3979 }) } }, -- Sif's Macrame / Rockfin Tooth
        { key = 'Utkux', hp = 300000,    name = 'Utkux',    group = { 63, rala }, personal = { { item = item.BEITETSU_BOX, min = 1, max = 3 } } },
    },

    -- Tier 3: the Glassy trio of Reisenjima Henge. Personal: Paragon cards of your job (Thinker: a Boulder Box);
    -- pool: retail (BG Wiki): one of three pieces of gear, and the boss's crystal
    [3] =
    {
        { key = 'Glassy_Craver', hp = 1125000,  name = 'Glassy Craver',  group = { 900, arenaZ }, specials = { { skill = 'MIGHTY_STRIKES_1', hpp = 50 } }, personal = { jobCards },
          loot = { oneOf({ 26421, 26084, 26029 }), always(4075) } }, -- Nusku Shield / Sherida Earring / Anu Torque, Hope Crystal
        { key = 'Glassy_Gorger', hp = 1125000,  name = 'Glassy Gorger',  group = { 901, arenaZ }, personal = { jobCards },
          loot = { oneOf({ 26188, 22213, 26030 }), always(4076) } }, -- Kishar Ring / Enki Strap / Erra Pendant, Fulfillment Crystal
        { key = 'Glassy_Thinker', hp = 1125000, name = 'Glassy Thinker', group = { 902, arenaZ }, personal = { { item = item.BOULDER_BOX, min = 1, max = 3 } },
          loot = { oneOf({ 26028, 22281, 26420 }), always(4074) } }, -- Adad Amulet / Knobkierrie / Adapa Shield, Thought Crystal
    },

    -- Tier 4: the Omen Caturae at level 139. Personal: 1-3 of a random box; pool: retail (BG Wiki)
    [4] =
    {
        { key = 'Fu', hp = 1500000,   name = 'Fu',   group = { 907, arenaZ }, specials = { { skill = 'MIGHTY_STRIKES_1', hpp = 50 } }, personal = { anyBox },
          loot = { always(9307), always(4081), { item = 9307, rate = 100 }, { item = 26185, rate = 100 }, { item = 26026, rate = 100 }, { item = 25789, rate = 10 } } }, -- Fu's Scale, Moonbow Stone; Niqmaddu Ring, Shulmanu Collar, Nisroch Jerkin
        { key = 'Gin', hp = 1450000,  name = 'Gin',  group = { 904, arenaZ }, specials = { { skill = 'PERFECT_DODGE_1', hpp = 65 } }, personal = { anyBox },
          loot = { always(9304), always(4079), { item = 9304, rate = 100 }, { item = 22280, rate = 100 }, { item = 26187, rate = 100 }, { item = 25786, rate = 10 } } }, -- Gin's Scale, Moonbow Leather; Yamarang, Dingir Ring, Ashera Harness
        { key = 'Kei', hp = 1550000,  name = 'Kei',  group = { 905, arenaZ }, specials = { { skill = 'BENEDICTION_1', hpp = 30 } }, personal = { anyBox },
          loot = { always(9305), always(4080), { item = 26419, rate = 100 }, { item = 26082, rate = 100 }, { item = 25787, rate = 10 } } }, -- Kei's Scale, Moonbow Urushi; Ammurapi Shield, Lugalbanda Earring, Shamash Robe
        { key = 'Kin', spellBonus = { [21] = 600 }, hp = 1500000,  name = 'Kin',  group = { 903, arenaZ }, specials = { { skill = 'MANAFONT_1', hpp = 50 } }, personal = { anyBox },
          loot = { always(9303), always(4077), { item = 22212, rate = 100 }, { item = 26186, rate = 100 }, { item = 25785, rate = 10 } } }, -- Kin's Scale, Moonbow Steel; Utu Grip, Ilabrat Ring, Dagon Breastplate
        { key = 'Kyou', spellBonus = { [21] = 600 }, hp = 1600000, name = 'Kyou', group = { 906, arenaZ }, specials = { { skill = 'HUNDRED_FISTS_1', hpp = 50 } }, personal = { anyBox },
          loot = { always(9306), always(4078), { item = 26083, rate = 100 }, { item = 26027, rate = 100 }, { item = 25788, rate = 10 } } }, -- Kyou's Scale, Moonbow Cloth; Enmerkar Earring, Iskur Gorget, Udug Jacket
    },

    -- Tier 5: Ou, harder than retail (tier regen / regain, Chainspell at 65%, and once at 10% HP he recovers to 25%,
    -- like retail's Prophylaxis). Personal: 1-3 of a random box; pool: retail (BG Wiki)
    [5] =
    {
        { key = 'Ou', hp = 2100000, name = 'Ou', group = { 908, arenaZ }, specials = { { skill = 'CHAINSPELL_1', hpp = 65 } }, rally = { at = 10, to = 25 }, personal = { anyBox },
          loot =
          {
              oneOf({ 25825, 25827, 25824, 25826, 26342, 26342, 26342 }, 400), -- a Regal handpiece (5% each) or the Regal Belt (15%)
              oneOf({ 26085, 21396, 26038, 26191 }, 600),                       -- Regal Earring / Gem / Necklace / Ring (15% each)
              oneOf({ 9303, 9304, 9305, 9306, 9307 }, 150),                     -- a scale
              oneOf({ 4077, 4078, 4079, 4080, 4081, 4082 }),                    -- Moonbow materials / Moonlight Coral, twice
              oneOf({ 4077, 4078, 4079, 4080, 4081, 4082 }),
          } },
    },
}

return config
