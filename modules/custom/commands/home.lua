-----------------------------------
-- func: home
-- desc: Sends you to your home point, the same as being warped by Warp. Not usable in battle, in events, or inside battlefields and instances.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

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

    qol.say(player, 'Warping to your home point...')
    player:warp()
end

xi.module.registerCommand('home', commandObj)
