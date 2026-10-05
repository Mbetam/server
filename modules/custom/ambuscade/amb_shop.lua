-----------------------------------
-- Ambuscade (custom) 1: Gorpa-Masorpa's exchange. Not a module (amb_npcs.lua hooks it to Gorpa).
-- Talk to him: spend Hallmarks on Ambuscade armor (base pieces), set rings, your job's JSE cape, materials, Dynamis
-- coins and Rem's Tales. Trade him one Ambuscade armor piece: upgrade it to +1 (Gallantry) or +2 (Hallmarks); the
-- Augmenter's augments carry over. No monthly limits. Prices: amb_config.lua.
-- Everything is checked again when the player says Yes; the item is given first and the currency taken after, and an
-- upgrade takes the old piece only once the new one could be made (Ambuscade gear is Rare: it can't be held twice).
-----------------------------------
local config = require('modules/custom/ambuscade/amb_config')
local arena  = require('modules/custom/htbf/htbf_arena')
local core   = require('modules/custom/lua/augment_core')
-----------------------------------

local shop = {}

local npcName = 'Gorpa-Masorpa'
local perPage = 5

local HALLMARKS = 'current_hallmarks'
local GALLANTRY = 'gallantry'

local currencyName = { [HALLMARKS] = 'Hallmarks', [GALLANTRY] = 'Gallantry' }

local jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }

local function say(player, message)
    arena.say(player, message, npcName)
end

shop.say = say

local function number(amount)
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

shop.number = number

local function send(player, title, options)
    arena.sendMenu(player, { title = title, options = options, onCancelled = function() end })
end

-- Every armor piece: itemId -> { set, slot, grade (0 base, 1 +1, 2 +2) }
local pieceById = {}

for setIndex, set in ipairs(config.sets) do
    for slot, piece in ipairs(set.pieces) do
        for grade = 0, 2 do
            pieceById[piece[grade + 2]] = { set = setIndex, slot = slot, grade = grade }
        end
    end
end

shop.pieceById = pieceById

local function pieceName(setIndex, slot, grade)
    local set  = config.sets[setIndex]
    local name = set.name .. ' ' .. set.pieces[slot][1]

    if grade > 0 then
        name = name .. ' +' .. grade
    end

    return name
end

shop.pieceName = pieceName

-- Gives `qty` of `itemId` and takes `price` of `currency` for it. Returns true, or false and the reason.
shop.buy = function(player, itemId, qty, price, currency, name)
    local have = player:getCurrency(currency)

    if have < price then
        return false, string.format('%s costs %s %s; you have %s.', name, number(price), currencyName[currency], number(have))
    end

    if player:getFreeSlotsCount() == 0 then
        return false, 'Your inventory is full.'
    end

    if not npcUtil.giveItem(player, { { itemId, qty } }) then
        return false, 'You can\'t carry that (a Rare item you already have, or no room), so nothing was taken.'
    end

    player:delCurrency(currency, price)

    return true
end

local function confirm(player, title, onYes, onNo)
    send(player, title,
    {
        { 'Yes', onYes },
        { 'No', onNo or function() end },
    })
end

-- One purchase: confirm, buy, say how it went
local function offer(player, itemId, qty, price, currency, name, back)
    confirm(player, string.format('%s for %s %s?', name, number(price), currencyName[currency]), function(playerArg)
        local ok, reason = shop.buy(playerArg, itemId, qty, price, currency, name)

        if ok then
            say(playerArg, string.format('Pleasure doing business! You have %s %s left.', number(playerArg:getCurrency(currency)), currencyName[currency]))
        else
            say(playerArg, reason)
        end
    end, back)
end

