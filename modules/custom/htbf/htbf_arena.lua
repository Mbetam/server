-----------------------------------
-- Boss arenas for Rem's Tales: the arena itself, a private copy of Maquette Abdhaljs-Legion A per party (instance
-- 18300, htbf_config.lua). Not a module: the instance script scripts/zones/Maquette_Abdhaljs-Legion_A/instances/
-- htbf_arena.lua returns this table, and htbf_hub.lua uses its helpers.
-- 1. The Battle Archivist opens a new arena for the tier picked; the one who asked and every party / alliance member
--    near them are moved in.
-- 2. Inside: the Arena Moogle lists the tier's bosses. Picking one spawns a copy of it after a few seconds: built from
--    its mob group, fighting with its retail script's fight hooks (if it has one) and its job two-hours, scaled to the
--    tier on spawn. One boss at a time; 30 minutes each; if everyone inside is KO'd for 3 minutes the boss leaves.
-- 3. On the kill every player inside gets their own personal drops, and the boss's loot goes to the treasure pool.
-- 4. The Arena Exit sends you back to the Archivist. When nobody is left inside, the arena closes.
-----------------------------------
local config = require('modules/custom/htbf/htbf_config')
-----------------------------------

local arena = {}

-----------------------------------
-- Helpers, shared with the hub
-----------------------------------
arena.say = function(player, message, speaker)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, speaker or 'Battle Archivist')
end

local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- The whole menu (title and options, each quoted) goes out in one chat packet with a 150-byte text field; anything
-- longer is cut off, losing the last options. Keep menus short and put the details in chat lines.
arena.menuLength = function(menu)
    local length = #menu.title + 2

    for _, option in ipairs(menu.options) do
        length = length + #option[1] + 2
    end

    return length
end

arena.menuLimit = 149

arena.sendMenu = function(player, menu)
    if arena.menuLength(menu) > arena.menuLimit then
        print(string.format('[htbf] menu "%s" is %d bytes, over %d: its last options will be cut off', menu.title, arena.menuLength(menu), arena.menuLimit))
    end

    sendMenu(player, menu)
end

-- For tests only: a test process that exits with a real menu open crashes
arena.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

-- Runs fn(entity) after ms. An entity timer on the server; tests swap it (the test harness does not run timers).
arena.schedule = function(entity, ms, fn)
    entity:timer(ms, fn)
end

-- The player and every party / alliance member near them in the same zone
arena.group = function(player)
    local members = {}

    for _, member in pairs(player:getAlliance()) do
        if member:isPC() and member:getZoneID() == player:getZoneID() and member:checkDistance(player) <= config.partyRange then
            table.insert(members, member)
        end
    end

    if #members == 0 then
        table.insert(members, player)
    end

    return members
end

-- Back to the Battle Archivist in Western Adoulin
arena.toArchivist = function(player)
    local a = config.archivist
    player:setPos(a.x, a.y, a.z, a.rotation, a.zoneId)
end

-----------------------------------
-- 1: opening an arena
-----------------------------------
-- Called by the Battle Archivist. The instance is built in the background; onInstanceCreatedCallback moves the group in.
arena.open = function(player, tier)
    if GetSystemTime() - player:getLocalVar('HTBF_OPENING') < 10 then
        return -- already opening one
    end

    player:setLocalVar('HTBF_OPENING', GetSystemTime())
    player:setLocalVar('HTBF_TIER', tier)
    player:createInstance(config.arena.instanceId)
end

-- What a boss gives each player, short (chat lines are cut at 150 bytes too)
local function rewardText(boss)
    local parts = {}

    for _, p in ipairs(boss.personal or {}) do
        if p.chapter then
            table.insert(parts, 'Ch' .. p.chapter)
        elseif p.jobCard then
            table.insert(parts, 'cards')
        elseif p.item or p.oneOf then
            table.insert(parts, 'box')
        end
    end

    return table.concat(parts, ', ')
end

arena.rewardText = rewardText

-- The Moogle's line: what each boss of the tier gives everyone inside
arena.rewardLine = function(tier)
    local rewards = {}

    for _, boss in ipairs(config.bosses[tier] or {}) do
        table.insert(rewards, string.format('%s %s', boss.name, rewardText(boss)))
    end

    return 'You each get: ' .. table.concat(rewards, ', ') .. '. Loot to roll too.'
end

-- The players inside (a table field so tests can swap it)
arena.chars = function(instance)
    local chars = {}

    for _, char in pairs(instance:getChars()) do
        table.insert(chars, char)
    end

    return chars
