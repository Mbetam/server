-----------------------------------
-- func: city
-- desc: Teleports you to a nation's main city, next to its Home Point #1 crystal. Try !city sandoria, bastok, windurst or jeuno.
--       Not usable in battle, in events, or inside battlefields and instances.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

-- Where each city leads: the zone in each nation that has the Auction House, the guilds and the Mog House entrance, at the
-- position of its Home Point #1 (from data/zones/<zone>/npcs.yaml; a test checks these against that file).
-- `names` are the words a player may type.
local cities =
{
    { label = 'San d\'Oria', names = { 'sandoria', 'sandy', 'san', 'sd' },  zone = xi.zone.SOUTHERN_SAN_DORIA, x =  -85.468, y =   1.0, z =  -66.454, rot =   0 },
    { label = 'Bastok',      names = { 'bastok', 'bas' },                   zone = xi.zone.BASTOK_MARKETS,      x = -344.0,   y = -10.0, z = -155.0,   rot = 160 },
    { label = 'Windurst',    names = { 'windurst', 'windy', 'win' },        zone = xi.zone.WINDURST_WOODS,      x =    9.088, y =  -2.5, z =   -0.383, rot = 244 },
    { label = 'Jeuno',       names = { 'jeuno', 'jue' },                    zone = xi.zone.LOWER_JEUNO,         x =  -98.588, y =   0.0, z = -183.416, rot = 167 },
}

local byName = {}

for _, city in ipairs(cities) do
    for _, name in ipairs(city.names) do
        byName[name] = city
    end
end

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = 's',
}

commandObj.onTrigger = function(player, destination)
    local city = destination and byName[destination:lower()]

    if city == nil then
        qol.say(player, 'Where to? Try !city sandoria, !city bastok, !city windurst or !city jeuno.')

        return
    end

    local reason = qol.blockedReason(player)
    if reason then
        qol.say(player, reason)

        return
    end

    qol.say(player, string.format('Teleporting to %s...', city.label))

    if player:getZoneID() == city.zone then
        player:setPos(city.x, city.y, city.z, city.rot)
    else
        player:setPos(city.x, city.y, city.z, city.rot, city.zone)
    end
end

xi.module.registerCommand('city', commandObj)
