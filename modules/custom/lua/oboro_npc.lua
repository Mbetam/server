-----------------------------------
-- Oboro, moved to Ru'Lude Gardens next to the Splintery Chest and the Magian Moogles (JSE weapon progression,
-- Eric 2026-09-29): a copy with his exact look stands there and does the 99 -> 119 -> 119 III upgrades
-- (oboro_flow.lua); the Port Jeuno Oboro is hidden. NPCs can't change zones, so this is a new NPC.
-- Position from Eric's in-game !pos: X 10.5124, Y 3.1000, Z 116.5696, rotation 126 (Y is height, as in the zone data:
-- the Splintery Chest next to it sits at y 3.100).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Port_Jeuno/Zone')
local flow = require('modules/custom/lua/oboro_flow')
-----------------------------------

local m = Module:new('oboro_npc')

local PORT_JEUNO_OBORO = 17784988

-- His Port Jeuno look (data/zones/port_jeuno/npcs.yaml): size 1, race 1, face 8, head 4280, body 8192, hands 12612,
-- legs 16568, feet 20804, main 24576, sub 28672, as a raw look string
local OBORO_LOOK = '0x01000801b81000204431b8404451006000700080'

m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity(
    {
        objtype    = xi.objType.NPC,
        name       = 'Oboro',
        packetName = 'Oboro',
        look       = OBORO_LOOK,
        x          = 10.5124,
        y          = 3.1000,
        z          = 116.5696,
        rotation   = 126,
        widescan   = 1,
        onTrade    = flow.onTrade,
        onTrigger  = flow.onTrigger,
    })
end)

m:addOverride('xi.zones.Port_Jeuno.Zone.onInitialize', function(zone)
    super(zone)

    local oboro = GetNPCByID(PORT_JEUNO_OBORO)

    if oboro then
        oboro:setStatus(xi.status.DISAPPEAR)
    end
end)

return m
