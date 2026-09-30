-----------------------------------
-- func: hangout
-- desc: Sends you to the hangout spot in Western Adoulin (Eric's !pos). Not usable in battle, in events, or inside
--       battlefields and instances.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

-- Eric's !pos, Western Adoulin (Y is height)
local HANGOUT = { x = 23.6316, y = 1.0000, z = -13.9023, rotation = 203, zoneId = xi.zone.WESTERN_ADOULIN }

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

commandObj.onTrigger = function(player)
    local reason = qol.blockedReason(player)
    if reason then
        qol.say(player, reason)
        return
    end

    qol.say(player, 'Off to the hangout in Western Adoulin...')
    player:setPos(HANGOUT.x, HANGOUT.y, HANGOUT.z, HANGOUT.rotation, HANGOUT.zoneId)
end

xi.module.registerCommand('hangout', commandObj)
xi.module.registerCommand('Hangout', commandObj) -- command names are matched exactly as typed
