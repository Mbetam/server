-----------------------------------
-- func: buff
-- desc: Grants the server buff bundle for one hour: EXP +200%, Regen +50, Refresh +50 and Regain +50.
--       Running it again replaces the buff and restarts the timer; it never stacks.
-----------------------------------
require('modules/module_utils')
-----------------------------------

-- Tune the buff here.
local buffDuration = 3600 -- seconds

-- EXP is Dedication: power is the percentage bonus on kill EXP, applied before the server's EXP_RATE (see xi.experiencePoints.calculate).
-- Dedication pays its bonus out of a pool (subPower) and ends when the pool is empty, so keep the pool out of reach for the duration.
local expPercent = 200
local expPool    = 99999999

-- Regen and Refresh: power is HP / MP restored every tick (3 seconds).
local regenPower   = 50
local refreshPower = 50

-- Regain: scripts/effects/regain.lua multiplies the effect power by 10 to get the REGAIN mod, and the mod is the TP gained every tick.
-- So an effect power of 5 is Regain +50.
local regainPower = 5

local buffEffects =
{
    xi.effect.DEDICATION,
    xi.effect.REGEN,
    xi.effect.REFRESH,
    xi.effect.REGAIN,
}

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

commandObj.onTrigger = function(player)
    if player:isDead() then
        player:printToPlayer('You cannot use !buff while KO\'d.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- Replace rather than stack, so running it again always restarts the timer at full strength.
    for _, effectId in ipairs(buffEffects) do
        player:delStatusEffect(effectId)
    end

    player:addStatusEffect(xi.effect.DEDICATION, { power = expPercent, subPower = expPool, duration = buffDuration, origin = player })
    player:addStatusEffect(xi.effect.REGEN, { power = regenPower, duration = buffDuration, origin = player, tick = 3 })
    player:addStatusEffect(xi.effect.REFRESH, { power = refreshPower, duration = buffDuration, origin = player })
    player:addStatusEffect(xi.effect.REGAIN, { power = regainPower, duration = buffDuration, origin = player })

    player:printToPlayer(
        string.format(
            'Buff active for %d minutes: EXP +%d%%, Regen +%d, Refresh +%d, Regain +%d.',
            buffDuration / 60,
            expPercent,
            regenPower,
            refreshPower,
            regainPower * 10
        ),
        xi.msg.channel.SYSTEM_3
    )
end

xi.module.registerCommand('buff', commandObj)
