-----------------------------------
-- At every login and zone change, teach the trusts a player has earned through quests/missions whose scripts
-- never teach them (the list and the rules are in trust_quest_grants.lua).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/trust')
local trustGrants = require('modules/custom/lua/trust_quest_grants')
-----------------------------------

local m = Module:new('trust_quest_grants_login')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    -- After the zone has finished loading the player, so the message is shown
    player:timer(3000, function(playerArg)
        trustGrants.grant(playerArg)
    end)
end)
