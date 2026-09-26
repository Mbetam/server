-----------------------------------
-- Armor Upgrader conversation: trade one Artifact, Relic or Empyrean armor piece with the retail materials of its next
-- step, confirm, get the next tier. Trading the piece alone lists what the next step needs.
-- Not a module (loaded by require). The chains and gil costs are in af_upgrade_config.lua, the materials in
-- af_upgrade_materials.lua. The +4 tiers are left out for now (Eric, 2026-09-26: they come with the hunt system).
-- Augments the Augmenter put on the piece carry over to the upgraded piece. Pieces carrying other data are refused.
-- Everything is checked again when the player says Yes. The materials and gil are taken first, then the original piece,
-- and the new piece is made last (AF is Rare: it can't be held twice); if anything fails, everything taken comes back.
-----------------------------------
local config    = require('modules/custom/lua/af_upgrade_config')
local materials = require('modules/custom/lua/af_upgrade_materials')
local core      = require('modules/custom/lua/augment_core')
-----------------------------------

local flow = {}

local npcName  = 'Armor Upgrader'
local sessions = {} -- one pending upgrade per player: { itemId, nextId, container, slot, augments, gil, takes }

-- Step key of each tier, by its place in the old set and in the Reforged set
local oldKeys      = { nil, 'oldPlus1', 'oldPlus2' }
local reforgedKeys = { 'reforged', 'reforgedPlus1', 'reforgedPlus2', 'reforgedPlus3', 'reforgedPlus4' }

-- itemId -> { next = next item id or nil, step = the step key of the next item, family = 'af' / 'relic' / 'empyrean' }
local byItem = {}

for family, jobs in pairs(config.chains) do
    for _, slots in pairs(jobs) do
        for _, chain in ipairs(slots) do
            local ids, keys = {}, {}

            for index, itemId in ipairs(chain.base) do
                table.insert(ids, itemId)
                table.insert(keys, oldKeys[index] or false)
            end

            for index, itemId in ipairs(chain.reforged) do
                table.insert(ids, itemId)
                table.insert(keys, reforgedKeys[index])
            end

            for index, itemId in ipairs(ids) do
                local step = keys[index + 1]

                if step == 'reforgedPlus4' then
                    byItem[itemId] = { family = family } -- +3 is the top for now
                else
                    byItem[itemId] = { next = ids[index + 1], step = step, family = family }
                end
            end
        end
    end
end

flow.lookup = function(itemId)
    return byItem[itemId]
end

-- The materials of the step that makes itemId: { { id, quantity }, ... }
flow.materialsFor = function(itemId)
    local flat = materials[itemId]

    if flat == nil then
        return nil
    end

    local list = {}

    for index = 1, #flat, 2 do
        table.insert(list, { id = flat[index], quantity = flat[index + 1] })
    end

    return list
end

-- Gil the step costs on top of its materials (Reforged Empyrean +2 / +3: Gallimaufry in retail)
flow.gilFor = function(entry)
    local family = config.gil[entry.family]

    return family and family[entry.step] or 0
end

local function formatGil(amount)
    local text = tostring(math.floor(amount))

    while true do
        local replaced, count = text:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        text = replaced

        if count == 0 then
            break
        end
    end

    return text
end

-- 'pummelers_lorica_+1' -> 'Pummelers Lorica +1'
local function displayName(itemId)
    local item = GetReadOnlyItem(itemId)
    local name = item and item:getName() or tostring(itemId)

    return (name:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest) return first:upper() .. rest end))
end

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, npcName)
end