-- A list of { label, fn } options, `perPage` at a time, with Next / Prev / Back
local function paged(player, title, entries, page, show, back)
    local pages = math.max(1, math.ceil(#entries / perPage))
    page        = math.max(1, math.min(page or 1, pages))

    local options = {}

    for index = (page - 1) * perPage + 1, math.min(page * perPage, #entries) do
        table.insert(options, entries[index])
    end

    if page < pages then
        table.insert(options, { 'Next', function(playerArg) show(playerArg, page + 1) end })
    end

    if page > 1 then
        table.insert(options, { 'Prev', function(playerArg) show(playerArg, page - 1) end })
    end

    table.insert(options, { 'Back', back })

    send(player, pages > 1 and string.format('%s %d/%d', title, page, pages) or title, options)
end

-----------------------------------
-- Armor (base pieces) and rings
-----------------------------------
-- Which jobs wear the sets on this page, two chat lines
local function setJobLines(player, page)
    local first = (page - 1) * perPage + 1
    local parts = {}

    for index = first, math.min(first + perPage - 1, #config.sets) do
        table.insert(parts, string.format('%s: %s', config.sets[index].name, config.sets[index].jobs))
    end

    say(player, table.concat(parts, '. ', 1, math.min(3, #parts)) .. '.')

    if #parts > 3 then
        say(player, table.concat(parts, '. ', 4) .. '.')
    end
end

shop.setJobLines = setJobLines

shop.showSets = function(player, slot, page)
    local entries = {}

    for setIndex, set in ipairs(config.sets) do
        local itemId = set.pieces[slot][2]
        local price  = config.armorPrice.base[slot]

        table.insert(entries, { set.name, function(playerArg)
            offer(playerArg, itemId, 1, price, HALLMARKS, pieceName(setIndex, slot, 0), function(p) shop.showSets(p, slot, page) end)
        end })
    end

    setJobLines(player, page or 1)
    paged(player, string.format('%s: %s Hallmarks', config.slotNames[slot], number(config.armorPrice.base[slot])), entries, page,
        function(p, newPage) shop.showSets(p, slot, newPage) end, shop.showArmor)
end

shop.showArmor = function(player)
    say(player, 'Base pieces cost Hallmarks. To upgrade one, trade it to me: +1 costs Gallantry, +2 costs Hallmarks. Augments stay on.')

    local options = {}

    for slot, name in ipairs(config.slotNames) do
        table.insert(options, { string.format('%s %s', name, number(config.armorPrice.base[slot])), function(p) shop.showSets(p, slot, 1) end })
    end

    table.insert(options, { 'Back', shop.showMain })
    send(player, 'Which piece? (Hallmarks)', options)
end

shop.showRings = function(player, page)
    local entries = {}

    for setIndex, set in ipairs(config.sets) do
        table.insert(entries, { set.name, function(playerArg)
            offer(playerArg, set.ring, 1, config.ringPrice, HALLMARKS, set.name .. ' Ring', function(p) shop.showRings(p, page) end)
        end })
    end

    setJobLines(player, page or 1)
    paged(player, string.format('Rings: %s Hallmarks', number(config.ringPrice)), entries, page, shop.showRings, shop.showMain)
end

shop.showCape = function(player)
    local job = player:getMainJob()

    say(player, 'This is the cape of your current main job; change jobs to buy another. It comes without augments.')
    offer(player, config.cape(job), 1, config.capePrice, HALLMARKS, string.format('The %s cape', jobs[job] or 'job'), shop.showMain)
end

-----------------------------------
-- Materials, coins, Rem's Tales
-----------------------------------
shop.showQuantity = function(player, groupIndex, itemIndex, page)
    local entry   = config.goods[groupIndex].items[itemIndex]
    local options = {}
    local back    = function(p) shop.showGoods(p, groupIndex, page) end

    for _, qty in ipairs(config.quantities) do
        table.insert(options, { string.format('x%d (%s)', qty, number(qty * entry[3])), function(playerArg)
            local name = qty > 1 and string.format('%s x%d', entry[1], qty) or entry[1]
            local ok, reason = shop.buy(playerArg, entry[2], qty, qty * entry[3], HALLMARKS, name)

            if ok then
                say(playerArg, string.format('Here you are! You have %s Hallmarks left.', number(playerArg:getCurrency(HALLMARKS))))
            else
                say(playerArg, reason)
            end
        end })
    end

    table.insert(options, { 'Back', back })
    send(player, string.format('%s: %s each', entry[1], number(entry[3])), options)
end

shop.showGoods = function(player, groupIndex, page)
    local group   = config.goods[groupIndex]
    local entries = {}

    for itemIndex, entry in ipairs(group.items) do
        table.insert(entries, { string.format('%s %s', entry[1], number(entry[3])), function(p) shop.showQuantity(p, groupIndex, itemIndex, page) end })
    end

    paged(player, group.title .. ' (Hallmarks)', entries, page, function(p, newPage) shop.showGoods(p, groupIndex, newPage) end, shop.showMain)
end

-----------------------------------
-- The main menu
-----------------------------------
shop.showMain = function(player)
    local options =
    {
        { 'Armor', shop.showArmor },
        { 'Set rings', function(p) shop.showRings(p, 1) end },
        { 'JSE cape', shop.showCape },
    }

    for groupIndex, group in ipairs(config.goods) do
        table.insert(options, { group.title, function(p) shop.showGoods(p, groupIndex, 1) end })
    end

    table.insert(options, { 'Goodbye', function() end })

    send(player, string.format('Hallmarks %s, Gallantry %s', number(player:getCurrency(HALLMARKS)), number(player:getCurrency(GALLANTRY))), options)
end

shop.onTrigger = function(player, npc)
    say(player, 'Welcome! Spend your Hallmarks and Gallantry here, no monthly limits. Earn them in the Ambuscade: read the tome beside me.')
    shop.showMain(player)
end

-----------------------------------
-- Upgrades: trade one Ambuscade armor piece
-----------------------------------
-- What upgrading this grade costs: currency, amount
local function upgradeCost(slot, grade)
    if grade == 0 then
        return GALLANTRY, config.armorPrice.plus1[slot]
    end

    return HALLMARKS, config.armorPrice.plus2[slot]
end

shop.upgradeCost = upgradeCost

-- Does the upgrade after checking everything again. Returns true, or false and the reason.
shop.upgrade = function(player, itemId, container, slotId)
    local info = pieceById[itemId]

    if info == nil or info.grade >= 2 then
        return false, 'I can\'t upgrade that.'
    end

    local item = player:getStorageItem(container, slotId, 255)

    if item == nil or item:getID() ~= itemId then
        return false, 'That piece is no longer where you left it, so nothing was changed.'
    end

    local augments, reason = core.readItem(item)

    if augments == nil then
        return false, reason
    end

    local currency, price = upgradeCost(info.slot, info.grade)
    local have            = player:getCurrency(currency)

    if have < price then
        return false, string.format('That upgrade costs %s %s; you have %s.', number(price), currencyName[currency], number(have))
    end

    local nextId = config.sets[info.set].pieces[info.slot][info.grade + 3]

    if not player:delItemAt(itemId, 1, container, slotId) then
        return false, 'I could not take your piece, so nothing was changed.'
    end

    if player:addItem({ id = nextId, exdata = core.buildExdata(augments), silent = true }) == nil then
        player:addItem({ id = itemId, exdata = core.buildExdata(augments), silent = true })

        return false, 'I could not make the new piece (do you already have one?), so you have your original back.'
    end

    player:delCurrency(currency, price)
    player:messageSpecial(zones[player:getZoneID()].text.ITEM_OBTAINED, nextId)

    return true
end

shop.onTrade = function(player, npc, trade)
    local piece = nil

    for slot = 0, 7 do
        local item = trade:getItem(slot)

        if item then
            if piece ~= nil or pieceById[item:getID()] == nil then
                say(player, 'Trade me one Ambuscade armor piece at a time, and nothing else, to upgrade it.')

                return
            end

            piece = item
        end
    end

    if piece == nil then
        return
    end

    local itemId = piece:getID()
    local info   = pieceById[itemId]

    if info.grade >= 2 then
        say(player, 'That piece is already +2, as good as it gets!')

        return
    end

    local currency, price = upgradeCost(info.slot, info.grade)
    local container, slotId = piece:getLocationID(), piece:getSlotID()
    local nextName = pieceName(info.set, info.slot, info.grade + 1)

    confirm(player, string.format('Make it %s for %s %s?', nextName, number(price), currencyName[currency]), function(playerArg)
        local ok, reason = shop.upgrade(playerArg, itemId, container, slotId)

        if ok then
            say(playerArg, string.format('There: %s! You have %s %s left.', nextName, number(playerArg:getCurrency(currency)), currencyName[currency]))
        else
            say(playerArg, reason)
        end
    end)
end

-- For tests
shop.setMenuSender = arena.setMenuSender

return shop
