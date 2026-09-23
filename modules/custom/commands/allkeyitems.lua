-----------------------------------
-- func: allkeyitems
-- desc: GM only. Gives every key item the game knows about to the named player or yourself (skipping ones
--       already owned). Some key items change what quest NPCs say, so only use it on test characters.
--       Runs in small batches; stay put until it says done.
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

local usage = '!allkeyitems (player)'

-- One database save per key item actually added.
local BATCH_SIZE = 100

commandObj.onTrigger = function(player, targetName)
    local target = unlocks.findTarget(player, targetName, usage)
    if target == nil then
        return
    end

    local missing = {}
    for _, id in ipairs(unlocks.keyItemIds(xi.keyItem)) do
        if not target:hasKeyItem(id) then
            table.insert(missing, id)
        end
    end

    if #missing == 0 then
        player:printToPlayer(string.format('%s already has every key item.', target:getName()), xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer(string.format('Giving %s %d key items...', target:getName(), #missing), xi.msg.channel.SYSTEM_3)

    unlocks.runInBatches(player, target:getName(), missing, BATCH_SIZE, '!allkeyitems',
        function(targ, id)
            targ:addKeyItem(id)
        end)
end

xi.module.registerCommand('allkeyitems', commandObj)
