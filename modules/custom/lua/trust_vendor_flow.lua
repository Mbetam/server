-----------------------------------
-- Trust Vendor conversation: pick a group, pick a trust you do not know yet, confirm, pay, learn it.
-- Not a module (loaded by require). The list and the price are in trust_vendor_config.lua.
-----------------------------------
require('scripts/globals/trust')
local config = require('modules/custom/lua/trust_vendor_config')
-----------------------------------

local flow = {}

local npcName      = 'Trust Vendor'
local trustsPerPage = 6

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

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, npcName)
end

-- The menu is sent a moment later so the previous menu is fully closed first (each choice ends its menu).
local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- For tests only (see augmenter_flow.lua): a test process that exits with a real menu open crashes.
-- Call with nothing to go back to the real thing.
flow.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

local function menuFor(title, options)
    return { title = title, options = options, onCancelled = function() end }
end

-- The trusts of a group that the player does not know yet
local function unknownTrusts(player, group)
    local list = {}

    for _, trust in ipairs(group.trusts) do
        if not player:hasSpell(trust.spell) then
            table.insert(list, trust)
        end
    end

    return list
end

-- Looks a trust up by spell id; nil if the vendor does not sell it
local function findTrust(spellId)
    for _, group in ipairs(config.groups) do
        for _, trust in ipairs(group.trusts) do
            if trust.spell == spellId then
                return trust
            end
        end
    end

    return nil
end

-- Teaches the trust and takes the gil, after checking everything again. Returns true, or false and the reason.
flow.buy = function(player, spellId)
    local trust = findTrust(spellId)

    if trust == nil then
        return false, 'I do not sell that one.'
    end

    if config.needsPermit and not xi.trust.hasPermit(player) then
        return false, 'You need a Trust permit first. Finish the Trust quest in San d\'Oria, Bastok or Windurst.'
    end

    if player:hasSpell(spellId) then
        return false, string.format('You already know Trust: %s.', trust.name)
    end

    if player:getGil() < config.price then
        return false, string.format('Trust: %s costs %s gil. You do not have enough.', trust.name, formatGil(config.price))
    end

    if not player:delGil(config.price) then
        return false, 'You do not have enough gil.'
    end

    player:addSpell(spellId, { silentLog = true })
    player:printToPlayer(string.format('You learned Trust: %s!', trust.name), xi.msg.channel.SYSTEM_3)

    return true
end

local function confirmMenu(player, groupIndex, page, trust)
    sendMenu(player, menuFor(string.format('Learn Trust: %s for %s gil?', trust.name, formatGil(config.price)),
    {
        {
            'Yes',
            function(playerArg)
                local ok, reason = flow.buy(playerArg, trust.spell)

                if ok then
                    say(playerArg, string.format('Pleasure doing business! Trust: %s is yours.', trust.name))
                else
                    say(playerArg, reason)
                end
            end,
        },
        { 'No', function(playerArg) flow.showGroup(playerArg, groupIndex, page) end },
    }))
end

flow.showGroup = function(player, groupIndex, page)
    local group  = config.groups[groupIndex]
    local trusts = unknownTrusts(player, group)

    if #trusts == 0 then
        say(player, 'You already know every trust in that list.')
        flow.showGroups(player)

        return
    end

    local pages = math.max(1, math.ceil(#trusts / trustsPerPage))
    page        = math.max(1, math.min(page or 1, pages))

    local options = {}

    for index = (page - 1) * trustsPerPage + 1, math.min(page * trustsPerPage, #trusts) do
        local trust = trusts[index]

        table.insert(options, { trust.name, function(playerArg) confirmMenu(playerArg, groupIndex, page, trust) end })
    end

    if page < pages then
        table.insert(options, { 'Next page', function(playerArg) flow.showGroup(playerArg, groupIndex, page + 1) end })
    end

    if page > 1 then
        table.insert(options, { 'Previous page', function(playerArg) flow.showGroup(playerArg, groupIndex, page - 1) end })
    end

    table.insert(options, { 'Back', function(playerArg) flow.showGroups(playerArg) end })

    sendMenu(player, menuFor(string.format('%s (page %d of %d)', group.title, page, pages), options))
end

flow.showGroups = function(player)
    local options = {}

    for groupIndex, group in ipairs(config.groups) do
        local left = #unknownTrusts(player, group)

        if left > 0 then
            table.insert(options, { string.format('%s (%d)', group.title, left), function(playerArg) flow.showGroup(playerArg, groupIndex, 1) end })
        end
    end

    if #options == 0 then
        say(player, 'You already know every trust I sell!')

        return
    end

    sendMenu(player, menuFor(string.format('Every trust costs %s gil. Which kind?', formatGil(config.price)), options))
end

flow.onTrigger = function(player, npc)
    if config.needsPermit and not xi.trust.hasPermit(player) then
        say(player, 'I sell trusts you cannot find anywhere else, but you need a Trust permit first. Finish the Trust quest in San d\'Oria, Bastok or Windurst.')

        return
    end

    flow.showGroups(player)
end

return flow
