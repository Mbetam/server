-----------------------------------
-- The Augmenter's conversation and item swap (modules/custom/lua/augmenter_flow.lua).
-- Uses stand-in players, items and trades, so every branch can be checked, including the ones that must never lose an item or
-- gil. The real engine is exercised in augmenter_engine.lua.
-----------------------------------
local core   = require('modules/custom/lua/augment_core')
local flow   = require('modules/custom/lua/augmenter_flow')
local config = core.config
-----------------------------------

local ringId = 13454

-- What getExData returns for gear carrying these augments
local function augmentExdata(list)
    local exdata =
    {
        augmentKind    = xi.augment.kind.HAS_AUGMENTS,
        augmentSubKind = xi.augment.subKind.STANDARD,
        augments       = {},
        signature      = '',
    }

    for slot = 1, 5 do
        exdata.augments[slot] = list[slot] and { id = list[slot].id, value = list[slot].value } or { id = 0, value = 0 }
    end

    return exdata
end

local function makeItem(slot, exdata, isGear)
    return
    {
        id            = ringId,
        slot          = slot,
        exdata        = exdata or { [0] = 0, [1] = 0, [2] = 0 },
        isGear        = isGear ~= false,
        getID         = function(self) return self.id end,
        getName       = function() return 'Copper Ring' end,
        getSlotID     = function(self) return self.slot end,
        getLocationID = function() return 0 end,
        isType        = function(self, itemType) return self.isGear and (itemType == xi.itemType.ARMOR or itemType == xi.itemType.WEAPON) end,
        getExData     = function(self) return self.exdata end,
    }
end

-- A stand-in for the player: keeps a bag, some gil, and records what was said and which menu was sent last
local function makePlayer(options)
    options = options or {}

    local player =
    {
        level          = options.level or 99,
        gil            = options.gil or 10000000,
        capacity       = options.capacity or 30,
        items          = {},
        printed        = {},
        menu           = nil,
        addFails       = false,
        failTakingSlot = nil,
    }

    player.getID      = function() return 7 end
    player.getMainLvl = function(self) return self.level end
    player.getGil     = function(self) return self.gil end
    player.addGil     = function(self, amount) self.gil = self.gil + amount end
    player.timer      = function(self, _, fn) fn(self) end -- menus are sent after a short delay; run it straight away

    player.delGil = function(self, amount)
        if self.gil < amount then
            return false
        end

        self.gil = self.gil - amount

        return true
    end

    player.getFreeSlotsCount = function(self)
        local used = 0

        for _ in pairs(self.items) do
            used = used + 1
        end

        return self.capacity - used
    end

    player.getStorageItem = function(self, container, slot, equipId)
        if container == 0 and equipId == 255 then
            return self.items[slot]
        end
    end

    player.addItem = function(self, data)
        if self.addFails or self:getFreeSlotsCount() < 1 then
            return nil
        end

        local slot = 1
        while self.items[slot] ~= nil do
            slot = slot + 1
        end

        local exdata = nil

        if data.exdata ~= nil then
            exdata = augmentExdata(data.exdata.augments)
        end

        self.items[slot] = makeItem(slot, exdata)
        self.items[slot].id = data.id

        return self.items[slot]
    end

    player.delItemAt = function(self, itemId, _, container, slot)
        if container ~= 0 or slot == self.failTakingSlot then
            return false
        end

        local item = self.items[slot]
        if item == nil or item.id ~= itemId then
            return false
        end

        self.items[slot] = nil

        return true
    end

    player.printToPlayer = function(self, message)
        table.insert(self.printed, message)
    end

    player.customMenu = function(self, menu)
        -- The game matches a click to an option by its label, so labels in one menu must never repeat
        local seen = {}

        for _, option in ipairs(menu.options) do
            assert(seen[option[1]] == nil, 'two options in the menu "' .. menu.title .. '" share the label "' .. option[1] .. '"')
            seen[option[1]] = true
        end

        self.menu = menu
    end

    return player
end

