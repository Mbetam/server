-----------------------------------
-- func: buff
-- desc: Grants the server buff bundle for ten hours: EXP +100%, Regen +50, Refresh +50 and Regain +50.
--       Running it again replaces the buff and restarts the timer; it never stacks.
-----------------------------------
require('modules/module_utils')
-----------------------------------

-- The numbers live in modules/custom/lua/buff_config.lua (shared with the pool top-up in buff_pool.lua).
-- Drop the cached copy first so re-running this file (the server's file watcher does that on save) picks up an edited config.
local configPath = 'modules/custom/lua/buff_config'
package.loaded[configPath] = nil
local config = require(configPath)

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

    player:addStatusEffect(xi.effect.DEDICATION, { power = config.expPercent, subPower = config.expPool, duration = config.duration, origin = player })
    player:addStatusEffect(xi.effect.REGEN, { power = config.regenPower, duration = config.duration, origin = player, tick = 3 })
    player:addStatusEffect(xi.effect.REFRESH, { power = config.refreshPower, duration = config.duration, origin = player })
    player:addStatusEffect(xi.effect.REGAIN, { power = config.regainPower, duration = config.duration, origin = player })

    player:printToPlayer(
        string.format(
            'Buff active for %g hours: EXP +%d%%, Regen +%d, Refresh +%d, Regain +%d.',
            config.duration / 3600,
            config.expPercent,
            config.regenPower,
            config.refreshPower,
            config.regainPower * 10
        ),
        xi.msg.channel.SYSTEM_3
    )
end

xi.module.registerCommand('buff', commandObj)
