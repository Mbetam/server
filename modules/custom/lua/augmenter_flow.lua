-----------------------------------
-- The Augmenter's conversation and item swap.
-- A player trades ONE weapon or piece of armor to the NPC. The item stays in their bag while they choose from menus.
-- Nothing changes until they confirm; then the swap is done in an order that can always be undone, and the item is
-- re-checked first in case it was moved or changed while the menus were open.
-- This is a helper file, not a module: it registers nothing and is only loaded when another file requires it.
-----------------------------------
local core   = require('modules/custom/lua/augment_core')
local config = core.config
-----------------------------------

local flow = {}

local statsPerPage = 6
local notEquipment = 255 -- getStorageItem: "look in the container, not the worn slots"

-- One conversation per player: { itemId, container, slot, itemName, augments, npcName }
local sessions = {}

-----------------------------------
-- Small helpers
-----------------------------------

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

local function bonusText(stat, amount)
    return string.format('+%d%s', amount, stat and stat.unit or '')
end

local function say(player, npcName, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, npcName or 'Augmenter')
end

local function sessionOf(player)
    return sessions[player:getID()]
end

-- The menu is sent a moment later so the previous menu is fully closed first (each choice ends its menu).
local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- For tests only. The engine keeps every open menu in a global table that is destroyed after the Lua state at exit, so a test
-- process that ends with a real menu still open crashes on the way out. Tests hand in a function that captures the menu instead.
-- Call with nothing to go back to the real thing.
flow.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

local function send(player, menu)
    sendMenu(player, menu)
end

-- Ends the conversation. Safe to call at any time.
flow.finish = function(player)
    sessions[player:getID()] = nil
end

local function cancelled(player)
    flow.finish(player)
end

local function menuFor(title, options)
    return { title = title, options = options, onCancelled = cancelled }
end

-----------------------------------
-- Checking the item is still what the player showed us
-----------------------------------

-- Returns the item's current augment list, or nil and a reason.
local function verify(player, session)
    local item = player:getStorageItem(session.container, session.slot, notEquipment)

    if item == nil or item:getID() ~= session.itemId then
        return nil, 'That item is no longer where you left it. Trade it to me again.'
    end

    local augments, reason = core.readItem(item)
    if augments == nil then
        return nil, reason
    end

    if #augments ~= #session.augments then
        return nil, 'That item has changed since you showed it to me. Trade it to me again.'
    end

    for slot, augment in ipairs(augments) do
        if augment.id ~= session.augments[slot].id or augment.value ~= session.augments[slot].value then
            return nil, 'That item has changed since you showed it to me. Trade it to me again.'
        end
    end

    return augments
end

-----------------------------------
-- The swap
-----------------------------------

-- Replaces the player's item with a new copy carrying `newAugments`, and takes `price` gil.
-- Every step is undone if a later one fails, so the player can never lose the item or the gil.
-- Returns true, or false and a reason.
local function swap(player, session, newAugments, price)
    if player:getFreeSlotsCount() < 1 then
        return false, 'You need at least one free inventory slot.'
    end

    if not player:delGil(price) then
        return false, 'You do not have enough gil.'
    end

    local added = player:addItem({ id = session.itemId, exdata = core.buildExdata(newAugments), silent = true })
    if added == nil then
        player:addGil(price)
        return false, 'I could not make the new item, so nothing was changed.'
    end

    if not player:delItemAt(session.itemId, 1, session.container, session.slot) then
        -- The original could not be taken: remove the copy we just made and give the gil back
        player:delItemAt(session.itemId, 1, added:getLocationID(), added:getSlotID())
        player:addGil(price)

        return false, 'I could not take your original item, so nothing was changed.'
    end

    return true
end

-----------------------------------
-- Adding an augment
-----------------------------------