local function said(player)
    return table.concat(player.printed, '\n')
end

local function labels(player)
    local list = {}

    for _, option in ipairs(player.menu.options) do
        table.insert(list, option[1])
    end

    return list
end

local function hasLabel(player, wanted)
    for _, label in ipairs(labels(player)) do
        if label == wanted then
            return true
        end
    end

    return false
end

-- Clicks an option in the current menu
local function pick(player, label)
    assert(player.menu ~= nil, 'no menu is open')

    for _, option in ipairs(player.menu.options) do
        if option[1] == label then
            player.menu = nil
            option[2](player)

            return
        end
    end

    error('no option "' .. label .. '" in the menu; the options are: ' .. table.concat(labels(player), ' | '))
end

local npc = { getPacketName = function() return 'Augmenter' end }

-- Trades one item (already in the bag) to the NPC
local function trade(player, slot, overrides)
    overrides = overrides or {}

    local item = player.items[slot]

    flow.onTrade(player, npc,
    {
        getGil       = function() return overrides.gil or 0 end,
        getSlotCount = function() return overrides.slots or 1 end,
        getItemCount = function() return overrides.count or 1 end,
        getItem      = function(_, index) if index == 0 then return item end end,
    })
end

local function bagWith(player, exdata, isGear)
    player.items[1] = makeItem(1, exdata, isGear)

    return player
end

local function augmentIds(item)
    local ids = {}

    for _, augment in ipairs(item.exdata.augments or {}) do
        if augment.id ~= 0 then
            table.insert(ids, augment.id .. ':' .. augment.value)
        end
    end

    return table.concat(ids, ',')
end

local function theOnlyItem(player)
    local found, count = nil, 0

    for _, item in pairs(player.items) do
        found = item
        count = count + 1
    end

    assert(count == 1, 'expected exactly one item in the bag but found ' .. count)

    return found
end

describe('Augmenter: what it accepts', function()
    it('explains itself when spoken to', function()
        local player = makePlayer()

        flow.onTrigger(player, npc)

        assert(said(player):find('ONE piece of gear', 1, true), 'the NPC should explain what to do')
    end)

    it('refuses gil in the trade', function()
        local player = bagWith(makePlayer())

        trade(player, 1, { gil = 100 })

        assert(player.menu == nil and said(player):find('exactly one', 1, true), 'gil in the trade should be refused')
    end)

    it('refuses more than one item', function()
        local player = bagWith(makePlayer())

        trade(player, 1, { slots = 2, count = 2 })

        assert(player.menu == nil and said(player):find('exactly one', 1, true), 'two items should be refused')
    end)

    it('refuses things that are not gear', function()
        local player = bagWith(makePlayer(), nil, false)

        trade(player, 1)

        assert(player.menu == nil and said(player):find('weapons and armor', 1, true), 'a non-gear item should be refused')
    end)

    it('refuses gear carrying augments it did not make', function()
        local player = bagWith(makePlayer(), augmentExdata({ { id = 146, value = 20 } }))

        trade(player, 1)

        assert(player.menu == nil and said(player):find('cannot be changed', 1, true), 'a foreign augment should be refused')
    end)

    it('needs a free inventory slot', function()
        local player = bagWith(makePlayer({ capacity = 1 }))

        trade(player, 1)

        assert(player.menu == nil and said(player):find('free inventory slot', 1, true), 'a full bag should be refused')
    end)

    it('opens the first menu for a plain item', function()
        local player = bagWith(makePlayer())

        trade(player, 1)

        assert(player.menu ~= nil and player.menu.title:find('Copper Ring', 1, true), 'the menu should name the item')
        assert(hasLabel(player, 'Add an augment') and hasLabel(player, 'Never mind'))
        assert(not hasLabel(player, 'Remove an augment'), 'a plain item has nothing to remove')
    end)

    it('offers removal once an item has an augment', function()
        local player = bagWith(makePlayer(), augmentExdata({ { id = 146, value = 2 } }))

        trade(player, 1)

        assert(hasLabel(player, 'Add an augment') and hasLabel(player, 'Remove an augment'))
        assert(said(player):find('1 of 4', 1, true) and said(player):find('Dual Wield +3', 1, true), 'the NPC should list what the item carries: ' .. said(player))
    end)

    it('offers no more augments once every slot is used', function()
        local full = augmentExdata({ { id = 146, value = 0 }, { id = 143, value = 0 }, { id = 144, value = 0 }, { id = 41, value = 0 } })
        local player = bagWith(makePlayer(), full)

        trade(player, 1)

        assert(not hasLabel(player, 'Add an augment') and hasLabel(player, 'Remove an augment'), 'a full item can only have augments removed')
    end)
end)

