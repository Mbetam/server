-----------------------------------
-- JSE weapon progression: the three Magian Moogles in Ru'Lude Gardens upgrade their family's weapon base -> 85 -> 95
-- -> 99 (green pom Relic, orange pom Mythic, blue pom Empyrean; jse_config.lua). Trade the player's active weapon with
-- the full material set; a weapon alone gets the list. Their retail Magian Trial dialogue and trades are gone (Eric,
-- 2026-09-29): talking gives the JSE instructions (every stage, its materials and which NM drops them), and any other
-- trade gets a short explanation.
-- Nothing is taken unless the trade is exactly right; if the new weapon cannot be given, everything comes back.
-----------------------------------
require('modules/module_utils')
local config   = require('modules/custom/jse_progression/jse_config')
local progress = require('modules/custom/jse_progression/jse_progress')
-----------------------------------

local m = Module:new('jse_moogles')

local moogles = {}

local familyByMoogle = {}
local colour = { relic = 'green', mythic = 'orange', empyrean = 'blue' }

for familyKey, family in pairs(config.families) do
    familyByMoogle[family.moogle] = familyKey
end

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, 'Magian Moogle')
end

local function itemName(itemId)
    local item = GetReadOnlyItem(itemId)
    local name = item and item:getName() or tostring(itemId)

    -- 'vial_of_fistule_discharge' -> 'Vial Of Fistule Discharge' reads badly; keep small words small
    name = name:gsub('_', ' '):gsub('(%a)([%w%-]*)', function(first, rest) return first:upper() .. rest end)

    return (name:gsub(' Of ', ' of '))
end

-- Where each material drops: item id -> 'NM (Zone)', from the drop table in jse_config.lua
local zoneNames =
{
    [xi.zone.ABYSSEA_LA_THEINE]  = 'La Theine',  [xi.zone.ABYSSEA_TAHRONGI]   = 'Tahrongi', [xi.zone.ABYSSEA_KONSCHTAT] = 'Konschtat',
    [xi.zone.ABYSSEA_VUNKERL]    = 'Vunkerl',    [xi.zone.ABYSSEA_MISAREAUX]  = 'Misareaux', [xi.zone.ABYSSEA_ATTOHWA]  = 'Attohwa',
    [xi.zone.ABYSSEA_ALTEPA]     = 'Altepa',     [xi.zone.ABYSSEA_ULEGUERAND] = 'Uleguerand', [xi.zone.ABYSSEA_GRAUBERG] = 'Grauberg',
}

local source = {}

for zoneId, nms in pairs(config.drops) do
    for nm, drop in pairs(nms) do
        source[drop[1]] = string.format('%s, %s', nm:gsub('_', ' '), zoneNames[zoneId])
    end
end

local function describe(list)
    local parts = {}

    for _, material in ipairs(list) do
        table.insert(parts, string.format('%d %s', material[2], itemName(material[1])))
    end

    return table.concat(parts, ', ')
end

