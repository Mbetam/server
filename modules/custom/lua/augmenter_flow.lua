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

-- The whole menu (title and options, each quoted) goes to the client in one chat packet with a 150-byte text field
-- (0x017 Mes[150]); anything longer is cut off and the menu breaks: on 2026-10-04 a bow with four augments could not
-- have any removed, because its remove list was ~184 bytes. Keep every menu within flow.menuLimit.
flow.menuLimit = 149

flow.menuLength = function(menu)
    local length = #menu.title + 2

    for _, option in ipairs(menu.options) do
        length = length + #option[1] + 2
    end

    return length
end

local function send(player, menu)
    if flow.menuLength(menu) > flow.menuLimit then
        print(string.format('[augmenter] menu "%s" is %d bytes, over %d: its last options will be cut off', menu.title, flow.menuLength(menu), flow.menuLimit))
    end

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
-- The original is taken FIRST and the copy made after: a Rare item cannot be held twice, and it frees a bag slot, so no
-- free slot is needed. (Changing the item in place is not an option: the engine builds an item's augment stats once, when
-- the item is made, so an in-place change would save the augments but keep the old stats.)
-- Every step is undone if a later one fails: if the copy cannot be made, the original is given back exactly as it was
-- (same augments) and the gil is refunded, so the player can never lose the item or the gil.
-- Returns true, or false and a reason.
local function swap(player, session, newAugments, price)
    if not player:delGil(price) then
        return false, 'You do not have enough gil.'
    end

    if not player:delItemAt(session.itemId, 1, session.container, session.slot) then
        player:addGil(price)

        return false, 'I could not take your item, so nothing was changed.'
    end

    local added = player:addItem({ id = session.itemId, exdata = core.buildExdata(newAugments), silent = true })
    if added == nil then
        -- Give the original back as it was, and the gil
        player:addItem({ id = session.itemId, exdata = core.buildExdata(session.augments), silent = true })
        player:addGil(price)

        return false, 'I could not make the new item, so you have your original back and nothing was charged.'
    end

    -- Keep following the item, so the player can go on adding or removing without trading it again
    session.container = added:getLocationID()
    session.slot      = added:getSlotID()
    session.augments  = newAugments

    return true
end

-----------------------------------
-- Adding an augment
-----------------------------------

-- Checks adding `count` copies of the same stat and bonus, one after the other, as core.checkAdd would for each.
-- Returns true and { price (total), amount, list (the new augment list) }, or false and the message for the player.
local function planAdd(player, augments, key, tier, count)
    local list  = augments
    local total = 0
    local amount

    for _ = 1, count do
        local ok, plan = core.checkAdd({ level = player:getMainLvl(), gil = player:getGil() - total, augments = list, key = key, tier = tier })
        if not ok then
            return false, plan
        end

        list   = core.withAdded(list, plan.id, plan.value)
        total  = total + plan.price
        amount = plan.amount
    end

    return true, { price = total, amount = amount, list = list }
end

