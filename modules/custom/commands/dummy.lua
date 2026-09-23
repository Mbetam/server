-----------------------------------
-- func: dummy [level | clear] [hp]
-- desc: Spawns a training dummy in front of you for combat testing (GM only). It never attacks, casts, uses TP moves
--       or moves, drops nothing and gives no EXP worth mentioning, and it cannot die: at 10% HP it heals back to full.
--         !dummy                 a dummy at your level with 100,000 HP
--         !dummy 75              a level 75 dummy
--         !dummy 99 500000       a level 99 dummy with 500,000 HP
--         !dummy clear           removes your dummy
--       One dummy per GM: a new !dummy replaces your old one. It also goes away after 60 minutes.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

-- Any mob group usable for dynamic spawns will do: level, HP, skills, spells and drops are all overridden below.
-- Goblin Browbeater (group 11374 in zone 86): a plain melee goblin.
local baseGroupId     = 11374
local baseGroupZoneId = 86

local defaultHP  = 100000
local maxHP      = 9999999
local lifetime   = 60 * 60 -- seconds
local healAtHPP  = 10
local varId      = '[Dummy]Id'

local function removeDummy(player)
    local id = player:getLocalVar(varId)

    if id ~= 0 then
        local dummy = GetMobByID(id)

        if dummy and dummy:isSpawned() then
            DespawnMob(id)
        end

        player:setLocalVar(varId, 0)

        return true
    end

    return false
end

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1, -- GM
    parameters = 'ss',
}

commandObj.onTrigger = function(player, levelArg, hpArg)
    if levelArg and levelArg:lower() == 'clear' then
        if removeDummy(player) then
            qol.say(player, 'Training dummy removed.')
        else
            qol.say(player, 'You have no training dummy.')
        end

        return
    end

    local level = tonumber(levelArg) or player:getMainLvl()
    local hp    = tonumber(hpArg) or defaultHP

    if level < 1 or level > 150 or hp < 1 or hp > maxHP then
        qol.say(player, string.format('Try !dummy [level 1-150] [HP 1-%d], or !dummy clear.', maxHP))

        return
    end

    removeDummy(player)

    -- 3 yalms in front of you
    local angle = player:getRotPos() / 256 * 2 * math.pi
    local x     = player:getXPos() + 3 * math.cos(angle)
    local z     = player:getZPos() - 3 * math.sin(angle)

    local dummy = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        name                 = 'Training_Dummy',
        packetName           = 'Training Dummy',
        groupId              = baseGroupId,
        groupZoneId          = baseGroupZoneId,
        minLevel             = level,
        maxLevel             = level,
        x                    = x,
        y                    = player:getYPos(),
        z                    = z,
        rotation             = (player:getRotPos() + 128) % 256, -- facing you
        dropId               = 0,
        skillList            = 0,
        spellList            = 0,
        respawn              = 0,
        isAggroable          = false,
        releaseIdOnDisappear = true,
    })

    if dummy == nil then
        qol.say(player, 'Could not spawn a training dummy here.')

        return
    end

    dummy:setSpawn(x, player:getYPos(), z, (player:getRotPos() + 128) % 256)
    dummy:spawn()

    dummy:setMobMod(xi.mobMod.NO_MOVE, 1)
    dummy:setMobMod(xi.mobMod.NO_LINK, 1)
    dummy:setAutoAttackEnabled(false)
    dummy:setMobAbilityEnabled(false)
    dummy:setMagicCastingEnabled(false)
    dummy:setMaxHP(hp)
    dummy:setHP(dummy:getMaxHP()) -- the base monster's HP bonuses can add a little on top
    dummy:setUnkillable(true)

    -- Heal back to full instead of dying, so a long test never has to stop
    dummy:addListener('COMBAT_TICK', 'DUMMY_HEAL', function(mob)
        if mob:getHPP() <= healAtHPP then
            mob:setHP(mob:getMaxHP())
        end
    end)

    -- Remove it after a while even if nobody clears it
    local id = dummy:getID()
    dummy:timer(lifetime * 1000, function(mob)
        if mob:isSpawned() then
            DespawnMob(id)
        end
    end)

    player:setLocalVar(varId, id)
    qol.say(player, string.format('Training dummy: level %d, %d HP. It never fights back and heals at %d%%. !dummy clear to remove it.', level, dummy:getMaxHP(), healAtHPP))
end

xi.module.registerCommand('dummy', commandObj)