flow.commitAdd = function(player, key, tier)
    local session = sessionOf(player)
    if session == nil then
        return
    end

    local current, reason = verify(player, session)
    if current == nil then
        say(player, session.npcName, reason)
        flow.finish(player)

        return
    end

    local ok, plan = core.checkAdd({ level = player:getMainLvl(), gil = player:getGil(), augments = current, key = key, tier = tier })
    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    local done, problem = swap(player, session, core.withAdded(current, plan.id, plan.value), plan.price)
    if not done then
        say(player, session.npcName, problem)
        flow.finish(player)

        return
    end

    local stat = core.stat(key)
    say(player, session.npcName, string.format('Done! Your %s now has %s %s. That was %s gil.', session.itemName, stat.name, bonusText(stat, plan.amount), formatGil(plan.price)))
    flow.finish(player)
end

local function confirmAddMenu(player, key, tier)
    local session      = sessionOf(player)
    local ok, plan     = core.checkAdd({ level = player:getMainLvl(), gil = player:getGil(), augments = session.augments, key = key, tier = tier })
    local stat         = core.stat(key)

    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    send(player, menuFor(string.format('Add %s %s for %s gil?', stat.name, bonusText(stat, plan.amount), formatGil(plan.price)),
    {
        { 'Yes, augment it', function(playerArg) flow.commitAdd(playerArg, key, tier) end },
        { 'No, go back',     function(playerArg) flow.showMain(playerArg) end },
    }))
end

local function tierMenu(player, key)
    local session  = sessionOf(player)
    local stat     = core.stat(key)
    local unlocked = core.tierForLevel(player:getMainLvl())
    local options  = {}

    for tier = 1, #config.tiers do
        -- List each bonus once, at the lowest tier that gives it, and only if the player has unlocked that tier
        local effective = core.effectiveTier(key, tier)

        if effective == tier and tier <= unlocked then
            table.insert(options,
            {
                string.format('%s (%s gil)', bonusText(stat, stat.amounts[tier]), formatGil(core.price(tier))),
                function(playerArg) confirmAddMenu(playerArg, key, tier) end,
            })
        end
    end

    table.insert(options, { 'Back', function(playerArg) flow.showStats(playerArg, 1) end })

    if unlocked < #config.tiers then
        say(player, session.npcName, string.format('Bigger bonuses unlock as you level (tiers open at level %d, %d and %d).', config.tiers[2].minLevel, config.tiers[3].minLevel, config.tiers[4].minLevel))
    end

    send(player, menuFor(string.format('%s: choose a bonus', stat.name), options))
end

-- The stats this item does not have yet, in the catalog's order
local function freeStats(session)
    local taken = {}

    for _, augment in ipairs(session.augments) do
        taken[(core.decode(augment.id, augment.value))] = true
    end

    local list = {}

    for _, stat in ipairs(config.stats) do
        if not taken[stat.key] then
            table.insert(list, stat)
        end
    end

    return list
end