-- How many of this stat the item can still take in one go: its free slots, and the per-stat limit
local function maxCount(augments, key)
    return math.max(0, math.min(config.slotsPerItem - #augments, config.maxPerStat - core.countOf(augments, key)))
end

flow.commitAdd = function(player, key, tier, count)
    count = count or 1

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

    local ok, plan = planAdd(player, current, key, tier, count)
    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    -- All of them in one swap and one payment
    local done, problem = swap(player, session, plan.list, plan.price)
    if not done then
        say(player, session.npcName, problem)
        flow.finish(player)

        return
    end

    local stat  = core.stat(key)
    local times = count > 1 and string.format('%d x ', count) or ''
    say(player, session.npcName, string.format('Done! Your %s now has %s%s %s. That was %s gil.', session.itemName, times, stat.name, bonusText(stat, plan.amount), formatGil(plan.price)))

    -- Straight back to the first menu: add the next augment without trading the item again
    flow.showMain(player)
end

local function confirmAddMenu(player, key, tier, count)
    count = count or 1

    local session  = sessionOf(player)
    local ok, plan = planAdd(player, session.augments, key, tier, count)
    local stat     = core.stat(key)

    if not ok then
        say(player, session.npcName, plan)
        flow.showMain(player)

        return
    end

    local times = count > 1 and string.format('%d x ', count) or ''

    send(player, menuFor(string.format('Add %s%s %s for %s gil?', times, stat.name, bonusText(stat, plan.amount), formatGil(plan.price)),
    {
        { 'Yes, augment it', function(playerArg) flow.commitAdd(playerArg, key, tier, count) end },
        { 'No, go back',     function(playerArg) flow.showMain(playerArg) end },
    }))
end

local tierMenu -- defined below; the count menu's Back goes to it

-- Eric (2026-10-04): the same augment several times in one go. After the bonus, ask how many (1 up to what the item
-- can still take); the confirmation shows the total price. Skipped when only one fits.
local function countMenu(player, key, tier)
    local session = sessionOf(player)
    local most    = maxCount(session.augments, key)

    if most <= 1 then
        confirmAddMenu(player, key, tier, 1)

        return
    end

    local stat    = core.stat(key)
    local amount  = stat.amounts[core.effectiveTier(key, tier)]
    local options = {}

    for count = 1, most do
        table.insert(options,
        {
            string.format('%d (%s gil)', count, formatGil(core.price(core.effectiveTier(key, tier)) * count)),
            function(playerArg) confirmAddMenu(playerArg, key, tier, count) end,
        })
    end

    table.insert(options, { 'Back', function(playerArg) tierMenu(playerArg, key) end })

    send(player, menuFor(string.format('How many %s %s?', stat.name, bonusText(stat, amount)), options))
end

tierMenu = function(player, key)
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
                function(playerArg) countMenu(playerArg, key, tier) end,
            })
        end
    end

    table.insert(options, { 'Back', function(playerArg) flow.showStats(playerArg, 1) end })

    if unlocked < #config.tiers then
        say(player, session.npcName, string.format('Bigger bonuses unlock as you level (tiers open at level %d, %d and %d).', config.tiers[2].minLevel, config.tiers[3].minLevel, config.tiers[4].minLevel))
    end

    send(player, menuFor(string.format('%s: choose a bonus', stat.name), options))
end

-- The stats this item can still take, in the catalog's order: every offered (not retired) stat that has not reached
-- the per-item limit
local function availableStats(session)
    local list = {}

    for _, stat in ipairs(config.stats) do
        if not stat.retired and core.countOf(session.augments, stat.key) < config.maxPerStat then
            table.insert(list, stat)
        end
    end

    return list
end

-- Splits the stats into pages that fit the menu packet: at most statsPerPage each, and never more bytes than the limit
-- leaves after the title ('Stats 1/9') and the three buttons (Next, Prev, Back)
local function statPages(stats)
    local budget = flow.menuLimit - (#'Stats 10/10' + 2) - (#'Next' + 2) - (#'Prev' + 2) - (#'Back' + 2)
    local pages  = { {} }
    local used   = 0

    for _, stat in ipairs(stats) do
        local cost    = #stat.name + 2
        local current = pages[#pages]

        if #current >= statsPerPage or used + cost > budget then
            current = {}
            table.insert(pages, current)
            used = 0
        end

        table.insert(current, stat)
        used = used + cost
    end

    return pages
end

flow.statPages = statPages

flow.showStats = function(player, page)
    local session = sessionOf(player)
    if session == nil then
        return
    end

    local pages = statPages(availableStats(session))
    page        = math.max(1, math.min(page, #pages))

    local options = {}

    for _, stat in ipairs(pages[page]) do
        table.insert(options, { stat.name, function(playerArg) tierMenu(playerArg, stat.key) end })
    end

    if page < #pages then
        table.insert(options, { 'Next', function(playerArg) flow.showStats(playerArg, page + 1) end })
    end

    if page > 1 then
        table.insert(options, { 'Prev', function(playerArg) flow.showStats(playerArg, page - 1) end })
    end

    table.insert(options, { 'Back', function(playerArg) flow.showMain(playerArg) end })

    send(player, menuFor(string.format('Stats %d/%d', page, #pages), options))
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

    flow.showMain(player)
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
        -- Checked whatever the player's gil; the price is on the confirmation (no room for it here: menu packet limit)
        local ok = core.checkRemove({ gil = math.huge, augments = session.augments, slot = slot })

        if ok then
            table.insert(options,
            {
                string.format('%d: %s +%d%s', slot, line.name, line.amount, line.unit),
                function(playerArg) confirmRemoveMenu(playerArg, slot) end,
            })
        end
    end

    table.insert(options, { 'Back', function(playerArg) flow.showMain(playerArg) end })

    send(player, menuFor('Remove which?', options))
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
    local stacking = config.maxPerStat > 1 and string.format('The same stat can be added up to %d times.', config.maxPerStat) or 'Each stat can be added once.'

    say(player, name, string.format('Each item holds up to %d augments. %s You pay only when you confirm.', config.slotsPerItem, stacking))
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
