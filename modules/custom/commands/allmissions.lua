-----------------------------------
-- func: allmissions
-- desc: GM only. Marks every mission in every mission log as completed and sets nation rank 10, for the named
--       player or yourself. It only changes the mission log and rank: no key items (see !allkeyitems), titles
--       or mission variables. Runs in small batches; stay put until it says done.
-----------------------------------
require('modules/module_utils')
local unlocks = require('modules/custom/lua/gm_unlocks')
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

local usage = '!allmissions (player)'

-- Mission steps: two database saves each (add, then complete), so fewer per batch than key items.
local BATCH_SIZE = 20

commandObj.onTrigger = function(player, targetName)
    local target = unlocks.findTarget(player, targetName, usage)
    if target == nil then
        return
    end

    local steps = unlocks.missionSteps(xi.mission.log_id, xi.mission.area, xi.mission.id)

    player:printToPlayer(string.format('Completing %d missions for %s...', #steps, target:getName()), xi.msg.channel.SYSTEM_3)

    unlocks.runInBatches(player, target:getName(), steps, BATCH_SIZE, '!allmissions',
        function(targ, step)
            targ:addMission(step.log, step.id)
            if step.action == 'complete' then
                targ:completeMission(step.log, step.id)
            end
        end,
        function(targ)
            targ:setRank(10)
            targ:printToPlayer('All missions are now completed. Zone once to refresh the mission log.', xi.msg.channel.SYSTEM_3)
        end)
end

xi.module.registerCommand('allmissions', commandObj)