end

local function tell(instance, message)
    for _, char in ipairs(arena.chars(instance)) do
        arena.say(char, message, 'Arena Moogle')
    end
end

-----------------------------------
-- 2: the bosses
-----------------------------------
-- The retail script's hooks a copy may borrow: fight behaviour only. Never onMobDeath / onMobDespawn (titles,
-- respawn timers and pop bookkeeping of the real NM).
local borrowable =
{
    'onMobInitialize', 'onMobSpawn', 'onMobRoam', 'onMobEngage', 'onMobFight', 'onMobDisengage',
    'onMobMobskillChoose', 'onMobSpellChoose', 'onMobWeaponSkill', 'onMobWeaponSkillPrepare',
    'onAdditionalEffect', 'onSpikesDamage', 'onCriticalHit', 'onSpellPrecast', 'onMobMagicPrepare',
}

local scripts = {}

-- The walkable square of the arena wing (htbf_config.lua), with a little margin
local function insideWing(entity)
    local x, z = entity:getXPos(), entity:getZPos()

    return x >= 128 and x <= 192 and z >= -190 and z <= -126
end

arena.insideWing = insideWing

-- The retail fight hooks guard their home lairs with world coordinates: draw-ins to fixed spots (Cerberus, Hydra,
-- Khimaira: the void in the arena) and rooting the boss (NO_MOVE) whenever the target is "outside the lair", which
-- here is always. So while a borrowed hook runs, utils.drawIn only pulls a target that has left the arena wing, to the
-- boss; and afterwards the boss is never left rooted (no boss on the roster roots itself for any other reason).
local function arenaSafe(fn)
    return function(mob, ...)
        local drawIn = utils.drawIn

        utils.drawIn = function(target, params)
            return drawIn(target, { conditions = { not insideWing(target) }, position = mob:getPos(), wait = params and params.wait })
        end

        local results = { pcall(fn, mob, ...) }
        utils.drawIn  = drawIn
        mob:setMobMod(xi.mobMod.NO_MOVE, 0)

        if not results[1] then
            error(results[2], 0)
        end

        return unpack(results, 2, table.maxn(results))
    end
end

-- Loads a retail mob script the way the server does (it sets the global `mixins`), once per boss
local function loadScript(boss)
    if boss.script == nil then
        return {}, nil
    end

    local savedMixins, savedOptions = rawget(_G, 'mixins'), rawget(_G, 'mixinOptions')
    rawset(_G, 'mixins', nil)
    rawset(_G, 'mixinOptions', nil)

    local ok, entity = pcall(dofile, 'scripts/zones/' .. boss.script .. '.lua')
    local mixins     = rawget(_G, 'mixins')

    rawset(_G, 'mixins', savedMixins)
    rawset(_G, 'mixinOptions', savedOptions)

    if not ok or type(entity) ~= 'table' then
        print(string.format('[htbf] could not load %s: %s', boss.script, tostring(entity)))
        entity = {}
    end

    return entity, mixins
end

-- Chains two hooks with the same arguments
local function chain(first, second)
    if first == nil then
        return second
    end

    return function(...)
        first(...)
        return second(...)
    end
end

local function hasMixin(mixins, mixin)
    for _, m in ipairs(mixins or {}) do
        if m == mixin then
            return true
        end
    end

    return false
end

