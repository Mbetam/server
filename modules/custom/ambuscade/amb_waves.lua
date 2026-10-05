-----------------------------------
-- Ambuscade (custom) 2: the wave run, a private copy of Maquette Abdhaljs-Legion B per party (instance 30100,
-- amb_config.lua). Not a module: the instance script scripts/zones/Maquette_Abdhaljs-Legion_B/instances/
-- ambuscade_waves.lua returns this table's instanceObject, and amb_npcs.lua hooks the Mhaura tome to `open`.
-- 1. The Ambuscade Tome in Mhaura: pick 3, 5, 7 or 10 waves; you and every party / alliance member near you go in.
-- 2. Inside, after a short wait, the waves come one at a time: a pack of Legion beasts, stronger each wave, then a
--    level 128 Paramount boss. The next wave comes a few seconds after the last monster of a wave falls.
-- 3. Clear the boss: everyone inside gets the run's Hallmarks and Gallantry. Out of time, or everyone KO'd for two
--    minutes: the run fails and pays half the Hallmarks for the share of waves cleared.
-- 4. The tome inside sends you back to Mhaura. When nobody is left inside, the instance closes.
-- The boss arena's helpers are reused (modules/custom/htbf/htbf_arena.lua: menus, party gathering, stat floors).
-----------------------------------
local config = require('modules/custom/ambuscade/amb_config')
local arena  = require('modules/custom/htbf/htbf_arena')
local shop   = require('modules/custom/ambuscade/amb_shop')
-----------------------------------

local waves = {}

local RUNNING = 0
local WON     = 1
local FAILED  = 2

local speaker = 'Ambuscade Tome'

local function say(player, message)
    arena.say(player, message, speaker)
end

local function tell(instance, message)
    for _, char in ipairs(arena.chars(instance)) do
        say(char, message)
    end
end

-- Back next to Gorpa-Masorpa in Mhaura
waves.toMhaura = function(player)
    local m = config.mhaura
    player:setPos(m.x, m.y, m.z, m.rotation, m.zoneId)
end

-- What a run pays on a clear, short
local function rewardText(run)
    return string.format('%s Hallmarks, %d Gallantry', shop.number(run.hallmarks), run.gallantry)
end

waves.rewardText = rewardText

-----------------------------------
-- 1: the tome in Mhaura
-----------------------------------
waves.open = function(player, runIndex)
    if GetSystemTime() - player:getLocalVar('AMB_OPENING') < 10 then
        return -- already opening one
    end

    player:setLocalVar('AMB_OPENING', GetSystemTime())
    player:setLocalVar('AMB_RUN', runIndex)
    player:createInstance(config.instance.instanceId)
end

waves.onTomeTrigger = function(player, npc)
    say(player, 'Waves of Legion beasts, each stronger than the last, then a level 128 boss. Your party / alliance near you comes too. Free, no limits.')

    local options = {}

    for runIndex, run in ipairs(config.runs) do
        say(player, string.format('%d waves, %d minutes: %s each.', run.waves, run.minutes, rewardText(run)))
        table.insert(options, { string.format('%d waves', run.waves), function(playerArg) waves.open(playerArg, runIndex) end })
    end

    table.insert(options, { 'Not now', function() end })

    arena.sendMenu(player, { title = 'Ambuscade: how many waves?', options = options })
end

-----------------------------------
-- 2: the waves
-----------------------------------
-- The living monsters of this run
waves.monsters = function(instance)
    local list = {}

    for _, mob in pairs(instance:getMobs()) do
        if mob:isSpawned() and mob:isAlive() and string.sub(mob:getName(), 1, 7) == 'DE_AMB_' then
            table.insert(list, mob)
        end
    end

    return list
end

-- Sends a monster away (a table field so tests can swap it)
waves.despawn = function(mob, instance)
    DespawnMob(mob:getID(), instance)
end

