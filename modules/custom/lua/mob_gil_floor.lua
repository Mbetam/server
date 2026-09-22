-----------------------------------
-- Every mob drops gil: at least 875 (see mob_gil.lua for the number and the rules).
-- The game calls xi.mob.onMobDeathEx for every kill BEFORE it decides how much gil to hand out, so raising the mob's gil
-- there is enough. It is called once per alliance member, which is fine: raising to a floor can be done any number of times.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
local mobGil = require('modules/custom/lua/mob_gil')
-----------------------------------

local m = Module:new('mob_gil_floor')

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    mobGil.apply(mob, xi.settings.map.MOB_GIL_MULTIPLIER)

    return super(mob, player, isKiller, isWeaponSkillKill)
end)
