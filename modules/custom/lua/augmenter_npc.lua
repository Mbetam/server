-----------------------------------
-- The Augmenter NPC.
-- Puts one "Augmenter" NPC into each zone listed below. Trade the NPC a weapon or piece of armor to add or remove
-- augments; the conversation and the item swap live in augmenter_flow.lua and the numbers in augment_config.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Lower_Jeuno/Zone')
require('scripts/zones/GM_Home/Zone')
local flow   = require('modules/custom/lua/augmenter_flow')
local config = require('modules/custom/lua/augment_config')
-----------------------------------

-- Where the Augmenter stands. Stand where you want it in game, use !pos to read your coordinates, then edit here.
-- Rotation is 0-255 (0 = east).
local placements =
{
    -- Lower Jeuno, in the middle of the zone (about 8 yalms from the Moogle at 0, 1.5). Chosen by Eric with !pos.
    { zone = 'Lower_Jeuno', x = 7.03, y = 0.0, z = 6.05, rotation = 84 },

    -- GM Home, for testing
    { zone = 'GM_Home', x = 8.0, y = 0.0, z = 3.0, rotation = 128 },
}

-- The look is set in augment_config.lua (a Moogle). Do not use model 50: it is the blank placeholder the Auction Counters use.
local model = config.npcModel

local m = Module:new('augmenter_npc')

for _, place in ipairs(placements) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        zone:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = 'Augmenter',
            packetName = 'Augmenter',
            look       = model,
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
