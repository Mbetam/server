-----------------------------------
-- Oboro (Ru'Lude Gardens since 2026-09-29, oboro_npc.lua): stores Pluton / Riftborn Boulder / Beitetsu and upgrades
-- Relic, Mythic and Empyrean weapons 99 -> 119 -> 119 III with them. Not a module (loaded by require).
-- A 119 III finishes the weapon for the JSE progression (jse_progress.lua): its family counts as done and the player's
-- active weapon slot clears.
-- The numbers and weapons are in oboro_config.lua.
-- Trade materials alone: they are stored. Trade one weapon alone: Oboro names the price, and on Yes takes it from the
-- stored balance. The weapon is taken first and the new one made after (they are Rare); if that fails, the weapon and
-- the materials come back.
-----------------------------------
local config   = require('modules/custom/lua/oboro_config')
local progress = require('modules/custom/jse_progression/jse_progress')
-----------------------------------

local flow = {}

local npcName  = 'Oboro'
local sessions = {} -- one pending upgrade per player: { itemId, nextId, container, slot, family, cost }

-- itemId -> { family, next, cost }
local byItem = {}

for family, chains in pairs(config.chains) do
    for _, chain in ipairs(chains) do
        for _, baseId in ipairs(chain.base) do
            byItem[baseId] = { family = family, next = chain.s119, cost = config.cost.to119 }
        end

        byItem[chain.s119] = { family = family, next = chain.s119iii, cost = config.cost.to119iii }

        if chain.s119ii then
            byItem[chain.s119ii] = { family = family, next = chain.s119iii, cost = config.cost.to119iii }
        end
    end
end

-- material item id -> family
local familyByMaterial = {}

for family, material in pairs(config.materials) do
    familyByMaterial[material.item] = family
end

flow.lookup = function(itemId)
    return byItem[itemId]
end

flow.getBalance = function(player, family)
    return player:getCharVar(config.materials[family].var)
end

local function setBalance(player, family, amount)
    player:setCharVar(config.materials[family].var, amount)
end

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, npcName)
end

local function balances(player)
    local parts = {}

    for _, family in ipairs({ 'relic', 'mythic', 'empyrean' }) do
        table.insert(parts, string.format('%s %d', config.materials[family].name, flow.getBalance(player, family)))
    end

    return table.concat(parts, ', ')
end

-- 'excalibur_119_iii' -> 'Excalibur 119 Iii' is ugly; use the name and the level of the stage instead
local function weaponName(itemId)
    local item = GetReadOnlyItem(itemId)
    local name = item and item:getName() or tostring(itemId)
    name = name:gsub('_119_iii$', ''):gsub('_119_ii$', ''):gsub('_119$', ''):gsub('_99_ii$', ''):gsub('_99$', '')

    return (name:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest) return first:upper() .. rest end))
end

local function stageName(itemId, entry)
    if entry and entry.next == nil then
        return '119 III'
    end

    for _, chains in pairs(config.chains) do
        for _, chain in ipairs(chains) do
            if itemId == chain.s119 then
                return '119'
            elseif itemId == chain.s119ii then
                return '119 II'
            elseif itemId == chain.s119iii then
                return '119 III'
            end
        end
    end

    return '99'
end

local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- For tests only: a test process that exits with a real menu open crashes
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
        return false, 'Trade me the weapon first.'
    end

    local item = player:getStorageItem(session.container, session.slot, 255)
    if item == nil or item:getID() ~= session.itemId then
        return false, 'That weapon is no longer where you left it, so nothing was changed.'
    end

    local balance = flow.getBalance(player, session.family)
    if balance < session.cost then
        return false, string.format('That takes %d %s and you have %d stored with me.', session.cost, config.materials[session.family].name, balance)
    end

    if not player:delItemAt(session.itemId, 1, session.container, session.slot) then
        return false, 'I could not take your weapon, so nothing was changed.'
    end

    setBalance(player, session.family, balance - session.cost)

    if player:addItem({ id = session.nextId, silent = true }) == nil then
        player:addItem({ id = session.itemId, silent = true })
        setBalance(player, session.family, balance)

        return false, 'I could not make the new weapon, so you have yours back and nothing was spent.'
    end

    if byItem[session.nextId] == nil then -- 119 III: the end of the line
        progress.finish(player, session.nextId)
    end

    return true