describe('Augmenter: choosing a stat and a bonus', function()
    local player

    before_each(function()
        player = bagWith(makePlayer())
        trade(player, 1)
        pick(player, 'Add an augment')
    end)

    it('lists the stats six to a page', function()
        assert(#labels(player) == 6 + 2, 'page 1 should have six stats plus Next page and Back: ' .. table.concat(labels(player), ' | '))
        assert(hasLabel(player, 'Dual Wield') and hasLabel(player, 'Next page'))
        assert(not hasLabel(player, 'Previous page'), 'the first page has no previous page')
        assert(player.menu.title:find('page 1 of 3', 1, true))
    end)

    it('reaches every stat by paging', function()
        local seen = {}

        for _ = 1, 3 do
            for _, label in ipairs(labels(player)) do
                seen[label] = true
            end

            if hasLabel(player, 'Next page') then
                pick(player, 'Next page')
            end
        end

        for _, stat in ipairs(config.stats) do
            assert(seen[stat.name], stat.name .. ' cannot be reached from the menus')
        end
    end)

    it('goes back a page', function()
        pick(player, 'Next page')
        assert(hasLabel(player, 'Previous page'))

        pick(player, 'Previous page')

        assert(hasLabel(player, 'Dual Wield'), 'Previous page should return to page 1')
    end)

    it('offers each bonus with its price', function()
        pick(player, 'Dual Wield')

        assert(hasLabel(player, '+1 (10,000 gil)') and hasLabel(player, '+2 (50,000 gil)'))
        assert(hasLabel(player, '+3 (250,000 gil)') and hasLabel(player, '+4 (1,000,000 gil)'))
    end)

    it('lists a bonus shared by two tiers only once, at the lower price', function()
        pick(player, 'Triple Attack')

        assert(hasLabel(player, '+1% (10,000 gil)') and hasLabel(player, '+2% (250,000 gil)'), table.concat(labels(player), ' | '))
        assert(not hasLabel(player, '+1% (50,000 gil)'), 'a second +1% at the tier 2 price would be a trap')
    end)

    it('shows only the tiers a player has unlocked', function()
        local low = bagWith(makePlayer({ level = 45 }))
        trade(low, 1)
        pick(low, 'Add an augment')
        pick(low, 'Dual Wield')

        assert(hasLabel(low, '+2 (50,000 gil)') and not hasLabel(low, '+3 (250,000 gil)'), 'level 45 has tiers 1 and 2 only')
        assert(said(low):find('unlock as you level', 1, true), 'the NPC should say more unlocks later')
    end)

    it('leaves out a stat the item already has', function()
        local carrying = bagWith(makePlayer(), augmentExdata({ { id = 146, value = 0 } }))
        trade(carrying, 1)
        pick(carrying, 'Add an augment')

        assert(not hasLabel(carrying, 'Dual Wield'), 'Dual Wield is already on the item')
        assert(hasLabel(carrying, 'Double Attack'))
    end)
end)

describe('Augmenter: adding an augment', function()
    local function addDualWield(player, bonus)
        trade(player, 1)
        pick(player, 'Add an augment')
        pick(player, 'Dual Wield')
        pick(player, bonus)
    end

    it('asks before charging', function()
        local player = bagWith(makePlayer())

        addDualWield(player, '+3 (250,000 gil)')

        assert(player.menu.title == 'Add Dual Wield +3 for 250,000 gil?', 'the confirmation should state the price: ' .. player.menu.title)
        assert(player.gil == 10000000, 'nothing should be charged yet')
    end)

    it('swaps the item and takes the gil when confirmed', function()
        local player = bagWith(makePlayer())

        addDualWield(player, '+3 (250,000 gil)')
        pick(player, 'Yes, augment it')

        local item = theOnlyItem(player)
        assert(augmentIds(item) == '146:2', 'the new item should carry Dual Wield +3 (146 with value 2) but carries: ' .. augmentIds(item))
        assert(player.gil == 10000000 - 250000, 'the gil taken was wrong: ' .. player.gil)
        assert(said(player):find('Done!', 1, true) and said(player):find('250,000', 1, true))
    end)

    it('charges nothing if the player says no', function()
        local player = bagWith(makePlayer())

        addDualWield(player, '+3 (250,000 gil)')
        pick(player, 'No, go back')

        assert(player.gil == 10000000 and augmentIds(theOnlyItem(player)) == '', 'saying no should change nothing')
        assert(hasLabel(player, 'Add an augment'), 'saying no should return to the first menu')
    end)

    it('adds a second augment to an item that already has one', function()
        local player = bagWith(makePlayer(), augmentExdata({ { id = 146, value = 0 } }))

        trade(player, 1)
        pick(player, 'Add an augment')
        pick(player, 'Double Attack')
        pick(player, '+2% (50,000 gil)')
        pick(player, 'Yes, augment it')

        assert(augmentIds(theOnlyItem(player)) == '146:0,143:1', 'the old augment should be kept and the new one added: ' .. augmentIds(theOnlyItem(player)))
    end)

    it('will not start a second transaction after finishing', function()
        local player = bagWith(makePlayer())

        addDualWield(player, '+1 (10,000 gil)')
        pick(player, 'Yes, augment it')
        local goldAfter = player.gil

        flow.commitAdd(player, 'dual_wield', 1)

        assert(player.gil == goldAfter, 'a finished conversation must not charge again')
    end)

    it('refuses to offer what the player cannot afford', function()
        local player = bagWith(makePlayer({ gil = 5000 }))

        addDualWield(player, '+1 (10,000 gil)')

        assert(said(player):find('costs 10000', 1, true), 'the NPC should say what it costs: ' .. said(player))
        assert(hasLabel(player, 'Add an augment'), 'the player should be returned to the first menu')
        assert(player.gil == 5000)
    end)

    it('checks the gil again at the moment of payment', function()
        local player = bagWith(makePlayer({ gil = 20000 }))

        addDualWield(player, '+1 (10,000 gil)')
        player.gil = 100 -- spent while the menu was open

        pick(player, 'Yes, augment it')

        assert(player.gil == 100 and augmentIds(theOnlyItem(player)) == '', 'nothing should change when the gil is gone')
    end)
end)

describe('Augmenter: never losing anything', function()
    local function confirmDualWield(player)
        trade(player, 1)
        pick(player, 'Add an augment')
        pick(player, 'Dual Wield')
        pick(player, '+1 (10,000 gil)')
    end

    it('gives the gil back if the new item cannot be made', function()
        local player = bagWith(makePlayer())

        confirmDualWield(player)
        player.addFails = true
        pick(player, 'Yes, augment it')

        assert(player.gil == 10000000, 'the gil must be refunded, but the player has ' .. player.gil)
        assert(augmentIds(theOnlyItem(player)) == '', 'the original item must be untouched')
    end)

    it('removes the copy and refunds if the original cannot be taken', function()
        local player = bagWith(makePlayer())

        confirmDualWield(player)
        player.failTakingSlot = 1
        pick(player, 'Yes, augment it')

        assert(player.gil == 10000000, 'the gil must be refunded, but the player has ' .. player.gil)
        assert(augmentIds(theOnlyItem(player)) == '', 'only the original should remain, unaugmented')
        assert(said(player):find('nothing was changed', 1, true))
    end)

    it('refuses if the item was moved away while the menus were open', function()
        local player = bagWith(makePlayer())

        confirmDualWield(player)
        player.items[1] = nil
        pick(player, 'Yes, augment it')

        assert(player.gil == 10000000, 'nothing should be charged')
        assert(said(player):find('no longer where you left it', 1, true), said(player))
    end)

    it('refuses if the item changed while the menus were open', function()
        local player = bagWith(makePlayer())

        confirmDualWield(player)
        player.items[1].exdata = augmentExdata({ { id = 144, value = 0 } })
        pick(player, 'Yes, augment it')

        assert(player.gil == 10000000 and augmentIds(theOnlyItem(player)) == '144:0', 'a changed item must not be swapped')
        assert(said(player):find('has changed', 1, true), said(player))
    end)

    it('refuses if the bag filled up while the menus were open', function()
        local player = bagWith(makePlayer({ capacity = 2 }))

        confirmDualWield(player)
        player.items[2] = makeItem(2)
        pick(player, 'Yes, augment it')

        assert(player.gil == 10000000, 'nothing should be charged')
        assert(said(player):find('free inventory slot', 1, true), said(player))
    end)

    it('forgets the conversation when the player cancels', function()
        local player = bagWith(makePlayer())

        confirmDualWield(player)
        player.menu.onCancelled(player, false)
        flow.commitAdd(player, 'dual_wield', 1)

        assert(player.gil == 10000000 and augmentIds(theOnlyItem(player)) == '', 'a cancelled conversation must not charge')
    end)
end)

describe('Augmenter: removing an augment', function()
    local twoAugments = { { id = 146, value = 2 }, { id = 144, value = 0 } } -- Dual Wield +3 (tier 3), Triple Attack +1 (tier 1)

    it('lists each augment with its removal price', function()
        local player = bagWith(makePlayer(), augmentExdata(twoAugments))

        trade(player, 1)
        pick(player, 'Remove an augment')

        assert(hasLabel(player, '1: Dual Wield +3 (15,000 gil)'), table.concat(labels(player), ' | '))
        assert(hasLabel(player, '2: Triple Attack +1% (5,000 gil)'), table.concat(labels(player), ' | '))
    end)

    it('removes the chosen augment and keeps the other', function()
        local player = bagWith(makePlayer(), augmentExdata(twoAugments))

        trade(player, 1)
        pick(player, 'Remove an augment')
        pick(player, '1: Dual Wield +3 (15,000 gil)')
        assert(player.menu.title == 'Remove Dual Wield +3 for 15,000 gil?', player.menu.title)
        pick(player, 'Yes, remove it')

        assert(augmentIds(theOnlyItem(player)) == '144:0', 'only Triple Attack should remain: ' .. augmentIds(theOnlyItem(player)))
        assert(player.gil == 10000000 - 15000, 'the gil taken was wrong: ' .. player.gil)
    end)

    it('gives back a plain item when the last augment is removed', function()
        local player = bagWith(makePlayer(), augmentExdata({ { id = 146, value = 0 } }))

        trade(player, 1)
        pick(player, 'Remove an augment')
        pick(player, '1: Dual Wield +1 (5,000 gil)')
        pick(player, 'Yes, remove it')

        local item = theOnlyItem(player)
        assert(augmentIds(item) == '' and core.readItem(item) ~= nil, 'the item should be plain and augmentable again')
    end)

    it('refuses without enough gil', function()
        local player = bagWith(makePlayer({ gil = 1000 }), augmentExdata({ { id = 146, value = 0 } }))

        trade(player, 1)
        pick(player, 'Remove an augment')
        pick(player, '1: Dual Wield +1 (5,000 gil)')

        assert(said(player):find('costs 5000', 1, true), said(player))
        assert(player.gil == 1000 and augmentIds(theOnlyItem(player)) == '146:0', 'nothing should change')
    end)
end)
