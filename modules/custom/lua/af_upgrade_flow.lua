-----------------------------------
-- Armor Upgrader conversation: trade one Artifact, Relic or Empyrean armor piece, confirm, pay, get the next tier.
-- Not a module (loaded by require). The chains and prices are in af_upgrade_config.lua.
-- Augments the Augmenter put on the piece carry over to the upgraded piece. Pieces carrying other data are refused.
-- The original is taken FIRST and the new piece made after (AF is Rare: it can't be held twice); if the new piece
-- can't be made, the original comes back as it was and the gil is refunded.
-----------------------------------
local config = require('modules/custom/lua/af_upgrade_config')
local core   = require('modules/custom/lua/augment_core')
-----------------------------------

local flow = {}

local npcName  = 'Armor Upgrader'
local sessions = {} -- one pending upgrade per player: { itemId, nextId, container, slot, augments, price }

-- Price key of each tier, by its place in the old set and in the Reforged set
local oldKeys      = { nil, 'oldPlus1', 'oldPlus2' }
local reforgedKeys = { 'reforged', 'reforgedPlus1', 'reforgedPlus2', 'reforgedPlus3', 'reforgedPlus4' }

-- itemId -> { next = next item id or nil, priceKey = the price key of the next item }
local byItem = {}

for _, jobs in pairs(config.chains) do
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
                byItem[itemId] = { next = ids[index + 1], priceKey = keys[index + 1] }
            end
        end
    end
end

flow.lookup = function(itemId)
    return byItem[itemId]
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

-- Does the upgrade after checking everything again. Returns true, or false and a reason.
flow.commit = function(player)
    local session = sessions[player:getID()]
    flow.finish(player)

    if session == nil then
        return false, 'Trade me the piece first.'
    end

    local item = player:getStorageItem(session.container, session.slot, 255)
    if item == nil or item:getID() ~= session.itemId then
        return false, 'That piece is no longer where you left it, so nothing was changed.'
    end

    if player:getGil() < session.price or not player:delGil(session.price) then
        return false, string.format('That costs %s gil. You do not have enough.', formatGil(session.price))
    end

    if not player:delItemAt(session.itemId, 1, session.container, session.slot) then
        player:addGil(session.price)

        return false, 'I could not take your piece, so nothing was changed.'
    end

    local added = player:addItem({ id = session.nextId, exdata = core.buildExdata(session.augments), silent = true })
    if added == nil then
        player:addItem({ id = session.itemId, exdata = core.buildExdata(session.augments), silent = true })
        player:addGil(session.price)

        return false, 'I could not make the new piece, so you have your original back and nothing was charged.'
    end

    return true
end

flow.onTrade = function(player, npc, trade)
    if trade:getGil() > 0 or trade:getSlotCount() ~= 1 or trade:getItemCount() ~= 1 then
        say(player, 'Trade me one piece of Artifact, Relic or Empyrean armor, and nothing else.')

        return
    end

    local item = nil

    for slot = 0, 7 do
        item = trade:getItem(slot)

        if item ~= nil then
            break
        end
    end

    local entry = item and flow.lookup(item:getID())

    if entry == nil then
        say(player, 'I only work on Artifact, Relic and Empyrean armor.')

        return
    end

    if entry.next == nil then
        say(player, 'That piece is already at its highest tier.')

        return
    end

    local augments, reason = core.readItem(item)
    if augments == nil then
        say(player, reason)

        return
    end

    local price = config.prices[entry.priceKey]
    local nextName = displayName(entry.next)

    sessions[player:getID()] =
    {
        itemId    = item:getID(),
        nextId    = entry.next,
        container = item:getLocationID(),
        slot      = item:getSlotID(),
        augments  = augments,
        price     = price,
    }

    local options =
    {
        {
            'Yes',
            function(playerArg)
                local ok, problem = flow.commit(playerArg)

                if ok then
                    say(playerArg, string.format('Done! Here is your %s. That was %s gil.', nextName, formatGil(price)))
                else
                    say(playerArg, problem)
                end
            end,
        },
        { 'No', function(playerArg) flow.finish(playerArg) end },
    }

    sendMenu(player, { title = string.format('Upgrade to %s for %s gil?', nextName, formatGil(price)), options = options, onCancelled = function(playerArg) flow.finish(playerArg) end })
end

flow.onTrigger = function(player, npc)
    local p = config.prices

    say(player, 'Trade me a piece of Artifact, Relic or Empyrean armor and I will upgrade it one step: up to +4 (Empyrean +3).')
    say(player, string.format('Prices: +1 %s, +2 %s, Reforged %s, Reforged +1 %s, +2 %s, +3 %s, +4 %s gil. Augments carry over.',
        formatGil(p.oldPlus1), formatGil(p.oldPlus2), formatGil(p.reforged), formatGil(p.reforgedPlus1), formatGil(p.reforgedPlus2), formatGil(p.reforgedPlus3), formatGil(p.reforgedPlus4)))
end

return flow
