-----------------------------------
-- Ambuscade (custom): every number in one place. Not a module (loaded by require).
-- Eric's design (2026-10-05): LSB's Ambuscade is a stub, so Mhaura gets
-- 1. Gorpa-Masorpa's exchange: Hallmarks and Gallantry buy the retail Ambuscade rewards, retail prices, no monthly
--    limits (amb_shop.lua);
-- 2. a wave Ambuscade: the Ambuscade Tome next to him sends you and your party into a private copy of Maquette
--    Abdhaljs-Legion B to fight 3, 5, 7 or 10 waves of Legion beasts, each wave harder, the last one a level 128 boss
--    (amb_waves.lua, built on the boss arena's helpers in modules/custom/htbf/htbf_arena.lua).
-- Free, no cooldown, party / alliance and trusts welcome. Hallmark amounts are Claude's proposal (see `runs`).
-----------------------------------
local config = {}

-- Where the run sends you back to, and where anyone logging back in after their run closed lands: next to Gorpa
-- (the retail exit spot)
config.mhaura = { zoneId = xi.zone.MHAURA, x = -34.2, y = -16.0, z = 58.0, rotation = 32 }

-----------------------------------
-- 1. The exchange
-----------------------------------
-- Retail prices (BG Wiki "Ambuscade Rewards"). Retail sells chits / vouchers that are then traded for gear; here
-- Gorpa sells the gear itself at the chit's price, and upgrades it when you trade him a piece:
--   base piece: the chit's Hallmarks; +1: the chit +1's Gallantry (retail: Gallantry only); +2: Hallmarks, 10x the chit
-- (not retail: retail +2 needs materials from a monthly-limited list).
-- Order of `pieces` and of each price list: head, body, hands, legs, feet.
config.slotNames = { 'Head', 'Body', 'Hands', 'Legs', 'Feet' }

config.armorPrice =
{
    base  = { 250, 600, 150, 400, 100 },      -- Hallmarks
    plus1 = { 750, 1800, 450, 1200, 300 },    -- Gallantry
    plus2 = { 2500, 6000, 1500, 4000, 1000 }, -- Hallmarks
}

config.ringPrice = 1000 -- Hallmarks (retail: Ambuscade Chit (ring))
config.capePrice = 500  -- Hallmarks (retail: Ambuscade Voucher (back)); the cape of your main job, unaugmented

-- The JSE capes, by job id: cichols_mantle (26246, WAR) ... ogmas_cape (26267, RUN), in job order
config.cape = function(job)
    return 26245 + job
end

-- pieces: { name, base id, +1 id, +2 id }. Generated from item_basic / item_equipment (jobs from the head piece).
config.sets =
{
    { name = "Sulevia's", jobs = 'WAR PLD DRK DRG', ring = 26204,
      pieces =
      {
          { 'Mask', 25659, 25660, 25574 },
          { 'Platemail', 25745, 25746, 25790 },
          { 'Gauntlets', 25800, 25801, 25828 },
          { 'Cuisses', 25858, 25859, 25879 },
          { 'Leggings', 25925, 25926, 25946 },
      },
    },
    { name = "Hizamaru", jobs = 'MNK SAM NIN PUP', ring = 26206,
      pieces =
      {
          { 'Somen', 25663, 25664, 25576 },
          { 'Haramaki', 25749, 25750, 25792 },
          { 'Kote', 25804, 25805, 25830 },
          { 'Hizayoroi', 25862, 25863, 25881 },
          { 'Sune-ate', 25929, 25930, 25948 },
      },
    },
    { name = "Inyanga", jobs = 'WHM BRD SMN', ring = 26207,
      pieces =
      {
          { 'Tiara', 25665, 25666, 25577 },
          { 'Jubbah', 25751, 25752, 25793 },
          { 'Dastanas', 25806, 25807, 25831 },
          { 'Shalwar', 25865, 25866, 25882 },
          { 'Crackows', 25931, 25932, 25949 },
      },
    },
    { name = "Meghanada", jobs = 'THF BST RNG COR DNC RUN', ring = 26205,
      pieces =
      {
          { 'Visor', 25661, 25662, 25575 },
          { 'Cuirie', 25747, 25748, 25791 },
          { 'Gloves', 25802, 25803, 25829 },
          { 'Chausses', 25860, 25861, 25880 },
          { 'Jambeaux', 25927, 25928, 25947 },
      },
    },
    { name = "Jhakri", jobs = 'BLM RDM BLU SCH GEO', ring = 26208,
      pieces =
      {
          { 'Coronal', 25667, 25668, 25578 },
          { 'Robe', 25753, 25754, 25794 },
          { 'Cuffs', 25808, 25809, 25832 },
          { 'Slops', 25867, 25868, 25883 },
          { 'Pigaches', 25933, 25934, 25950 },
      },
    },
    { name = "Flamma", jobs = 'WAR PLD DRK SAM DRG', ring = 26211,
      pieces =
      {
          { 'Zucchetto', 25579, 25580, 25569 },
          { 'Korazin', 25779, 25780, 25797 },
          { 'Manopolas', 25818, 25819, 25835 },
          { 'Dirs', 25873, 25874, 25886 },
          { 'Gambieras', 25940, 25941, 25953 },
      },
    },
    { name = "Mummu", jobs = 'MNK THF RNG NIN COR DNC', ring = 26212,
      pieces =
      {
          { 'Bonnet', 25581, 25582, 25570 },
          { 'Jacket', 25781, 25782, 25798 },
          { 'Wrists', 25820, 25821, 25836 },
          { 'Kecks', 25875, 25876, 25887 },
          { 'Gamashes', 25942, 25943, 25954 },
      },
    },
    { name = "Mallquis", jobs = 'BLM SCH GEO', ring = 26213,
      pieces =
      {
          { 'Chapeau', 25583, 25584, 25571 },
          { 'Saio', 25783, 25784, 25799 },
          { 'Cuffs', 25822, 25823, 25837 },
          { 'Trews', 25877, 25878, 25888 },
          { 'Clogs', 25944, 25945, 25955 },
      },
    },
    { name = "Ayanmo", jobs = 'WHM RDM BRD BLU RUN', ring = 26209,
      pieces =
      {
          { 'Zucchetto', 25588, 25589, 25572 },
          { 'Corazza', 25762, 25763, 25795 },
          { 'Manopolas', 25810, 25811, 25833 },
          { 'Cosciales', 25869, 25870, 25884 },
          { 'Gambieras', 25935, 25936, 25951 },
      },
    },
    { name = "Taliah", jobs = 'BST SMN PUP', ring = 26210,
      pieces =
      {
          { 'Turban', 25590, 25591, 25573 },
          { 'Manteel', 25764, 25765, 25796 },
          { 'Gages', 25812, 25813, 25834 },
          { 'Seraweels', 25871, 25872, 25885 },
          { 'Crackows', 25937, 25938, 25952 },
      },
    },
}

-- Materials and currencies, Hallmarks each (retail prices). Every one stacks to 99.
config.goods =
{
    {
        title = 'Materials',
        items =
        {
            { 'Pluton', 4059, 50 },
            { 'Beitetsu', 4060, 50 },
            { 'Riftborn Boulder', 4061, 50 },
            { 'Alexandrite', 2488, 15 },
            { 'H-P Bayld', 8798, 35 },
            { 'Heavy Metal', 3509, 200 },
            { 'Riftdross', 3498, 1500 },
            { 'Riftcinder', 3499, 1500 },
            { 'Umbral Marrow', 3502, 30000 },
            { 'Mulcibar\'s Scoria', 3503, 50000 },
        },
    },
    {
        title = 'Dynamis coins',
        items =
        {
            { 'One Byne Bill', 1455, 20 },
            { 'O. Bronzepiece', 1452, 20 },
            { 'T. Whiteshell', 1449, 20 },
            { '100 Byne Bill', 1456, 2000 },
            { 'M. Silverpiece', 1453, 2000 },
            { 'L. Jadeshell', 1450, 2000 },
        },
    },
    {
        title = 'Rem\'s Tales',
        items =
        {
            { 'Ch. 1', 4064, 100 },
            { 'Ch. 2', 4065, 100 },
            { 'Ch. 3', 4066, 100 },
            { 'Ch. 4', 4067, 100 },
            { 'Ch. 5', 4068, 100 },
            { 'Ch. 6', 4069, 300 },
            { 'Ch. 7', 4070, 300 },
            { 'Ch. 8', 4071, 300 },
            { 'Ch. 9', 4072, 300 },
            { 'Ch. 10', 4073, 300 },
        },
    },
}

config.quantities = { 1, 10, 50, 99 }

-----------------------------------
-- 2. The wave Ambuscade
-----------------------------------
-- The run: one wing of Maquette Abdhaljs-Legion B (zone 287, the same layout as the boss arena's wing in Legion A),
-- a private instance per party. The instance_list row: modules/custom/sql/ambuscade_waves.sql.
config.instance =
{
    zoneId       = xi.zone.MAQUETTE_ABDHALJS_LEGION_B,
    instanceId   = 30100,
    entry        = { 142.0, 12.0, -142.0, 32 },
    tome         = { name = 'AMB_Tome', packetName = 'Ambuscade Tome', look = 2290, pos = { 137.0, 12.0, -146.0, 32 } },
    spawn        = { 162.0, 12.0, -162.0, 160 }, -- the middle of the pack; mobs stand around it
    spread       = 4,   -- yalms from the middle
    waveDelay    = 10,  -- seconds between a wave falling and the next arriving (the first: after entering)
    wipeSeconds  = 120, -- everyone inside KO'd this long: the run fails
    emptySeconds = 30,  -- nobody inside this long: the instance closes
}

-- The four lengths. Claude's proposal for the rewards (Eric asked for help deciding): every player inside gets them on
-- a clear, solo or in a party. Scale: retail Intense VD pays 3,600 Hallmarks for one boss; a 3-wave run is about that
-- long, and the longer runs pay more per wave. Gallantry is a tenth (it pays for the +1 upgrades: 300-1,800 a piece).
-- A failed run (time up, wipe) pays half of the Hallmarks for the share of waves cleared, and no Gallantry.
config.runs =
{
    { waves = 3,  minutes = 15, hallmarks = 1500, gallantry = 150 },
    { waves = 5,  minutes = 20, hallmarks = 3000, gallantry = 300 },
    { waves = 7,  minutes = 30, hallmarks = 5000, gallantry = 500 },
    { waves = 10, minutes = 40, hallmarks = 8000, gallantry = 800 },
}

-- The monsters: the retail Legion beasts of Maquette Abdhaljs-Legion B (mob_groups in zone 287, so no SQL needed),
-- in their retail order of strength: Lofty, Mired, Soaring, Veiled, then a Paramount boss. Each regular wave is a pack
-- drawn from one stage; the stages are spread over the run (a 3-wave run: Mired, Veiled, boss; 10 waves: Lofty x2,
-- Mired x2, Soaring x2, Veiled x3, boss). Left out: Varanus and Veiled Gigaworm (no TP moves), Paramount Mantis and
-- Paramount Gallu (odd model data). Entries: { group id, name }.
config.stages =
{
    {
        name   = 'Lofty',
        groups =
        {
            { 1, 'Lofty Behemoth' }, { 2, 'Lofty Wyrm' }, { 3, 'Lofty Adamantoise' }, { 4, 'Lofty Elasmoth' },
            { 5, 'Lofty Zilant' }, { 6, 'Lofty Ferromantoise' }, { 7, 'Lofty Harpeia' },
        },
    },
    {
        name   = 'Mired',
        groups =
        {
            { 9, 'Mired Cerberus' }, { 10, 'Mired Khimaira' }, { 11, 'Mired Hydra' }, { 12, 'Mired Orthrus' },
            { 13, 'Mired Khrysokhimaira' }, { 14, 'Mired Alfard' }, { 15, 'Mired Mantis' },
        },
    },
    {
        name   = 'Soaring',
        groups =
        {
            { 16, 'Soaring Corse' }, { 17, 'Soaring Dvergr' }, { 18, 'Soaring Vampyr' }, { 19, 'Soaring Kumakatok' },
            { 20, 'Soaring Dweorg' }, { 21, 'Soaring Strigoi' }, { 22, 'Soaring Naraka' },
        },
    },
    {
        name   = 'Veiled',
        groups =
        {
            { 23, 'Veiled Amphiptere' }, { 24, 'Veiled Ixion' }, { 25, 'Veiled Sandworm' },
            { 26, 'Veiled Sanguiptere' }, { 27, 'Veiled Alicorn' }, { 29, 'Veiled Ironclad' },
        },
    },
}

config.bosses = { { 30, 'Paramount Naraka' }, { 31, 'Paramount Harpeia' }, { 33, 'Paramount Ironclad' }, { 35, 'Paramount Botulus' } }

-- Each regular wave's strength runs from `first` (wave 1) to `last` (the wave before the boss), straight line.
-- Floors: final combat stats at least these (htbf_arena.lua applyFloors); `last` is the boss arena's Tier 1 floors.
config.waveScale =
{
    first = { level = 110, hp = 12000, matt = 25, macc = 25,  acc = 800, att = 850,  def = 700, eva = 700, meva = 650, mdb = 30 },
    last  = { level = 125, hp = 40000, matt = 50, macc = 100, acc = 950, att = 1050, def = 850, eva = 850, meva = 750, mdb = 60 },
}

-- Monsters per regular wave: 3 in the first half of the run, 4 in the second; one more with 4+ players inside, one
-- more again with 7+ (an alliance). Trusts don't count.
config.pack = function(wave, regularWaves, players)
    local count = wave > regularWaves / 2 and 4 or 3

    if players >= 4 then
        count = count + 1
    end

    if players >= 7 then
        count = count + 1
    end

    return count
end

-- The last wave: one boss, the boss arena's Tier 2 numbers (level 128). Sleep, petrify and terror don't land on it.
config.boss = { level = 128, hp = 300000, matt = 75, macc = 150, stat = 60, acc = 975, att = 1100, def = 900, eva = 875, meva = 775, mdb = 90 }

-- TP moves: once TP passes a goal rolled in this range, the monster uses one (as in the boss arena)
config.tpUse = { min = 1000, max = 1500 }

return config
