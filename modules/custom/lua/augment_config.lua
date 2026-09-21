-----------------------------------
-- Augment system settings: the ONE file to edit when tuning augments.
-- Read by modules/custom/lua/augment_core.lua. This is a helper file, not a module: it registers nothing.
--
-- Stats and their augment ids are the game's own retail augment table (the `augments` SQL table). The client draws
-- augment text from its own data by id, so only retail ids display correctly. Do not invent ids.
-- An augment stores an id plus a value of 0-31, and the bonus is (base + value), so `base` below is what a stored
-- value of 0 gives. `ranges` lists the ids that can hold this stat, with the base of each (HP and MP use one id per
-- 32 points).
-----------------------------------

return
{
    slotsPerItem = 4, -- the engine allows 5

    -- How many times the SAME stat may be on one item: 1 = each stat once, 4 = the same augment in every slot.
    -- Every copy counts (two Dual Wield +2 augments give Dual Wield +4). Stats add up across all worn gear too,
    -- and the game only caps a few of them (gear Haste 25%, Fast Cast 50, Cure Potency 50%).
    maxPerStat = 4,

    -- What the Augmenter NPC looks like: a model id from docs/model_ids.txt. 82 is the Moogle, the same model the game's own
    -- Moogle NPCs use. Do NOT use 50: that model is a blank placeholder (the Auction Counters use it) and the NPC is invisible.
    npcModel = 82,

    -- Tiers unlock with the player's MAIN job level. `price` is what one augment costs at that tier.
    -- If two tiers give the same bonus for a stat, the LOWER tier's level and price apply.
    tiers =
    {
        { minLevel =  1, price =    10000 },
        { minLevel = 30, price =    50000 },
        { minLevel = 60, price =   250000 },
        { minLevel = 90, price =  1000000 },
    },

    -- Removing an augment costs this much times the tier it belongs to.
    removalPricePerTier = 5000,

    -- key:          short name used in code
    -- name:         what players see
    -- unit:         shown after the number ('%' or '')
    -- mod:          the xi.mod the augment changes (used by the engine tests)
    -- modPerPoint:  how many mod units one displayed point is (gear Haste is stored in hundredths of a percent)
    -- amounts:      the bonus at tier 1, 2, 3 and 4
    -- ranges:       { id = retail augment id, base = bonus given by a stored value of 0 }
    stats =
    {
        { key = 'dual_wield',     name = 'Dual Wield',          unit = '',  mod = 'DUAL_WIELD',    modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 146, base = 1 } } },
        { key = 'double_attack',  name = 'Double Attack',       unit = '%', mod = 'DOUBLE_ATTACK', modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 143, base = 1 } } },
        { key = 'triple_attack',  name = 'Triple Attack',       unit = '%', mod = 'TRIPLE_ATTACK', modPerPoint = 1,   amounts = {  1,  1,  2,  2 }, ranges = { { id = 144, base = 1 } } },
        { key = 'crit_rate',      name = 'Critical Hit Rate',   unit = '%', mod = 'CRITHITRATE',   modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id =  41, base = 1 } } },
        { key = 'store_tp',       name = 'Store TP',            unit = '',  mod = 'STORETP',       modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 142, base = 1 } } },
        { key = 'gear_haste',     name = 'Haste (gear)',        unit = '%', mod = 'HASTE_GEAR',    modPerPoint = 100, amounts = {  1,  1,  2,  2 }, ranges = { { id =  49, base = 1 } } },
        { key = 'fast_cast',      name = 'Fast Cast',           unit = '%', mod = 'FASTCAST',      modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 140, base = 1 } } },
        { key = 'accuracy',       name = 'Accuracy',            unit = '',  mod = 'ACC',           modPerPoint = 1,   amounts = {  5, 10, 15, 20 }, ranges = { { id =  23, base = 1 } } },
        { key = 'attack',         name = 'Attack',              unit = '',  mod = 'ATT',           modPerPoint = 1,   amounts = {  5, 10, 15, 20 }, ranges = { { id =  25, base = 1 } } },
        { key = 'magic_accuracy', name = 'Magic Accuracy',      unit = '',  mod = 'MACC',          modPerPoint = 1,   amounts = {  5, 10, 15, 20 }, ranges = { { id =  35, base = 1 } } },
        { key = 'magic_attack',   name = 'Magic Attack Bonus',  unit = '',  mod = 'MATT',          modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 133, base = 1 } } },
        { key = 'hp',             name = 'HP',                  unit = '',  mod = 'HP',            modPerPoint = 1,   amounts = { 20, 40, 60, 80 }, ranges = { { id = 1, base = 1 }, { id = 2, base = 33 }, { id = 3, base = 65 }, { id = 4, base = 97 } } },
        { key = 'mp',             name = 'MP',                  unit = '',  mod = 'MP',            modPerPoint = 1,   amounts = { 20, 40, 60, 80 }, ranges = { { id = 9, base = 1 }, { id = 10, base = 33 }, { id = 11, base = 65 }, { id = 12, base = 97 } } },
        { key = 'refresh',        name = 'Refresh (MP/tick)',   unit = '',  mod = 'REFRESH',       modPerPoint = 1,   amounts = {  1,  1,  2,  2 }, ranges = { { id = 138, base = 1 } } },
        { key = 'regen',          name = 'Regen (HP/tick)',     unit = '',  mod = 'REGEN',         modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 137, base = 1 } } },
        { key = 'cure_potency',   name = 'Cure Potency',        unit = '%', mod = 'CURE_POTENCY',  modPerPoint = 1,   amounts = {  1,  2,  3,  4 }, ranges = { { id = 329, base = 1 } } },
    },
}
