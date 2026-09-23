-----------------------------------
-- The Augmenter NPC.
-- Puts one "Augmenter" NPC into each zone listed below. Trade the NPC a weapon or piece of armor to add or remove
-- augments; the conversation and the item swap live in augmenter_flow.lua and the numbers in augment_config.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Norg/Zone')
require('scripts/zones/GM_Home/Zone')
local flow   = require('modules/custom/lua/augmenter_flow')
local config = require('modules/custom/lua/augment_config')
-----------------------------------

-- Where the Augmenter stands. Stand where you want it in game, use !pos to read your coordinates, then edit here.
-- Rotation is 0-255 (0 = east).
local placements =
{
    -- Norg, near the Trust Vendor. Chosen by Eric with !pos (2026-09-23; was Lower Jeuno, then -24.73, -34.12).
    { zone = 'Norg', x = -22.3777, y = 1.0977, z = -32.0073, rotation = 24 },

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