-- The boss's hooks and mixins, built once: the retail script's fight hooks (made arena-safe), then the custom parts:
-- job two-hours (job_special mixin), immunities for the custom bosses, Ou's rally
local function bossScript(boss)
    if scripts[boss.key] then
        return scripts[boss.key]
    end

    local entity, mixins = loadScript(boss)
    local hooks = {}

    for _, name in ipairs(borrowable) do
        if type(entity[name]) == 'function' and not (boss.skip and boss.skip[name]) then
            hooks[name] = arenaSafe(entity[name])
        end
    end

    if boss.specials then
        local jobSpecial = require('scripts/mixins/job_special')
        mixins = mixins or {}

        if not hasMixin(mixins, jobSpecial) then
            table.insert(mixins, jobSpecial)
        end

        hooks.onMobSpawn = chain(hooks.onMobSpawn, function(mob)
            local specials = {}

            for _, special in ipairs(boss.specials) do
                table.insert(specials, { id = xi.mobSkill[special.skill], hpp = special.hpp })
            end

            xi.mix.jobSpecial.config(mob, { specials = specials })
        end)
    end

    -- The custom bosses (no retail script) resist sleep, petrify and terror like the NMs they stand in for
    if boss.script == nil then
        hooks.onMobInitialize = chain(hooks.onMobInitialize, function(mob)
            mob:addImmunity(xi.immunity.DARK_SLEEP)
            mob:addImmunity(xi.immunity.LIGHT_SLEEP)
            mob:addImmunity(xi.immunity.PETRIFY)
            mob:addImmunity(xi.immunity.TERROR)
        end)
    end

    -- Extra base damage for particular spells (MAGIC_DAMAGE is read when the spell's damage is worked out, so it is
    -- set for each cast: the bonus for that spell, else none)
    if boss.spellBonus then
        hooks.onSpellPrecast = chain(hooks.onSpellPrecast, function(mob, spell)
            mob:setMod(xi.mod.MAGIC_DAMAGE, boss.spellBonus[spell:getID()] or 0)
        end)
    end

    -- Once at `at`% HP, recover to `to`% (Ou, after retail's Prophylaxis)
    if boss.rally then
        hooks.onMobFight = chain(hooks.onMobFight, function(mob, target)
            if mob:getLocalVar('HTBF_RALLY') == 0 and mob:getHPP() <= boss.rally.at then
                mob:setLocalVar('HTBF_RALLY', 1)
                mob:setHP(math.floor(mob:getMaxHP() * boss.rally.to / 100))
                mob:resetEnmity(target)
            end
        end)
    end

    scripts[boss.key] = { hooks = hooks, mixins = mixins }

    return scripts[boss.key]
end

arena.bossScript = bossScript

-- Raises a stat to at least `target`: adds the gap to its mod, then corrects once more if other mods scale it
-- (attack and defense are multiplied by their % mods)
local function raiseTo(mob, read, mod, target)
    for _ = 1, 3 do
        local current = read(mob)

        if current >= target then
            return
        end

        mob:addMod(mod, target - current)

        if read(mob) == current then
            return -- the mod does not move this stat; do not keep adding
        end
    end
end

local statReaders =
{
    acc  = { function(mob) return mob:getACC() end,               xi.mod.ACC  },
    att  = { function(mob) return mob:getStat(xi.mod.ATT) end,    xi.mod.ATT  },
    def  = { function(mob) return mob:getStat(xi.mod.DEF) end,    xi.mod.DEF  },
    eva  = { function(mob) return mob:getEVA() end,               xi.mod.EVA  },
    meva = { function(mob) return mob:getMod(xi.mod.MEVA) end,    xi.mod.MEVA },
    mdb  = { function(mob) return mob:getMod(xi.mod.MDEF) end,    xi.mod.MDEF },
}

arena.applyFloors = function(mob, floors)
    for key, target in pairs(floors or {}) do
        local reader = statReaders[key]

        if reader then
            raiseTo(mob, reader[1], reader[2], target)
        end
    end
end

arena.scale = function(mob, tier, boss)
    local t = config.tiers[tier]

    mob:setMobLevel(t.level)

    local scale = config.hpScale or 1

    if boss and boss.hp then
        mob:setMaxHP(math.floor(boss.hp * scale))
    else
        mob:setMaxHP(math.floor(mob:getMaxHP() * t.hp * scale))
    end

    mob:setHP(mob:getMaxHP())
    mob:addMod(xi.mod.MATT, t.damage)
    mob:addMod(xi.mod.MACC, t.macc or 0)
    mob:addMod(xi.mod.INT, t.stat or 0)
    mob:addMod(xi.mod.MND, t.stat or 0)

    arena.applyFloors(mob, config.floors[tier])

    if config.magicTaken and config.magicTaken[tier] then
        mob:addMod(xi.mod.DMGMAGIC, config.magicTaken[tier])
    end

    if t.regen then
        mob:addMod(xi.mod.REGEN, t.regen)
    end

    if t.regain then
        mob:addMod(xi.mod.REGAIN, t.regain)
    end
end

-- The personal drops for one player: { { itemId, qty } ... }
arena.personalItems = function(player, boss)
    local items = {}

    for _, p in ipairs(boss.personal or {}) do
        if p.chapter then
            table.insert(items, { config.chapter(p.chapter), math.random(config.dropMin, config.dropMax) })
        elseif p.jobCard then
            table.insert(items, { config.paragonCard(player:getMainJob()), math.random(p.min, p.max) })
        elseif p.oneOf then
            table.insert(items, { p.oneOf[math.random(1, #p.oneOf)], math.random(p.min, p.max) })
        elseif p.item then
            table.insert(items, { p.item, math.random(p.min, p.max) })
        end
    end

    return items
end

arena.givePersonal = function(player, boss)
    local items = arena.personalItems(player, boss)

    if #items > 0 and not npcUtil.giveItem(player, items) then
        player:printToPlayer('Your inventory is full: your personal drops from this fight are lost.', xi.msg.channel.SYSTEM_3)
    end
end

-- The treasure pool: added to the boss's (empty) drop list when it dies
arena.addLoot = function(loot, boss)
    for _, entry in ipairs(boss.loot or {}) do
        if entry.oneOf then
            local items = {}

            for _, id in ipairs(entry.oneOf) do
                table.insert(items, { item = id, weight = 1 })
            end

            loot:addGroupFixed(entry.rate, items)
        else
            loot:addItemFixed(entry.item, entry.rate)
        end
    end
end

-- The living boss in this arena, if any
arena.currentBoss = function(instance)
    for _, mob in pairs(instance:getMobs()) do
        if mob:isSpawned() and mob:isAlive() and string.sub(mob:getName(), 1, 8) == 'DE_HTBF_' then
            return mob
        end
    end

    return nil
end

-- Sends the boss away (a table field so tests can swap it)
arena.despawn = function(mob, instance)
    DespawnMob(mob:getID(), instance)
end

local function endFight(instance)
    instance:setLocalVar('fightEnd', 0)
    instance:setLocalVar('wipeAt', 0)

    for _, char in ipairs(arena.chars(instance)) do
        char:countdown()
    end
end

local function onBossDeath(mob, player, optParams)
    if not (optParams.isKiller or optParams.noKiller) then
        return
    end

    local instance = mob:getInstance()
    local tier     = instance and instance:getLocalVar('tier') or 0
    local boss     = config.bosses[tier] and config.bosses[tier][instance:getLocalVar('boss')]

    if boss == nil then
        return
    end

    endFight(instance)

    for _, char in ipairs(arena.chars(instance)) do
        arena.givePersonal(char, boss)
    end

    tell(instance, string.format('%s is defeated! Talk to me for the next fight, or use the Arena Exit.', boss.name))
end

-- Spawns boss number `index` of the arena's tier, scaled, and sets it on `player`
arena.spawnBoss = function(instance, index, player)
    local tier = instance:getLocalVar('tier')
    local boss = config.bosses[tier][index]
    local s    = bossScript(boss)
    local pos  = config.arena.bossSpawn
    local t    = config.tiers[tier]

    local def =
    {
        objtype              = xi.objType.MOB,
        name                 = 'HTBF_' .. boss.key,
        packetName           = boss.name,
        x                    = pos[1],
        y                    = pos[2],
        z                    = pos[3],
        rotation             = pos[4],
        groupId              = boss.group[1],
        groupZoneId          = boss.group[2],
        minLevel             = t.level,
        maxLevel             = t.level,
        releaseIdOnDisappear = true,
        mixins               = s.mixins,
        onMobDeath           = onBossDeath,
        skillList            = boss.skillList,
        spellList            = boss.spellList,
    }

    for name, fn in pairs(s.hooks) do
        def[name] = fn
    end

    local mob = instance:insertDynamicEntity(def)

    if mob == nil then
        return nil
    end

    mob:setRespawnTime(0) -- the retail onMobInitialize may have set the real NM's timer
    mob:setDropID(0) -- the empty drop list: only the treasure pool entries below, not the source NM's loot
    mob:setSpawn(pos[1], pos[2], pos[3], pos[4])

    if boss.loot then
        mob:addListener('ITEM_DROPS', 'HTBF_LOOT', function(mobArg, loot)
            arena.addLoot(loot, boss)
        end)
    end

    mob:spawn()
    arena.scale(mob, tier, boss)

    instance:setLocalVar('boss', index)
    instance:setLocalVar('fightEnd', GetSystemTime() + config.arena.fightSeconds)
    instance:setLocalVar('wipeAt', 0)

    for _, char in ipairs(arena.chars(instance)) do
        char:countdown(config.arena.fightSeconds)
    end

    if player and player:isAlive() then
        mob:updateEnmity(player)
    end

    return mob
end

-- The Moogle: pick a boss (after a short delay it appears), or leave
local function pickBoss(player, index)
    local instance = player:getInstance()

    if instance == nil then
        return
    end

    if arena.currentBoss(instance) or instance:getLocalVar('pending') == 1 then
        arena.say(player, 'A fight is already underway!', 'Arena Moogle')

        return
    end

    local boss  = config.bosses[instance:getLocalVar('tier')][index]
    local token = instance:getLocalVar('token')
    instance:setLocalVar('pending', 1)
    tell(instance, string.format('%s appears in %d seconds! You have %d minutes.', boss.name, config.arena.spawnDelay, config.arena.fightSeconds / 60))

    arena.schedule(player, config.arena.spawnDelay * 1000, function(playerArg)
        local here = playerArg:getInstance()

        if here == nil or here:getLocalVar('token') ~= token then
            return -- they left the arena in the meantime
        end

        here:setLocalVar('pending', 0)
        arena.spawnBoss(here, index, playerArg)
    end)
end

arena.onMoogleTrigger = function(player, npc)
    local instance = player:getInstance()

    if instance == nil then
        return
    end

    local tier    = instance:getLocalVar('tier')
    local options = {}

    for index, boss in ipairs(config.bosses[tier] or {}) do
        table.insert(options, { boss.name, function(playerArg) pickBoss(playerArg, index) end })
    end

    table.insert(options, { 'Leave', function(playerArg) arena.toArchivist(playerArg) end })

    arena.say(player, arena.rewardLine(tier), 'Arena Moogle')
    arena.sendMenu(player, { title = string.format('%s: which boss?', config.tiers[tier].name), options = options })
end

arena.onExitTrigger = function(player, npc)
    arena.sendMenu(player,
    {
        title   = 'Back to Western Adoulin?',
        options =
        {
            { 'Yes', function(playerArg) arena.toArchivist(playerArg) end },
            { 'No', function() end },
        },
    })
end

-----------------------------------
-- The instance script (scripts/zones/Maquette_Abdhaljs-Legion_A/instances/htbf_arena.lua returns this)
-----------------------------------
local instanceObject = {}

instanceObject.onInstanceCreated = function(instance)
    instance:setLocalVar('token', math.random(1, 1000000000))

    for _, npc in ipairs({ config.arena.moogle, config.arena.exit }) do
        instance:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = npc.name,
            packetName = npc.packetName,
            look       = npc.look,
            x          = npc.pos[1],
            y          = npc.pos[2],
            z          = npc.pos[3],
            rotation   = npc.pos[4],
            widescan   = 1,
            onTrigger  = npc == config.arena.moogle and arena.onMoogleTrigger or arena.onExitTrigger,
        })
    end
end

instanceObject.onInstanceCreatedCallback = function(player, instance)
    player:setLocalVar('HTBF_OPENING', 0)

    if instance == nil then
        arena.say(player, 'The arena could not be opened. Please try again.')

        return
    end

    local tier = player:getLocalVar('HTBF_TIER')
    instance:setLocalVar('tier', tier)

    local entry = config.arena.entry

    for _, member in ipairs(arena.group(player)) do
        if member:getID() ~= player:getID() then
            arena.say(member, string.format('%s is taking your party into the %s arena.', player:getName(), config.tiers[tier].name))
        end

        member:setInstance(instance)
        member:setPos(entry[1], entry[2], entry[3], entry[4], config.arena.zoneId)
    end
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()

    if instance then
        arena.say(player, string.format('Welcome to the %s arena, kupo! Talk to me to call a boss.', config.tiers[instance:getLocalVar('tier')].name), 'Arena Moogle')
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
        elseif now - instance:getLocalVar('emptySince') >= config.arena.emptySeconds then
            instance:fail()
        end

        return
    end

    instance:setLocalVar('emptySince', 0)

    local boss = arena.currentBoss(instance)

    if boss == nil then
        return
    end

    -- Out of time
    local fightEnd = instance:getLocalVar('fightEnd')

    if fightEnd > 0 and now >= fightEnd then
        arena.despawn(boss, instance)
        endFight(instance)
        tell(instance, 'Time is up! The boss has left. Talk to me to try again.')

        return
    end

    -- Everyone inside KO'd for a while
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
    elseif now - instance:getLocalVar('wipeAt') >= config.arena.wipeSeconds then
        arena.despawn(boss, instance)
        endFight(instance)
        tell(instance, 'The boss grew bored and left. Talk to me to try again.')
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

arena.instanceObject = instanceObject

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.htbfArena = arena -- for tests

return arena
