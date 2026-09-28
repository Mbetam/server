-----------------------------------
-- func: hunt
-- desc: Shows your daily hunts and Hunt Marks. "!hunt reroll <number>" swaps an unfinished hunt for a new one.
-----------------------------------
require('modules/module_utils')
local core = require('modules/custom/lua/hunt_core')
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = 'ss',
}

commandObj.onTrigger = function(player, action, number)
    if action == 'reroll' then
        local ok, reason = core.reroll(player, tonumber(number) or 0)

        if not ok then
            core.say(player, reason)

            return
        end

        core.say(player, 'Hunt ' .. number .. ' rerolled.')
    end

    core.show(player)
end

xi.module.registerCommand('hunt', commandObj)