-- Every regular wave's numbers, a straight line from `first` (wave 1) to `last` (the wave before the boss)
waves.scaleFor = function(wave, regularWaves)
    local first, last = config.waveScale.first, config.waveScale.last
    local t           = regularWaves > 1 and (wave - 1) / (regularWaves - 1) or 1
    local scale       = {}

    for key, from in pairs(first) do
        scale[key] = math.floor(from + (last[key] - from) * t + 0.5)
    end

    return scale
end

-- Which stage (config.stages) a regular wave draws from: the stages spread evenly over the run
waves.stageFor = function(wave, regularWaves)
    return math.max(1, math.min(#config.stages, math.ceil(wave / regularWaves * #config.stages)))
end

-- TP moves sooner, as in the boss arena: once TP passes a rolled goal, a random move from the monster's list
local function onMobFight(mob, target)
    local goal = mob:getLocalVar('AMB_TP_GOAL')

    if goal == 0 then
        goal = math.random(config.tpUse.min, config.tpUse.max)
        mob:setLocalVar('AMB_TP_GOAL', goal)
    end

    local action = mob:getCurrentAction()

    if mob:getTP() >= goal and action ~= 30 and action ~= 34 and action ~= 3 and action ~= 6 then
        mob:setLocalVar('AMB_TP_GOAL', 0)
        mob:useMobAbility()
    end
end

local floorKeys = { 'acc', 'att', 'def', 'eva', 'meva', 'mdb' }

waves.scale = function(mob, s)
    mob:setMobLevel(s.level)
    mob:setMaxHP(s.hp)
    mob:setHP(s.hp)
    mob:addMod(xi.mod.MATT, s.matt or 0)
    mob:addMod(xi.mod.MACC, s.macc or 0)
    mob:addMod(xi.mod.INT, s.stat or 0)
    mob:addMod(xi.mod.MND, s.stat or 0)

    local floors = {}

    for _, key in ipairs(floorKeys) do
        floors[key] = s[key]
    end

    arena.applyFloors(mob, floors)
end

-- One monster of group `entry` ({ group id, name }), the `index`-th of `count` around the spawn point
local function spawnOne(instance, entry, s, index, count, target)
    local pos   = config.instance.spawn
    local angle = 2 * math.pi * (index - 1) / count
    local x     = count > 1 and pos[1] + config.instance.spread * math.cos(angle) or pos[1]
    local z     = count > 1 and pos[3] + config.instance.spread * math.sin(angle) or pos[3]

    local mob = instance:insertDynamicEntity(
    {
        objtype              = xi.objType.MOB,
        name                 = 'AMB_' .. string.gsub(entry[2], ' ', '_'),
        packetName           = entry[2],
        x                    = x,
        y                    = pos[2],
        z                    = z,
        rotation             = pos[4],
        groupId              = entry[1],
        groupZoneId          = xi.zone.MAQUETTE_ABDHALJS_LEGION_B,
        minLevel             = s.level,
        maxLevel             = s.level,
        releaseIdOnDisappear = true,
        onMobFight           = onMobFight,
    })

    if mob == nil then
        print(string.format('[ambuscade] could not create %s (group %d)', entry[2], entry[1]))

        return nil
    end

    mob:setRespawnTime(0)
    mob:setDropID(0)
    mob:setSpawn(x, pos[2], z, pos[4])
    mob:spawn()
    waves.scale(mob, s)

    if target and target:isAlive() then
        mob:updateEnmity(target)
    end

    return mob
end

-- A living player inside to send the wave at
local function someoneAlive(instance)
    local alive = {}

    for _, char in ipairs(arena.chars(instance)) do
        if char:isAlive() then
            table.insert(alive, char)
        end
    end

    return #alive > 0 and alive[math.random(1, #alive)] or nil
end

-- Spawns wave number `wave` of the run. Returns the monsters.
waves.spawnWave = function(instance, wave)
    local run     = config.runs[instance:getLocalVar('run')]
    local regular = run.waves - 1
    local spawned = {}

    instance:setLocalVar('wave', wave)

    if wave >= run.waves then
        local entry = config.bosses[math.random(1, #config.bosses)]
        local boss  = spawnOne(instance, entry, config.boss, 1, 1, someoneAlive(instance))

        if boss then
            boss:addImmunity(xi.immunity.DARK_SLEEP)
            boss:addImmunity(xi.immunity.LIGHT_SLEEP)
            boss:addImmunity(xi.immunity.PETRIFY)
            boss:addImmunity(xi.immunity.TERROR)
            table.insert(spawned, boss)
        end

        tell(instance, string.format('Final wave: %s (level %d)!', entry[2], config.boss.level))

        return spawned
    end

    local stage = config.stages[waves.stageFor(wave, regular)]
    local s     = waves.scaleFor(wave, regular)
    local count = config.pack(wave, regular, #arena.chars(instance))

    for index = 1, count do
        local mob = spawnOne(instance, stage.groups[math.random(1, #stage.groups)], s, index, count, someoneAlive(instance))

        if mob then
            table.insert(spawned, mob)
        end
    end

    tell(instance, string.format('Wave %d of %d: %d %s beasts (level %d)!', wave, run.waves, count, stage.name, s.level))

    return spawned
end

-----------------------------------
-- 3: the end of a run
-----------------------------------
-- What each player gets: hallmarks, gallantry
waves.payout = function(run, won, cleared)
    if won then
        return run.hallmarks, run.gallantry
    end

    return math.floor(run.hallmarks * cleared / run.waves / 2), 0
end

waves.finish = function(instance, won, why)
    local run     = config.runs[instance:getLocalVar('run')]
    local cleared = won and run.waves or instance:getLocalVar('cleared')

    instance:setLocalVar('state', won and WON or FAILED)

    for _, mob in ipairs(waves.monsters(instance)) do
        waves.despawn(mob, instance)
    end

    local hallmarks, gallantry = waves.payout(run, won, cleared)
    local number               = shop.number

    for _, char in ipairs(arena.chars(instance)) do
        char:countdown()

        if hallmarks > 0 then
            char:addCurrency('current_hallmarks', hallmarks)
            char:addCurrency('total_hallmarks', hallmarks)
        end

        if gallantry > 0 then
            char:addCurrency('gallantry', gallantry)
        end

        if won then
            say(char, string.format('Ambuscade cleared! You earn %s Hallmarks and %d Gallantry. Spend them with Gorpa-Masorpa.', number(hallmarks), gallantry))
        else
            say(char, string.format('%s %d of %d waves cleared: you earn %s Hallmarks.', why, cleared, run.waves, number(hallmarks)))
        end

        say(char, 'Read me to go back to Mhaura.')
    end
end

-----------------------------------
-- 4: the tome inside
-----------------------------------
waves.onExitTrigger = function(player, npc)
    local instance = player:getInstance()
    local running  = instance and instance:getLocalVar('state') == RUNNING

    arena.sendMenu(player,
    {
        title   = running and 'Leave? You lose this run\'s rewards.' or 'Back to Mhaura?',
        options =
        {
            { 'Yes', function(playerArg) waves.toMhaura(playerArg) end },
            { 'No', function() end },
        },
    })
end

-----------------------------------
-- The instance script (scripts/zones/Maquette_Abdhaljs-Legion_B/instances/ambuscade_waves.lua returns this)
-----------------------------------
local instanceObject = {}

instanceObject.onInstanceCreated = function(instance)
    local t = config.instance.tome

    instance:insertDynamicEntity(
    {
        objtype    = xi.objType.NPC,
        name       = t.name,
        packetName = t.packetName,
        look       = t.look,
        x          = t.pos[1],
        y          = t.pos[2],
        z          = t.pos[3],
        rotation   = t.pos[4],
        widescan   = 1,
        onTrigger  = waves.onExitTrigger,
    })
end

instanceObject.onInstanceCreatedCallback = function(player, instance)
    player:setLocalVar('AMB_OPENING', 0)

    if instance == nil then
        say(player, 'The Ambuscade could not be opened. Please try again.')

        return
    end

    local runIndex = player:getLocalVar('AMB_RUN')
    local run      = config.runs[runIndex]
    local now      = GetSystemTime()

    instance:setLocalVar('run', runIndex)
    instance:setLocalVar('state', RUNNING)
    instance:setLocalVar('wave', 0)
    instance:setLocalVar('nextWaveAt', now + config.instance.waveDelay + 10) -- 10 s more to zone in
    instance:setLocalVar('endAt', now + run.minutes * 60 + 10)

    local entry = config.instance.entry

    for _, member in ipairs(arena.group(player)) do
        if member:getID() ~= player:getID() then
            say(member, string.format('%s is taking your party into a %d-wave Ambuscade.', player:getName(), run.waves))
        end

        member:setInstance(instance)
        member:setPos(entry[1], entry[2], entry[3], entry[4], config.instance.zoneId)
    end
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()

    if instance == nil then
        return
    end

    local run = config.runs[instance:getLocalVar('run')]

    if run then
        say(player, string.format('%d waves, then the boss. The first wave comes in a few seconds. Good luck!', run.waves))
        player:countdown(math.max(0, instance:getLocalVar('endAt') - GetSystemTime()))
    end
end

-- Every second (every 40 s until someone is inside)
instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    local chars = arena.chars(instance)
    local now   = GetSystemTime()

    -- Nobody left inside: close
    if #chars == 0 then
        if instance:getLocalVar('emptySince') == 0 then
            instance:setLocalVar('emptySince', now)
        elseif now - instance:getLocalVar('emptySince') >= config.instance.emptySeconds then
            instance:fail()
        end

        return
    end

    instance:setLocalVar('emptySince', 0)

    if instance:getLocalVar('state') ~= RUNNING then
        return
    end

    if now >= instance:getLocalVar('endAt') then
        waves.finish(instance, false, 'Time is up!')

        return
    end

    local run = config.runs[instance:getLocalVar('run')]

    -- A wave is on: watch for a wipe
    if #waves.monsters(instance) > 0 then
        local allDown = true

        for _, char in ipairs(chars) do
            if char:isAlive() then
                allDown = false
                break
            end
        end

        if not allDown then
            instance:setLocalVar('wipeAt', 0)
        elseif instance:getLocalVar('wipeAt') == 0 then
            instance:setLocalVar('wipeAt', now)
        elseif now - instance:getLocalVar('wipeAt') >= config.instance.wipeSeconds then
            waves.finish(instance, false, 'Everyone fell!')
        end

        return
    end

    instance:setLocalVar('wipeAt', 0)

    local wave = instance:getLocalVar('wave')

    -- The wave just fell
    if instance:getLocalVar('nextWaveAt') == 0 then
        instance:setLocalVar('cleared', wave)

        if wave >= run.waves then
            waves.finish(instance, true)

            return
        end

        instance:setLocalVar('nextWaveAt', now + config.instance.waveDelay)
        tell(instance, string.format('Wave %d cleared! The next wave comes in %d seconds.', wave, config.instance.waveDelay))

        return
    end

    if now >= instance:getLocalVar('nextWaveAt') then
        instance:setLocalVar('nextWaveAt', 0)
        waves.spawnWave(instance, wave + 1)
    end
end

instanceObject.onInstanceFailure = function(instance)
end

instanceObject.onInstanceComplete = function(instance)
end

instanceObject.onInstanceProgressUpdate = function(instance, progress)
end

instanceObject.onEventUpdate = function(player, csid, option, npc)
end

instanceObject.onEventFinish = function(player, csid, option, npc)
end

waves.instanceObject = instanceObject

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.ambuscadeWaves = waves -- for tests

return waves
