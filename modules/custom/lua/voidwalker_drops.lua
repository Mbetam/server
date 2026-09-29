-----------------------------------
-- Voidwalker personal drops (Eric, 2026-09-28): every party / alliance member in the zone gets their own pile of
-- Reisenjima-style upgrade materials when a Voidwalker NM dies, straight into their inventory (no lotting).
-- The tier is the abyssite the NM was popped with: Clear = T1, Colorful = T2, Blue / Orange / Brown / Yellow / Grey =
-- T3, Black = boss. The game calls xi.voidwalker.onMobDeath once per member in the zone (luautils OnMobDeath).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/voidwalker')
-----------------------------------

local m = Module:new('voidwalker_drops')

local PLUTON           = 4059
local RIFTBORN_BOULDER = 4061
local BEITETSU         = 4060 -- chunk_of_beitetsu

local drops =
{
    t1   = { { PLUTON, 20, 50 } },
    t2   = { { RIFTBORN_BOULDER, 20, 50 } },
    t3   = { { BEITETSU, 20, 50 } },
    boss = { { PLUTON, 20, 50 }, { RIFTBORN_BOULDER, 20, 50 }, { BEITETSU, 20, 50 } },
}

local tierByAbyssite =
{
    [xi.keyItem.CLEAR_ABYSSITE]    = 't1',
    [xi.keyItem.COLORFUL_ABYSSITE] = 't2',
    [xi.keyItem.BLUE_ABYSSITE]     = 't3',
    [xi.keyItem.ORANGE_ABYSSITE]   = 't3',
    [xi.keyItem.BROWN_ABYSSITE]    = 't3',
    [xi.keyItem.YELLOW_ABYSSITE]   = 't3',
    [xi.keyItem.GREY_ABYSSITE]     = 't3',
    [xi.keyItem.BLACK_ABYSSITE]    = 'boss',
}

-- One npcUtil.giveItem call per member: the usual "Obtained" messages, or "cannot obtain" with a full inventory
-- (then the drop is lost, like a full treasure pool)
m:addOverride('xi.voidwalker.onMobDeath', function(mob, player, optParams, keyItem)
    super(mob, player, optParams, keyItem)

    local tier = tierByAbyssite[mob:getLocalVar('[VoidWalker]PopedWith')]

    if player and player:isPC() and tier then
        local items = {}

        for _, drop in ipairs(drops[tier]) do
            table.insert(items, { drop[1], math.random(drop[2], drop[3]) })
        end

        npcUtil.giveItem(player, items)
    end
end)

return m
