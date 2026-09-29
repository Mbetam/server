-----------------------------------
-- JSE weapon progression: lookups and the player's progress (character variables). Not a module (loaded by require):
-- the Splintery Chest, the Magian Moogles and Oboro use it.
-- JSE_ACTIVE_WEAPON holds the base item id of the one weapon in progress (0 = none); JSE_<FAMILY>_DONE is set when a
-- weapon of that family is finished (119 III at Oboro, or 99 for the weapons with no 119 version).
-----------------------------------
local config = require('modules/custom/jse_progression/jse_config')
local oboro  = require('modules/custom/lua/oboro_config')
-----------------------------------

local progress = {}

-- itemId -> { family, weapon, stage } with stage 0 = base, 85, 95, 99, 119 (119 / 119 II), 1193 (119 III)
local byItem = {}
-- base item id -> { family, weapon }
local byBase = {}

-- 99 item id -> the Oboro chain of that weapon
local oboroBy99 = {}

for _, chains in pairs(oboro.chains) do
    for _, chain in ipairs(chains) do
        for _, id in ipairs(chain.base) do
            oboroBy99[id] = chain
        end
    end
end

for familyKey, family in pairs(config.families) do
    for _, weapon in ipairs(family.weapons) do
        local entry = { family = familyKey, weapon = weapon }

        byBase[weapon.base] = entry
        byItem[weapon.s99]  = { family = familyKey, weapon = weapon, stage = 99 }
        byItem[weapon.s95]  = { family = familyKey, weapon = weapon, stage = 95 }
        byItem[weapon.s85]  = { family = familyKey, weapon = weapon, stage = 85 }

        if weapon.base ~= weapon.s85 then
            byItem[weapon.base] = { family = familyKey, weapon = weapon, stage = 0 }
        end

        local chain = oboroBy99[weapon.s99]
        weapon.oboro = chain

        if chain then
            byItem[chain.s119] = { family = familyKey, weapon = weapon, stage = 119 }

            if chain.s119ii then
                byItem[chain.s119ii] = { family = familyKey, weapon = weapon, stage = 119 }
            end

            byItem[chain.s119iii] = { family = familyKey, weapon = weapon, stage = 1193 }
        end
    end
end

progress.lookup = function(itemId)
    return byItem[itemId]
end

progress.byBase = function(baseId)
    return byBase[baseId]
end

-- The moogle step for a weapon item: stage index (1-3), materials, next item id; nil when not a moogle step
progress.moogleStep = function(itemId)
    local entry = byItem[itemId]

    if entry == nil then
        return nil
    end

    local weapon = entry.weapon
    local family = config.families[entry.family]

    if entry.stage == 0 then
        return 1, family.stages[1], weapon.s85
    elseif entry.stage == 85 then
        return 2, family.stages[2], weapon.s95
    elseif entry.stage == 95 then
        return 3, family.stages[3], weapon.s99
    end

    return nil
end

-----------------------------------
-- Player progress
-----------------------------------

progress.getActive = function(player)
    return player:getCharVar(config.var.active)
end

progress.setActive = function(player, baseId)
    player:setCharVar(config.var.active, baseId)
end

progress.clearActive = function(player)
    player:setCharVar(config.var.active, 0)
end

progress.isDone = function(player, familyKey)
    return player:getCharVar(config.var.done[familyKey]) == 1
end

progress.setDone = function(player, familyKey)
    player:setCharVar(config.var.done[familyKey], 1)
end

-- Every item id of a weapon, base to 119 III
progress.stages = function(weapon)
    local ids = { weapon.base, weapon.s85, weapon.s95, weapon.s99 }

    if weapon.oboro then
        table.insert(ids, weapon.oboro.s119)
        table.insert(ids, weapon.oboro.s119ii)
        table.insert(ids, weapon.oboro.s119iii)
    end

    return ids
end

-- Does the player still hold their active weapon (any stage below 119 III, in any container)?
progress.holdsActive = function(player)
    local entry = byBase[progress.getActive(player)]

    if entry == nil then
        return false
    end

    for _, id in ipairs(progress.stages(entry.weapon)) do
        if id and id ~= (entry.weapon.oboro and entry.weapon.oboro.s119iii) and player:hasItem(id) then
            return true
        end
    end

    return false
end

-- A weapon was finished (Oboro 119 III, or 99 for weapons with no 119): the family counts as done, and the active
-- slot clears if it was this weapon
progress.finish = function(player, itemId)
    local entry = byItem[itemId]

    if entry == nil then
        return
    end

    progress.setDone(player, entry.family)

    if progress.getActive(player) == entry.weapon.base then
        progress.clearActive(player)
    end
end

return progress