-- "8 Rem's Tale Ch.6, 1 Voidwrought Plate and 50,000 gil"
local function describe(list, gil)
    local parts = {}

    for _, material in ipairs(list) do
        table.insert(parts, string.format('%d %s', material.quantity, displayName(material.id)))
    end

    if gil > 0 then
        table.insert(parts, formatGil(gil) .. ' gil')
    end

    if #parts == 1 then
        return parts[1]
    end

    return table.concat(parts, ', ', 1, #parts - 1) .. ' and ' .. parts[#parts]
end

-- The menu is sent a moment later so the previous menu is fully closed first
local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- For tests only (see augmenter_flow.lua): a test process that exits with a real menu open crashes
flow.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

flow.finish = function(player)
    sessions[player:getID()] = nil
end

-- Puts back what commit() took so far
local function refund(player, session, taken, gilTaken)
    for _, take in ipairs(taken) do
        player:addItem({ id = take.id, quantity = take.quantity, silent = true })
    end

    if gilTaken then
        player:addGil(session.gil)
    end
end

-- Does the upgrade after checking everything again. Returns true, or false and a reason.
flow.commit = function(player)
    local session = sessions[player:getID()]
    flow.finish(player)

    if session == nil then
        return false, 'Trade me the piece and its materials first.'
    end

    local item = player:getStorageItem(session.container, session.slot, 255)
    if item == nil or item:getID() ~= session.itemId then
        return false, 'That piece is no longer where you left it, so nothing was changed.'
    end

    for _, take in ipairs(session.takes) do
        local stack = player:getStorageItem(take.container, take.slot, 255)

        if stack == nil or stack:getID() ~= take.id or stack:getQuantity() < take.quantity then
            return false, 'Some of the materials are no longer where you left them, so nothing was changed.'
        end
    end

    if player:getGil() < session.gil then
        return false, string.format('This step also costs %s gil. You do not have enough.', formatGil(session.gil))
    end

    local taken = {}

    for _, take in ipairs(session.takes) do
        if not player:delItemAt(take.id, take.quantity, take.container, take.slot) then
            refund(player, session, taken, false)

            return false, 'I could not take your materials, so nothing was changed.'
        end

        table.insert(taken, take)
    end

    if session.gil > 0 and not player:delGil(session.gil) then
        refund(player, session, taken, false)

        return false, 'I could not take the gil, so nothing was changed.'
    end

    if not player:delItemAt(session.itemId, 1, session.container, session.slot) then
        refund(player, session, taken, true)

        return false, 'I could not take your piece, so nothing was changed.'
    end

    local added = player:addItem({ id = session.nextId, exdata = core.buildExdata(session.augments), silent = true })
    if added == nil then
        player:addItem({ id = session.itemId, exdata = core.buildExdata(session.augments), silent = true })
        refund(player, session, taken, true)

        return false, 'I could not make the new piece, so you have your original and your materials back.'
    end

    return true
end

-- What was traded: the one armor piece (if any) and every other slot
local function readTrade(trade)
    local piece, others = nil, {}

    for slot = 0, 7 do
        local item = trade:getItem(slot)

        if item ~= nil then
            local quantity = trade:getSlotQty(slot)

            if piece == nil and byItem[item:getID()] ~= nil then
                piece = item
            else
                table.insert(others, { item = item, quantity = quantity })
            end
        end
    end

    return piece, others
end

-- Matches the traded slots against the list. Returns the slots to take from, or nil and a reason.
local function planTakes(list, others)
    local need = {}

    for _, material in ipairs(list) do
        need[material.id] = (need[material.id] or 0) + material.quantity
    end

    local takes = {}

    for _, other in ipairs(others) do
        local id = other.item:getID()

        if need[id] == nil then
            return nil, string.format('%s is not needed for this step. Trade me only the piece and its materials.', displayName(id))
        end

        local quantity = math.min(need[id], other.quantity)

        if quantity > 0 then
            table.insert(takes, { id = id, quantity = quantity, container = other.item:getLocationID(), slot = other.item:getSlotID() })
            need[id] = need[id] - quantity
        end
    end

    local missing = {}

    for _, material in ipairs(list) do
        if need[material.id] > 0 then
            table.insert(missing, { id = material.id, quantity = need[material.id] })
            need[material.id] = 0
        end
    end

    if #missing > 0 then
        return nil, 'Still missing: ' .. describe(missing, 0) .. '.'
    end

    return takes
end

flow.onTrade = function(player, npc, trade)
    local piece, others = readTrade(trade)

    if trade:getGil() > 0 or piece == nil then
        say(player, 'Trade me one piece of Artifact, Relic or Empyrean armor together with the materials for its next step.')
        say(player, 'Trade me the piece on its own and I will tell you what the next step needs.')

        return
    end

    local entry = flow.lookup(piece:getID())

    if entry.next == nil then
        say(player, 'That piece is already at the highest tier I can make.')

        return
    end

    local list = flow.materialsFor(entry.next)
    local gil  = flow.gilFor(entry)

    if list == nil then
        say(player, 'I do not know how to make the next step of that piece yet.')

        return
    end

    local nextName = displayName(entry.next)

    if #others == 0 then
        say(player, string.format('To make %s, trade me the piece with %s.', nextName, describe(list, gil)))

        return
    end

    local takes, problem = planTakes(list, others)

    if takes == nil then
        say(player, problem)

        return
    end

    local augments, reason = core.readItem(piece)
    if augments == nil then
        say(player, reason)

        return
    end

    sessions[player:getID()] =
    {
        itemId    = piece:getID(),
        nextId    = entry.next,
        container = piece:getLocationID(),
        slot      = piece:getSlotID(),
        augments  = augments,
        gil       = gil,
        takes     = takes,
    }

    local cost = gil > 0 and string.format(' (and %s gil)', formatGil(gil)) or ''

    local options =
    {
        {
            'Yes',
            function(playerArg)
                local ok, failure = flow.commit(playerArg)

                if ok then
                    say(playerArg, string.format('Done! Here is your %s.', nextName))
                else
                    say(playerArg, failure)
                end
            end,
        },
        { 'No', function(playerArg) flow.finish(playerArg) end },
    }

    sendMenu(player, { title = string.format('Make %s%s?', nextName, cost), options = options, onCancelled = function(playerArg) flow.finish(playerArg) end })
end

flow.onTrigger = function(player, npc)
    say(player, 'I upgrade Artifact, Relic and Empyrean armor one step at a time with the same materials as the old smiths used: up to +3.')
    say(player, 'Trade me a piece on its own and I will tell you what its next step needs. Augments carry over.')
end

return flow
