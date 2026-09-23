-----------------------------------
-- The Trust Vendor NPC: sells the trusts players cannot get in normal play here. Puts one NPC into each zone listed in
-- trust_vendor_config.lua (placements); the conversation is in trust_vendor_flow.lua.
-----------------------------------
require('modules/module_utils')
local config = require('modules/custom/lua/trust_vendor_config')
local flow   = require('modules/custom/lua/trust_vendor_flow')
-----------------------------------

local m = Module:new('trust_vendor_npc')

for _, place in ipairs(config.placements) do
    require(string.format('scripts/zones/%s/Zone', place.zone))

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        zone:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = 'Trust_Vendor',
            packetName = 'Trust Vendor',
            look       = config.npcModel,
            x          = place.x,
            y          = place.y,
            z          = place.z,
            rotation   = place.rotation,
            widescan   = 1,
            onTrigger  = flow.onTrigger,
        })
    end)
end
