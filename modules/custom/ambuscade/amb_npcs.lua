-----------------------------------
-- Ambuscade (custom): hooks Mhaura's two retail NPCs to the custom Ambuscade (LSB's is a stub: Gorpa's menus are
-- empty and the tome launches one placeholder fight).
-- Gorpa-Masorpa: the exchange (amb_shop.lua). Talk to buy, trade a piece to upgrade it.
-- Ambuscade Tome: the wave run (amb_waves.lua).
-- No Records of Eminence step is needed for either. Anyone who logs back in inside a run that has closed lands next
-- to Gorpa (retail: Mhaura at 0, 0, 0).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/ambuscade')
require('scripts/zones/Maquette_Abdhaljs-Legion_B/Zone')
local shop  = require('modules/custom/ambuscade/amb_shop')
local waves = require('modules/custom/ambuscade/amb_waves')
-----------------------------------

local m = Module:new('amb_npcs')

m:addOverride('xi.ambuscade.onTriggerGorpaMasorpa', function(player, npc)
    shop.onTrigger(player, npc)
end)

m:addOverride('xi.ambuscade.onTradeGorpaMasorpa', function(player, npc, trade)
    shop.onTrade(player, npc, trade)
end)

m:addOverride('xi.ambuscade.onTriggerTome', function(player, npc)
    waves.onTomeTrigger(player, npc)
end)

m:addOverride('xi.zones.Maquette_Abdhaljs-Legion_B.Zone.onInstanceZoneIn', function(player, instance)
    if player:getInstance() == nil then
        waves.toMhaura(player)

        return
    end

    return super(player, instance)
end)

return m
