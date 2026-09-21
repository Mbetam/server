-----------------------------------
-- Augment rules for the Augmenter.
-- Pure logic: no NPC, no menus, no changes to the game. Everything takes plain values and returns plain values, so it can
-- be tested on its own. Numbers live in augment_config.lua.
-- This is a helper file, not a module: it registers nothing and is only loaded when another file requires it.
--
-- An "augment list" is an array of { id = <retail augment id>, value = <0-31> }, one entry per used slot, no gaps.
-----------------------------------
local config = require('modules/custom/lua/augment_config')
-----------------------------------

local core = {}

core.config = config

local maxStoredValue = 31 -- an augment's value is stored in 5 bits

local statsByKey = {}
local rangeById  = {} -- augment id -> { stat = <stat row>, base = <bonus at stored value 0> }

for _, stat in ipairs(config.stats) do
    statsByKey[stat.key] = stat

    for _, range in ipairs(stat.ranges) do
        rangeById[range.id] = { stat = stat, base = range.base }
    end
end

-----------------------------------
-- Stats and tiers
-----------------------------------

core.stat = function(key)
    return statsByKey[key]
end

-- The highest tier the player's main job level has unlocked (0 if none).
core.tierForLevel = function(level)
    local best = 0

    for tier, data in ipairs(config.tiers) do
        if level >= data.minLevel then
            best = tier
        end
    end

    return best
end

-- If a lower tier already gives the same bonus, that lower tier is what counts (its level and its price).
core.effectiveTier = function(key, tier)
    local stat   = statsByKey[key]
    local amount = stat and stat.amounts[tier]

    if amount == nil then
        return nil
    end

    for lower = 1, tier do
        if stat.amounts[lower] == amount then
            return lower
        end
    end

    return tier
end

core.price = function(tier)
    return config.tiers[tier] and config.tiers[tier].price
end

-----------------------------------
-- Turning a stat and tier into a stored augment, and back
-----------------------------------

-- Returns augment id, stored value, bonus. On failure returns nil and the reason.
core.encode = function(key, tier)
    local stat = statsByKey[key]
    if stat == nil then
        return nil, 'unknown stat'
    end

    local amount = stat.amounts[tier]
    if amount == nil then
        return nil, 'unknown tier'
    end

    -- Use the id whose base is closest below the bonus, so the stored value stays as small as possible
    local chosen = nil

    for _, range in ipairs(stat.ranges) do
        if range.base <= amount and (chosen == nil or range.base > chosen.base) then
            chosen = range
        end
    end

    if chosen == nil or amount - chosen.base > maxStoredValue then
        return nil, 'no augment id can hold this bonus'
    end

    return chosen.id, amount - chosen.base, amount
end

-- Returns stat key, bonus and tier. The tier is nil when the bonus is not one the catalog hands out.
-- Returns nil when the id is not a catalog stat at all.
core.decode = function(id, value)
    local found = rangeById[id]
    if found == nil then
        return nil
    end

    local amount = found.base + value
    local tier   = nil

    for candidate, catalogAmount in ipairs(found.stat.amounts) do
        if catalogAmount == amount then
            tier = candidate
            break
        end
    end

    return found.stat.key, amount, tier
end

-----------------------------------
-- Working with the augments on an item
-----------------------------------

-- Copies a list of augments so callers can never change the original by accident.
local function copyList(augments)
    local copy = {}

    for _, augment in ipairs(augments) do
        table.insert(copy, { id = augment.id, value = augment.value })
    end

    return copy
end

-- Can this stat be added to an item with these augments by a player with this level and gil?
-- ctx = { level, gil, augments, key, tier }
-- Returns true and { price, tier, id, value, amount }, or false and a message for the player.
core.checkAdd = function(ctx)
    if statsByKey[ctx.key] == nil then
        return false, 'That stat is not available.'
    end

    local tier = core.effectiveTier(ctx.key, ctx.tier)
    if tier == nil then
        return false, 'That tier does not exist.'
    end

    if ctx.level < config.tiers[tier].minLevel then
        return false, string.format('Tier %d unlocks at level %d.', tier, config.tiers[tier].minLevel)
    end

    if #ctx.augments >= config.slotsPerItem then
        return false, 'This item has no free augment slot.'
    end

    for _, augment in ipairs(ctx.augments) do
        if core.decode(augment.id, augment.value) == ctx.key then
            return false, 'This item already has that stat.'
        end
    end

    local price = core.price(tier)
    if ctx.gil < price then
        return false, string.format('That costs %d gil.', price)
    end

    local id, value, amount = core.encode(ctx.key, ctx.tier)
    if id == nil then
        return false, 'That augment cannot be made.'
    end

    return true, { price = price, tier = tier, id = id, value = value, amount = amount }
