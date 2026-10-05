-----------------------------------
-- Trusts go in as soon as you engage (Eric, 2026-10-05): LSB's custom engagement type 1 ("Master engage", no melee
-- swing needed; trust_controller.cpp DoRoamTick) becomes everyone's default. Retail (type 0) waits for your first
-- swing, so a mage or anyone engaging from range had trusts standing around.
-- Needs ENABLE_TRUST_CUSTOM_ENGAGEMENT = 1 in settings/main.lua (also turns on !trustengage). Set once per character
-- at login; anyone can go back with !trustengage 0 and it stays that way.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('trust_engage_default')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not zoning and player:getCharVar('TrustEngageDefaulted') == 0 then
        player:setCharVar('TrustEngageType', 1)
        player:setCharVar('TrustEngageDefaulted', 1)
    end
end)

return m