end

-- Stores every material in the trade. Returns true when the trade held only materials.
local function deposit(player, trade)
    local added = {}

    for slot = 0, 7 do
        local item = trade:getItem(slot)

        if item ~= nil then
            local family = familyByMaterial[item:getID()]

            if family == nil then
                return false
            end

            added[family] = (added[family] or 0) + trade:getSlotQty(slot)
        end
    end

    for family, amount in pairs(added) do
        if flow.getBalance(player, family) + amount > config.maxBalance then
            say(player, string.format('I cannot keep more than %d %s for you.', config.maxBalance, config.materials[family].name))

            return true
        end
    end

    for family, amount in pairs(added) do
        setBalance(player, family, flow.getBalance(player, family) + amount)
    end

    player:tradeComplete()
    say(player, 'Stored. You now have: ' .. balances(player) .. '.')

    return true
end

flow.onTrade = function(player, npc, trade)
    if trade:getGil() > 0 then
        say(player, 'Keep your gil. Trade me Pluton, Riftborn Boulder or Beitetsu to store, or one weapon to upgrade.')

        return
    end

    if deposit(player, trade) then
        return
    end

    local weapon = nil

    for slot = 0, 7 do
        local item = trade:getItem(slot)

        if item ~= nil then
            if weapon ~= nil or byItem[item:getID()] == nil then
                say(player, 'Trade me materials on their own to store them, or one Relic, Mythic or Empyrean weapon on its own.')

                return
            end

            weapon = item
        end
    end

    local entry = byItem[weapon:getID()]

    if entry.next == nil then
        say(player, 'That weapon is already at 119 III. There is nothing more I can do for it.')

        return
    end

    local material = config.materials[entry.family]
    local balance  = flow.getBalance(player, entry.family)
    local fromName = string.format('%s %s', weaponName(weapon:getID()), stageName(weapon:getID(), entry))
    local toName   = string.format('%s %s', weaponName(entry.next), stageName(entry.next, byItem[entry.next]))

    if balance < entry.cost then
        say(player, string.format('%s to %s takes %d %s. You have %d stored; trade me the rest first.', fromName, toName, entry.cost, material.name, balance))

        return
    end

    sessions[player:getID()] =
    {
        itemId    = weapon:getID(),
        nextId    = entry.next,
        container = weapon:getLocationID(),
        slot      = weapon:getSlotID(),
        family    = entry.family,
        cost      = entry.cost,
    }

    local options =
    {
        {
            'Yes',
            function(playerArg)
                local ok, failure = flow.commit(playerArg)

                if ok then
                    say(playerArg, string.format('Done! Your %s. %d %s left in store.', toName, flow.getBalance(playerArg, entry.family), material.name))
                else
                    say(playerArg, failure)
                end
            end,
        },
        { 'No', function(playerArg) flow.finish(playerArg) end },
    }

    sendMenu(player, { title = string.format('Make %s for %d %s?', toName, entry.cost, material.name), options = options, onCancelled = function(playerArg) flow.finish(playerArg) end })
end

flow.onTrigger = function(player, npc)
    say(player, 'I take Relic, Mythic and Empyrean weapons past their limits: 99 to 119 for 300, and 119 to 119 III for 1,000.')
    say(player, 'Relic weapons need Pluton, Mythic weapons Riftborn Boulders, Empyrean weapons Beitetsu. Trade them to me to store them first.')
    say(player, 'Stored with me: ' .. balances(player) .. '.')
end

return flow
