-----------------------------------
-- Daily hunts: giving, tracking and paying them. Not a module (loaded by require): hunt_board.lua counts the kills,
-- the Hunt Board NPC and !hunt show them, the Armor Upgrader spends Hunt Marks.
-- A player's hunts are made the first time they are looked at (or a kill is counted) after JST midnight, from their
-- main job level at that moment, and kept in char vars until the next JST midnight.
-----------------------------------
local config = require('modules/custom/lua/hunt_config')
local data   = require('modules/custom/lua/hunt_data')
-----------------------------------

local core = {}

local KIND_KILL = 1
local KIND_NM   = 2

core.KIND_KILL = KIND_KILL
core.KIND_NM   = KIND_NM

local killByKey = {}

for _, entry in ipairs(data.kills) do
    killByKey[entry.zone * 1000 + entry.family] = entry
end

core.huntCount = function()
    return config.killHunts + config.nmHunts
end

local function var(n, field)
    return string.format('HUNT_%d_%s', n, field)
end

-- The target of a hunt key: the kill entry or the NM entry
core.target = function(kind, key)
    if kind == KIND_KILL then
        return killByKey[key]
    end

    return data.nms[key]
end

-----------------------------------
-- Hunt Marks
-----------------------------------

core.getMarks = function(player)
    return player:getCharVar(config.var.marks)
end

core.addMarks = function(player, amount)
    player:setCharVar(config.var.marks, core.getMarks(player) + amount)
end

-- Takes the marks if the player has them; returns true when taken
core.spendMarks = function(player, amount)
    local marks = core.getMarks(player)

    if marks < amount then
        return false
    end

    player:setCharVar(config.var.marks, marks - amount)

    return true
end

-----------------------------------
-- Choosing targets
-----------------------------------

-- Kill entries whose usual levels overlap the window around level, widening until at least `wanted` fit
local function killCandidates(level, wanted)
    local below, above = config.window.below, config.window.above

    for _ = 1, 20 do
        local list = {}

        for key, entry in pairs(killByKey) do
            if entry.low <= level + above and entry.high >= level - below then
                table.insert(list, key)
            end
        end

        if #list >= wanted then
            return list
        end

        below = below + config.window.widen
        above = above + config.window.widen
    end

    return {}
end

local function nmCandidates(level)
    local below, above = config.window.below + 2, config.window.above + 1

    for _ = 1, 20 do
        local list = {}

        for key, entry in pairs(data.nms) do
            if entry.low <= level + above and entry.high >= level - below then
                table.insert(list, key)
            end
        end

        if #list >= 3 then
            return list
        end

        below = below + config.window.widen
        above = above + config.window.widen
    end

    return {}
end