flow.showStats = function(player, page)
    local session = sessionOf(player)
    if session == nil then
        return
    end

    local stats = freeStats(session)
    local pages = math.max(1, math.ceil(#stats / statsPerPage))
    page        = math.max(1, math.min(page, pages))

    local options = {}

    for index = (page - 1) * statsPerPage + 1, math.min(page * statsPerPage, #stats) do
        local stat = stats[index]

        table.insert(options, { stat.name, function(playerArg) tierMenu(playerArg, stat.key) end })
    end

    if page < pages then
        table.insert(options, { 'Next page', function(playerArg) flow.showStats(playerArg, page + 1) end })
    end

    if page > 1 then
        table.insert(options, { 'Previous page', function(playerArg) flow.showStats(playerArg, page - 1) end })
    end

    table.insert(options, { 'Back', function(playerArg) flow.showMain(playerArg) end })

    send(player, menuFor(string.format('Choose a stat (page %d of %d)', page, pages), options))
end

-----------------------------------
-- Removing an augment
-----------------------------------

flow.commitRemove = function(player, slot)
    local session = sessionOf(player)
    if session == nil then
        return
    end

    local current, reason = verify(player, session)
    if current == nil then
        say(player, session.npcName, reason)
        flow.finish(player)

        return
    end

    local ok, plan = core.checkRemove({ gil = player:getGil(), augments = current, slot = slot })
    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    local done, problem = swap(player, session, core.withRemoved(current, slot), plan.price)
    if not done then
        say(player, session.npcName, problem)
        flow.finish(player)

        return
    end

    local stat = core.stat(plan.key)
    say(player, session.npcName, string.format('Done! I removed %s %s from your %s. That was %s gil.', stat.name, bonusText(stat, plan.amount), session.itemName, formatGil(plan.price)))
    flow.finish(player)
end

local function confirmRemoveMenu(player, slot)
    local session  = sessionOf(player)
    local ok, plan = core.checkRemove({ gil = player:getGil(), augments = session.augments, slot = slot })

    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    local stat = core.stat(plan.key)

    send(player, menuFor(string.format('Remove %s %s for %s gil?', stat.name, bonusText(stat, plan.amount), formatGil(plan.price)),
    {
        { 'Yes, remove it', function(playerArg) flow.commitRemove(playerArg, slot) end },
        { 'No, go back',    function(playerArg) flow.showMain(playerArg) end },
    }))
end

local function removeMenu(player)
    local session = sessionOf(player)
    local options = {}

    for slot, line in ipairs(core.describe(session.augments)) do
        -- Price shown whatever the player's gil, so they can see what it would cost
        local ok, plan = core.checkRemove({ gil = math.huge, augments = session.augments, slot = slot })

        if ok then
            table.insert(options,
            {
                string.format('%d: %s +%d%s (%s gil)', slot, line.name, line.amount, line.unit, formatGil(plan.price)),
                function(playerArg) confirmRemoveMenu(playerArg, slot) end,
            })
        end
    end

    table.insert(options, { 'Back', function(playerArg) flow.showMain(playerArg) end })

    send(player, menuFor('Which augment should I remove?', options))
end

-----------------------------------
-- The first menu
-----------------------------------

flow.showMain = function(player)
    local session = sessionOf(player)
    if session == nil then
        return
    end

    say(player, session.npcName, string.format('%s has %d of %d augment slots used.', session.itemName, #session.augments, config.slotsPerItem))

    for _, line in ipairs(core.describe(session.augments)) do
        say(player, session.npcName, string.format('  %d. %s +%d%s', line.slot, line.name, line.amount, line.unit))
    end

    local options = {}

    if #session.augments < config.slotsPerItem then
        table.insert(options, { 'Add an augment', function(playerArg) flow.showStats(playerArg, 1) end })
    end

    if #session.augments > 0 then
        table.insert(options, { 'Remove an augment', function(playerArg) removeMenu(playerArg) end })
    end

    table.insert(options, { 'Never mind', function(playerArg) flow.finish(playerArg) end })

    send(player, menuFor(string.format('Augmenter: %s', session.itemName), options))
end

-----------------------------------
-- What the NPC does when spoken to or traded with
-----------------------------------

flow.onTrigger = function(player, npc)
    local name = npc:getPacketName()

    say(player, name, 'I can add bonus stats to your weapons and armor. Trade me ONE piece of gear with no augments, or one I have augmented before, and take it off first.')
    say(player, name, string.format('Each item holds up to %d augments, one of each stat. You pay only when you confirm.', config.slotsPerItem))
end

flow.onTrade = function(player, npc, trade)
    local name = npc:getPacketName()

    if trade:getGil() > 0 or trade:getSlotCount() ~= 1 or trade:getItemCount() ~= 1 then
        say(player, name, 'Please trade me exactly one weapon or piece of armor, and nothing else.')

        return
    end

    local item = nil

    for slot = 0, 7 do
        item = trade:getItem(slot)

        if item ~= nil then
            break
        end
    end

    if item == nil then
        return
    end

    local augments, reason = core.readItem(item)
    if augments == nil then
        say(player, name, reason)

        return
    end

    if player:getFreeSlotsCount() < 1 then
        say(player, name, 'You need at least one free inventory slot first.')

        return
    end

    sessions[player:getID()] =
    {
        itemId    = item:getID(),
        container = item:getLocationID(),
        slot      = item:getSlotID(),
        itemName  = item:getName(),
        augments  = augments,
        npcName   = name,
    }

    flow.showMain(player)
end

return flow
