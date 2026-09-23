-----------------------------------
-- Leveling Guide NPC: a free teleport to one good leveling area per level bracket (Eric's picks from BG Wiki's
-- "Fantastic EXPs and Where to Find Them", 2026-09-23). It lands on the Home Point / Survival Guide / waypoint nearest
-- the camp. No level limit and no fee. Not usable in battle, in events, or inside battlefields and instances.
-- New spots need a server restart (module).
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

local npcName = 'Leveling Guide'

-- The Field Manual (FoV book) look: model 2290, "White Book (Floating)" in docs/model_ids.txt
local npcModel = 2290

-- Where the NPC stands. Stand where you want it in game, use !pos, then edit here. Rotation 0-255 (0 = east).
local placements =
{
    -- Norg, chosen by Eric with !pos (2026-09-23)
    { zone = 'Norg', x = -13.3101, y = 1.0977, z = -36.1236, rotation = 14 }, -- Eric's !pos faced 142; flipped 180

    -- GM Home, for testing
    { zone = 'GM_Home', x = 6.0, y = 0.0, z = 3.0, rotation = 128 },
}

-- label, then x, y, z, rotation, zone. Coordinates are the game's own teleport points (see the comment on each line).
-- Keep the labels and the title SHORT: the whole menu is sent as one chat message of at most 150 bytes
-- (GP_SERV_COMMAND_CHAT_STD Mes[150]); anything past that is cut off in game. This menu is about 120 bytes.
local destinations =
{
    { '10-24 Valkurm',         137.9,    -7.5,    97.0,  162, xi.zone.VALKURM_DUNES         }, -- Survival Guide
    { '25-50 Oldton',         -260.78,    8.0,   -54.0,  128, xi.zone.OLDTON_MOVALPOLOS     }, -- Survival Guide
    { '50-70 Bhaflau',         -98.0,   -10.0,  -493.0,  192, xi.zone.BHAFLAU_THICKETS      }, -- Home Point #1
    { '70-80 Kuftal',          -16.84,  -20.47, -237.0,    0, xi.zone.KUFTAL_TUNNEL         }, -- Survival Guide
    { '80-90 Mt. Zhayolm',    -540.844,  -4.0,    70.809,  74, xi.zone.MOUNT_ZHAYOLM        }, -- Home Point #1
    { '90-99 Yahse',           321.0,     0.0,  -199.8,  127, xi.zone.YAHSE_HUNTING_GROUNDS }, -- Frontier Station
}

local function teleport(player, dest)
    local reason = qol.blockedReason(player)

    if reason then
        qol.say(player, reason)

        return
    end

    player:setPos(dest[2], dest[3], dest[4], dest[5], dest[6])
end

local function onTrigger(player, npc)
    local reason = qol.blockedReason(player)

    if reason then
        qol.say(player, reason)

        return
    end

    local options = {}

    for _, dest in ipairs(destinations) do
        table.insert(options, { dest[1], function(playerArg) teleport(playerArg, dest) end })
    end

    table.insert(options, { 'Cancel', function() end })

    player:customMenu({ title = 'Level where?', options = options, onCancelled = function() end })
end

local m = Module:new('leveling_guide_npc')

for _, place in ipairs(placements) do
    require(string.format('scripts/zones/%s/Zone', place.zone))

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        zone:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = 'Leveling_Guide',
            packetName = npcName,
            look       = npcModel,
            x          = place.x,
            y          = place.y,
            z          = place.z,
            rotation   = place.rotation,
            widescan   = 1,
            onTrigger  = onTrigger,
        })
    end)
end
