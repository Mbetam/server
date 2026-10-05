-----------------------------------
-- !gotoexp (Eric, 2026-10-05: free, no cooldown, the party leader can bring the party). Not a module: the command
-- (modules/custom/commands/gotoexp.lua) and the tests require it.
-- Camps come from gotoexp_data.lua (generated: open-world zones, monster families with their usual levels and spawn
-- counts, and a safe landing spot: the zone's Home Point or Survival Guide). For a level, a zone scores the spawns of
-- its families that sit 1-5 levels above it (good EXP, still killable), each weighted by how much of its level range
-- fits; the window widens when too few zones fit.
-- The level is the lowest main job level of the party members in the zone (level sync lowers it already).
-----------------------------------
local data = require('modules/custom/lua/gotoexp_data')
local qol  = require('modules/custom/lua/qol_common')
-----------------------------------

local core = {}

core.campCount = 3
-- Families whose usual levels spread over more than this are skipped
core.maxSpread = 40
-- Level windows tried in order, relative to the party's level: { lowest, highest }
core.windows   = { { 1, 5 }, { 0, 8 }, { -3, 12 } }
-- The whole menu (title and options) must fit the 150-byte chat packet the client gets it in
core.menuLimit = 149

local function say(player, message)
    qol.say(player, message)
end

-- Party members in the leader's zone (players only), the leader included
core.partyHere = function(player)
    local list = {}

    for _, member in ipairs(player:getParty() or { player }) do
        if member:isPC() and member:getZoneID() == player:getZoneID() then
            table.insert(list, member)
        end
    end

    if #list == 0 then
        table.insert(list, player)
    end

    return list
end

core.isLeader = function(player)
    local leader = player:getPartyLeader()

    return leader ~= nil and leader:getID() == player:getID()
end

core.level = function(player)
    local level = player:getMainLvl()

    for _, member in ipairs(core.partyHere(player)) do
        level = math.min(level, member:getMainLvl())
    end

    return level
end

-- The best camps for a level: { zone, name, landing, families = { name, ... }, best (family), low, high (its levels),
-- score }
core.camps = function(level, count)
    count = count or core.campCount
    local result = {}

    for _, window in ipairs(core.windows) do
        local lo, hi = level + window[1], level + window[2]
        result = {}

        for zoneId, zone in pairs(data.zones) do
            local score, names, best, bestScore = 0, {}, nil, 0

            for _, family in ipairs(zone.families) do
                local low, high, spawns = family[2], family[3], family[4]
                local overlap = math.min(high, hi) - math.max(low, lo) + 1

                -- A family spread over 40+ levels (bats or skeletons all over a zone) says little about any one camp
                if overlap > 0 and high - low <= core.maxSpread then
                    -- Weighted by how much of the family's level range fits the window
                    local weight = spawns * overlap / (high - low + 1)

                    score = score + weight
                    table.insert(names, family[1])

                    if weight > bestScore then
                        best, bestScore = family, weight
                    end
                end
            end

            if score > 0 then
                table.insert(result, { zone = zoneId, name = zone.name, landing = zone.landing, families = names, best = best[1], low = best[2], high = best[3], score = score })
            end
        end

        if #result >= count then
            break
        end
    end

    table.sort(result, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end

        return a.zone < b.zone
    end)

    local top = {}
    for i = 1, math.min(count, #result) do
        top[i] = result[i]
    end

    return top
end

-- Menu labels: zone, its best-fitting monsters and their levels, shortened until the menu fits the packet
core.labels = function(title, camps)
    local function build(withFamilies)
        local labels = {}

        for _, camp in ipairs(camps) do
            if withFamilies then
                table.insert(labels, string.format('%s (%s %d-%d)', camp.name, camp.best, camp.low, camp.high))
            else
                table.insert(labels, string.format('%s %d-%d', camp.name, camp.low, camp.high))
            end
        end

        return labels
    end

    local function size(labels)
        local n = #title + 2

        for _, label in ipairs(labels) do
            n = n + #label + 3
        end

        return n
    end

    local labels = build(true)
    if size(labels) > core.menuLimit then
        labels = build(false)
    end

    return labels
end

-- Teleports a player to a camp's landing spot
core.send = function(player, camp)
    local l = camp.landing

    if player:getZoneID() == camp.zone then
        player:setPos(l[1], l[2], l[3], l[4])
    else
        player:setPos(l[1], l[2], l[3], l[4], camp.zone)
    end
end

-- Sends the player (and, if asked, the party members in the zone who are free to go) to a camp
core.go = function(player, camp, withParty)
    local reason = qol.blockedReason(player)
    if reason then
        say(player, reason)
        return 0
    end

    local sent = 0
    local group = withParty and core.partyHere(player) or { player }

    for _, member in ipairs(group) do
        if member:getID() == player:getID() or qol.blockedReason(member) == nil then
            if member:getID() ~= player:getID() then
                say(member, string.format('%s is taking the party to %s.', player:getName(), camp.name))
            end

            core.send(member, camp)
            sent = sent + 1
        else
            say(player, string.format('%s can\'t come along right now.', member:getName()))
        end
    end

    say(player, string.format('Heading to %s (%s, Lv.%d-%d).', camp.name, table.concat(camp.families, ', '), camp.low, camp.high))

    return sent
end

-- Menus. sendMenu is swappable for tests (a test process that exits with a real menu open crashes).
local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

core.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

local function partyChoice(player, camp)
    sendMenu(player,
    {
        title   = camp.name .. ': who goes?',
        options =
        {
            { 'Just me', function(playerArg) core.go(playerArg, camp, false) end },
            { 'Bring party', function(playerArg) core.go(playerArg, camp, true) end },
        },
        onCancelled = function() end,
    })
end

-- !gotoexp: the menu of camps for the party's level
core.open = function(player)
    local reason = qol.blockedReason(player)
    if reason then
        say(player, reason)
        return
    end

    local level = core.level(player)
    local camps = core.camps(level)

    if #camps == 0 then
        say(player, 'No EXP camp found for level ' .. level .. '.')
        return
    end

    local title   = string.format('EXP camps, Lv.%d', level)
    local labels  = core.labels(title, camps)
    local leading = core.isLeader(player) and #core.partyHere(player) > 1
    local options = {}

    for i, camp in ipairs(camps) do
        table.insert(options, { labels[i], function(playerArg)
            if leading then
                partyChoice(playerArg, camp)
            else
                core.go(playerArg, camp, false)
            end
        end })
    end

    sendMenu(player, { title = title, options = options, onCancelled = function() end })
end

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.gotoexp = core -- for tests

return core