end

-- Can the augment in this slot (1-based) be removed?
-- ctx = { gil, augments, slot }
-- Returns true and { price, tier, key, amount }, or false and a message for the player.
core.checkRemove = function(ctx)
    local augment = ctx.augments[ctx.slot]
    if augment == nil then
        return false, 'There is no augment in that slot.'
    end

    local key, amount, tier = core.decode(augment.id, augment.value)
    if key == nil or tier == nil then
        return false, 'That augment cannot be removed here.'
    end

    local price = config.removalPricePerTier * tier
    if ctx.gil < price then
        return false, string.format('That costs %d gil.', price)
    end

    return true, { price = price, tier = tier, key = key, amount = amount }
end

-- The list after adding an augment, and the list after removing the one in a slot. Neither changes its input.
core.withAdded = function(augments, id, value)
    local list = copyList(augments)
    table.insert(list, { id = id, value = value })

    return list
end

core.withRemoved = function(augments, slot)
    local list = copyList(augments)
    table.remove(list, slot)

    return list
end

-- The exdata table to hand to player:addItem so the new item carries these augments.
-- Returns nil for an empty list: an item with no augments should be a plain item.
core.buildExdata = function(augments)
    if #augments == 0 then
        return nil
    end

    return
    {
        augmentKind    = xi.augment.kind.HAS_AUGMENTS,
        augmentSubKind = xi.augment.subKind.STANDARD,
        augments       = copyList(augments),
    }
end

-- What the Augmenter shows for each augment on an item.
core.describe = function(augments)
    local lines = {}

    for slot, augment in ipairs(augments) do
        local key, amount = core.decode(augment.id, augment.value)
        local stat        = key and statsByKey[key]

        table.insert(lines, { slot = slot, name = stat and stat.name or 'Unknown', amount = amount, unit = stat and stat.unit or '' })
    end

    return lines
end

-----------------------------------
-- Reading a real item
-----------------------------------

-- Returns the item's augment list if the Augmenter may work on it, or nil and the reason it may not.
-- Only weapons and armor with no augments, or with augments this system made, are accepted. Anything else (Magian trials,
-- Ambuscade and Odyssey gear, crafting shields, serialized or signed items, items with charges) is left alone.
core.readItem = function(item)
    if not (item:isType(xi.itemType.ARMOR) or item:isType(xi.itemType.WEAPON)) then
        return nil, 'Only weapons and armor can be augmented.'
    end

    local exdata   = item:getExData()
    local augments = {}

    if exdata.augments == nil then
        -- Not augment data at all: only a completely blank item is fine
        for _, byte in pairs(exdata) do
            if byte ~= 0 then
                return nil, 'This item carries other data and cannot be augmented.'
            end
        end

        return augments
    end

    local used = 0

    for slot, augment in ipairs(exdata.augments) do
        if augment.id ~= 0 then
            used = used + 1

            if slot > config.slotsPerItem then
                return nil, 'This item already carries more augments than can be changed here.'
            end

            local key, _, tier = core.decode(augment.id, augment.value)
            if key == nil or tier == nil then
                return nil, 'This item carries augments that cannot be changed here.'
            end

            table.insert(augments, { id = augment.id, value = augment.value })
        end
    end

    local blank = (used == 0)

    if not blank then
        if exdata.augmentKind ~= xi.augment.kind.HAS_AUGMENTS or exdata.augmentSubKind ~= xi.augment.subKind.STANDARD then
            return nil, 'This item carries augments that cannot be changed here.'
        end
    elseif (exdata.augmentKind or 0) ~= 0 and exdata.augmentKind ~= xi.augment.kind.HAS_AUGMENTS then
        return nil, 'This item carries other data and cannot be augmented.'
    end

    if exdata.signature ~= nil and exdata.signature ~= '' then
        return nil, 'Signed items cannot be augmented.'
    end

    return augments
end

return core
