-----------------------------------
-- func: status [summary | mods | skills | effects | all] [page]
-- desc: Shows the stats of your current target, or your own when you have no target. Works on players, monsters, pets
--       and trusts. Only reads, changes nothing.
--         !status              level, job, HP/MP/TP, attributes, offense, defense, bonuses
--         !status mods [page]  every modifier that is not zero (this is where everything else lives)
--         !status skills       every skill above zero
--         !status effects      every status effect with its power and time left
--         !status all          all of the above at once
-----------------------------------
require('modules/module_utils')
local qol    = require('modules/custom/lua/qol_common')
local report = require('modules/custom/lua/status_report')
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = 'ss',
}

commandObj.onTrigger = function(player, section, page)
    local lines, message = report.run(player:getCursorTarget() or player, section, page)

    if lines == nil then
        qol.say(player, message)

        return
    end

    for _, line in ipairs(lines) do
        qol.say(player, line)
    end
end

xi.module.registerCommand('status', commandObj)