-- Handles a trade holding a JSE weapon. Returns false when the trade has none (so retail handles it).
moogles.onTrade = function(player, npc, trade)
    local weapon, entry = nil, nil
    local others        = {}

    for slot = 0, 7 do
        local item = trade:getItem(slot)

        if item ~= nil then
            local found = progress.lookup(item:getID())

            if found and weapon == nil then
                weapon, entry = item, found
            else
                others[item:getID()] = (others[item:getID()] or 0) + trade:getSlotQty(slot)
            end
        end
    end

    if weapon == nil then
        return false
    end

    local family = config.families[entry.family]

    if family.moogle ~= npc:getID() then
        say(player, string.format('I only work on %s weapons. Take that one to the Magian Moogle with the %s pom.', config.families[familyByMoogle[npc:getID()]].name, colour[entry.family]))

        return true
    end

    if progress.getActive(player) ~= entry.weapon.base then
        say(player, 'I only upgrade the weapon you are working on now (the one you bought from the Splintery Chest).')

        return true
    end

    local stage, materials, nextId = progress.moogleStep(weapon:getID())

    if stage == nil then
        say(player, 'That weapon is past what I can do. Oboro takes it from 99 to 119.')

        return true
    end

    -- Exactly the materials, nothing else
    local missing, extra = {}, {}

    for _, material in ipairs(materials) do
        local have = others[material[1]] or 0

        if have < material[2] then
            table.insert(missing, { material[1], material[2] - have })
        elseif have > material[2] then
            table.insert(extra, string.format('%d %s', have - material[2], itemName(material[1])))
        end

        others[material[1]] = nil
    end

    for itemId, quantity in pairs(others) do
        table.insert(extra, string.format('%d %s', quantity, itemName(itemId)))
    end

    if next(others) == nil and #missing == #materials and #extra == 0 then
        say(player, string.format('To upgrade %s I need: %s.', itemName(weapon:getID()), describe(materials)))

        return true
    end

    if #missing > 0 then
        say(player, 'Still missing: ' .. describe(missing) .. '.')

        return true
    end

    if #extra > 0 then
        say(player, 'I do not need these: ' .. table.concat(extra, ', ') .. '. Trade me only the weapon and its materials.')

        return true
    end

    local oldId = weapon:getID()
    player:tradeComplete()

    if not player:addItem(nextId) then
        player:addItem(oldId)

        for _, material in ipairs(materials) do
            player:addItem({ id = material[1], quantity = material[2], silent = true })
        end

        say(player, 'I could not hand you the new weapon, so you have everything back.')

        return true
    end

    player:messageSpecial(zones[player:getZoneID()].text.ITEM_OBTAINED, nextId)

    if stage == 3 and entry.weapon.done99 then
        progress.finish(player, nextId)
        say(player, string.format('%s is complete. You can start your next weapon at the Splintery Chest.', entry.weapon.name))
    elseif stage == 3 then
        say(player, string.format('%s is at 99. Oboro, by the Splintery Chest, takes it to 119.', entry.weapon.name))
    end

    return true
end

-- What talking to the moogle shows: every stage of its family and where each material drops
moogles.instructions = function(player, npc)
    local familyKey = familyByMoogle[npc:getID()]
    local family    = config.families[familyKey]
    local labels    = { 'base -> 85', '85 -> 95', '95 -> 99' }

    say(player, string.format('I upgrade %s weapons from the Splintery Chest (500,000 gil) one stage at a time, up to 99.', family.name))
    say(player, 'Trade me your weapon together with 5 of each material for its stage. The weapon alone shows what it needs.')

    for stage, materials in ipairs(family.stages) do
        local parts = {}

        for _, material in ipairs(materials) do
            table.insert(parts, string.format('%d %s (%s)', material[2], itemName(material[1]), source[material[1]] or '?'))
        end

        say(player, string.format('%s: %s', labels[stage], table.concat(parts, ', ')))
    end

    say(player, 'At 99, Oboro next to the Splintery Chest takes it to 119 and 119 III.')
end

for _, script in ipairs({ 'Magian_Moogle_Green', 'Magian_Moogle_Orange', 'Magian_Moogle_Blue' }) do
    require(string.format('scripts/zones/RuLude_Gardens/npcs/%s', script))

    m:addOverride(string.format('xi.zones.RuLude_Gardens.npcs.%s.onTrade', script), function(player, npc, trade)
        if not moogles.onTrade(player, npc, trade) then
            local family = config.families[familyByMoogle[npc:getID()]]
            say(player, string.format('I only upgrade %s weapons. Trade me the weapon you are working on, with its materials.', family.name))
        end
    end)

    m:addOverride(string.format('xi.zones.RuLude_Gardens.npcs.%s.onTrigger', script), function(player, npc)
        moogles.instructions(player, npc)
    end)
end

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.jseMoogles = moogles -- for tests

return m
