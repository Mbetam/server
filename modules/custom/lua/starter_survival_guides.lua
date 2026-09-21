-----------------------------------
-- New characters start with every Survival Guide registered.
-- (START_GIL, ALL_MAPS and UNLOCK_OUTPOST_WARPS in settings/main.lua cover gil, maps and outpost warps; nothing covers guides.)
-- Same loop as the GM command scripts/commands/addallwarps.lua, minus its Home Points.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('starter_survival_guides')

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    for groupIndex = 1, 32 do
        for group = 1, 3 do
            player:addTeleport(xi.teleport.type.SURVIVAL, groupIndex - 1, group - 1)
        end
    end
end)