-- Picks a key from the list that is not in `taken`
local function pick(list, taken)
    local free = {}

    for _, key in ipairs(list) do
        if not taken[key] then
            table.insert(free, key)
        end
    end

    if #free == 0 then
        return nil
    end

    return free[math.random(1, #free)]
end

local function setHunt(player, n, kind, key)
    local need = 1

    if kind == KIND_KILL then
        need = math.random(config.killCount.min, config.killCount.max)
    end

    player:setCharVar(var(n, 'KIND'), kind)
    player:setCharVar(var(n, 'KEY'), key)
    player:setCharVar(var(n, 'NEED'), need)
    player:setCharVar(var(n, 'HAVE'), 0)
    player:setCharVar(var(n, 'PAID'), 0)
end

-- Makes today's hunts
core.assign = function(player)
    local level = player:getMainLvl()
    local taken = {}
    local n     = 0

    local kills = killCandidates(level, config.killHunts)

    for _ = 1, config.killHunts do
        local key = pick(kills, taken)

        if key then
            n = n + 1
            taken[key] = true
            setHunt(player, n, KIND_KILL, key)
        end
    end

    local nms = nmCandidates(level)

    for _ = 1, config.nmHunts do
        local key = pick(nms, taken)

        if key then
            n = n + 1
            taken[key] = true
            setHunt(player, n, KIND_NM, key)
        end
    end

    -- Clear any slot left over (fewer targets than slots)
    for rest = n + 1, core.huntCount() do
        player:setCharVar(var(rest, 'KIND'), 0)
    end

    player:setCharVar(config.var.day, JstMidnight())
    player:setCharVar(config.var.rerolls, 0)
    player:setCharVar(config.var.bonus, 0)
end

-- Makes new hunts if the day has turned since they were made
core.refresh = function(player)
    if player:getCharVar(config.var.day) ~= JstMidnight() then
        core.assign(player)

        return true
    end

    return false
end

-- Today's hunts: { { n, kind, key, need, have, paid, target }, ... }
core.list = function(player)
    core.refresh(player)

    local hunts = {}

    for n = 1, core.huntCount() do
        local kind = player:getCharVar(var(n, 'KIND'))

        if kind ~= 0 then
            local key = player:getCharVar(var(n, 'KEY'))

            table.insert(hunts,
            {
                n      = n,
                kind   = kind,
                key    = key,
                need   = player:getCharVar(var(n, 'NEED')),
                have   = player:getCharVar(var(n, 'HAVE')),
                paid   = player:getCharVar(var(n, 'PAID')) == 1,
                target = core.target(kind, key),
            })
        end
    end

    return hunts
end

-----------------------------------
-- Messages
-----------------------------------

core.say = function(player, message)
    player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
end

core.describe = function(hunt)
    local target = hunt.target

    if target == nil then
        return string.format('%d. (this hunt\'s target no longer exists; reroll it)', hunt.n)
    end

    local state = hunt.paid and 'DONE' or string.format('%d/%d', hunt.have, hunt.need)

    if hunt.kind == KIND_KILL then
        return string.format('%d. Kill %d %s-family monsters in %s (Lv.%d-%d): %s', hunt.n, hunt.need, target.name, target.zoneName, target.low, target.high, state)
    end

    return string.format('%d. NM: defeat %s in %s (Lv.%d-%d): %s', hunt.n, target.display, target.zoneName, target.low, target.high, state)
end

-- Shows the hunts, the marks and when they reset
core.show = function(player)
    local hunts = core.list(player)

    core.say(player, string.format('Daily hunts (new ones at JST midnight). Hunt Marks: %d', core.getMarks(player)))

    for _, hunt in ipairs(hunts) do
        core.say(player, core.describe(hunt))
    end

    local left = config.rerollsPerDay - player:getCharVar(config.var.rerolls)
    core.say(player, string.format('Rerolls left today: %d (!hunt reroll <number>).', math.max(0, left)))
end

-----------------------------------
-- Rewards
-----------------------------------

local function giveTrophy(player)
    local missing = {}

    for _, itemId in ipairs(config.trophies) do
        if not player:hasItem(itemId) then
            table.insert(missing, itemId)
        end
    end

    if #missing > 0 then
        local itemId = missing[math.random(1, #missing)]

        if npcUtil.giveItem(player, itemId) then
            return
        end
    end

    core.addMarks(player, config.trophyMarksIfFull)
    core.say(player, string.format('You could not hold another trophy, so you get %d extra Hunt Marks.', config.trophyMarksIfFull))
end

local function pay(player, hunt)
    local reward = hunt.kind == KIND_KILL and config.rewards.kill or config.rewards.nm
    local level  = player:getMainLvl()
    local exp    = math.floor((reward.expBase + level * level * reward.expPerLevel2) * xi.settings.main.BOOK_EXP_RATE)
    local gil    = level * reward.gilPerLevel

    player:setCharVar(var(hunt.n, 'PAID'), 1)
    core.say(player, string.format('Hunt complete! %s', core.describe({ n = hunt.n, kind = hunt.kind, need = hunt.need, have = hunt.need, paid = true, target = hunt.target })))

    player:addExp(exp)
    player:addGil(gil)
    core.addMarks(player, reward.marks)
    core.say(player, string.format('You receive %d gil and %d Hunt Marks.', gil, reward.marks))

    if hunt.kind == KIND_NM then
        giveTrophy(player)
    end

    -- All of today's hunts done?
    if player:getCharVar(config.var.bonus) == 0 then
        for n = 1, core.huntCount() do
            if player:getCharVar(var(n, 'KIND')) ~= 0 and player:getCharVar(var(n, 'PAID')) ~= 1 then
                return
            end
        end

        player:setCharVar(config.var.bonus, 1)
        core.addMarks(player, config.rewards.allDoneMarks)
        core.say(player, string.format('All of today\'s hunts are done: %d bonus Hunt Marks!', config.rewards.allDoneMarks))
    end
end

-- A monster died and the player gets credit for it (killer or an alliance member in the zone)
core.onKill = function(player, mob)
    if not mob:isMob() or mob:getZoneID() ~= player:getZoneID() then
        return
    end

    core.refresh(player)

    for n = 1, core.huntCount() do
        local kind = player:getCharVar(var(n, 'KIND'))

        if kind ~= 0 and player:getCharVar(var(n, 'PAID')) ~= 1 then
            local key    = player:getCharVar(var(n, 'KEY'))
            local target = core.target(kind, key)
            local counts = false

            if target and target.zone == mob:getZoneID() then
                if kind == KIND_KILL then
                    counts = mob:getFamily() == target.family
                else
                    counts = mob:getName() == target.name
                end
            end

            if counts then
                local need = player:getCharVar(var(n, 'NEED'))
                local have = math.min(need, player:getCharVar(var(n, 'HAVE')) + 1)
                player:setCharVar(var(n, 'HAVE'), have)

                local hunt = { n = n, kind = kind, key = key, need = need, have = have, target = target }

                if have >= need then
                    pay(player, hunt)
                elseif kind == KIND_KILL then
                    core.say(player, string.format('Hunt %d: %d/%d %s', n, have, need, target.name))
                end
            end
        end
    end
end

-- Swaps an unfinished hunt for a new one of the same kind. Returns true, or false and a reason.
core.reroll = function(player, n)
    core.refresh(player)

    local kind = player:getCharVar(var(n, 'KIND'))

    if kind == 0 then
        return false, 'There is no hunt with that number.'
    end

    if player:getCharVar(var(n, 'PAID')) == 1 then
        return false, 'That hunt is already done.'
    end

    if player:getCharVar(config.var.rerolls) >= config.rerollsPerDay then
        return false, 'You have no rerolls left today.'
    end

    local taken = {}

    for other = 1, core.huntCount() do
        taken[player:getCharVar(var(other, 'KEY'))] = true
    end

    local list = kind == KIND_KILL and killCandidates(player:getMainLvl(), config.killHunts + 1) or nmCandidates(player:getMainLvl())
    local key  = pick(list, taken)

    if key == nil then
        return false, 'There is no other hunt for your level right now.'
    end

    setHunt(player, n, kind, key)
    player:setCharVar(config.var.rerolls, player:getCharVar(config.var.rerolls) + 1)

    return true
end

return core
