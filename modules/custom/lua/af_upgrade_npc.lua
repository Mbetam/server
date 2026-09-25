-----------------------------------
-- The Armor Upgrader NPC: upgrades Artifact, Relic and Empyrean armor one tier per trade. Puts one NPC into each zone listed in
-- af_upgrade_config.lua (placements); the conversation is in af_upgrade_flow.lua.
-- Off unless settings/main.lua has ENABLE_ARMOR_UPGRADER = true (on test only until the armor is fully working; Eric).
-----------------------------------
require('modules/module_utils')
local config = require('modules/custom/lua/af_upgrade_config')
local flow   = require('modules/custom/lua/af_upgrade_flow')
-----------------------------------

local m = Module:new('af_upgrade_npc')

for _, place in ipairs(config.placements) do
    require(string.format('scripts/zones/%s/Zone', place.zone))

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        if not xi.settings.main.ENABLE_ARMOR_UPGRADER then
            return
        end

        zone:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = 'Armor_Upgrader',
            packetName = 'Armor Upgrader',
            look       = config.npcModel,
            x          = place.x,
            y          = place.y,
            z          = place.z,
            rotation   = place.rotation,
            widescan   = 1,
            onTrade    = flow.onTrade,
            onTrigger  = flow.onTrigger,
        })
    end)
end
