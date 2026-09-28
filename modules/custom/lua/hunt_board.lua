-----------------------------------
-- Daily hunts: the Hunt Board NPC (in each zone listed in hunt_config.lua) and kill tracking.
-- The game calls xi.mob.onMobDeathEx once per alliance member for every kill, so each member in the zone gets credit.
-- The hunts themselves: hunt_core.lua. The !hunt command: modules/custom/commands/hunt.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
local config = require('modules/custom/lua/hunt_config')
local core   = require('modules/custom/lua/hunt_core')
-----------------------------------

local m = Module:new('hunt_board')

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    if player and player:isPC() then
        core.onKill(player, mob)
    end

    return super(mob, player, isKiller, isWeaponSkillKill)
end)

local function onTrigger(player, npc)
    core.show(player)
    core.say(player, 'Finished hunts pay out on the spot. Spend Hunt Marks on +4 armor at the Armor Upgrader.')
end

for _, place in ipairs(config.placements) do
    require(string.format('scripts/zones/%s/Zone', place.zone))

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        zone:insertDynamicEntity(
        {
            objtype    = xi.objType.NPC,
            name       = 'Hunt_Board',
            packetName = 'Hunt Board',
            look       = config.npcModel,
            x          = place.x,
            y          = place.y,
            z          = place.z,
            rotation   = place.rotation,
            widescan   = 1,
            onTrigger  = onTrigger,
        })
    end)
end

return m
