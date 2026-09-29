-----------------------------------
-- Abyssea pops LSB left broken (found 2026-09-29 while checking Abyssea for the JSE weapon progression):
-- 1. Every ??? in Abyssea - Vunkerl, Misareaux and Uleguerand (70) had its onTrade / onTrigger commented out, so
--    none of those NMs could be popped. Here they get the retail requirements (abyssea_pops_data.lua, generated from
--    the BG Wiki zone NM tables) through LSB's own xi.abyssea.qmOnTrade / qmOnTrigger.
-- 2. Myrmecoleon (Tahrongi) spawns in retail when Lachrymater is dragged onto it; LSB has no spawn for it at all.
--    Here killing Lachrymater makes Myrmecoleon come out of the sand at that spot, claimed by the killer.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')
require('scripts/globals/mobs')
local data = require('modules/custom/lua/abyssea_pops_data')
-----------------------------------

local m = Module:new('abyssea_pops')

local zoneDirs =
{
    [xi.zone.ABYSSEA_VUNKERL]    = 'Abyssea-Vunkerl',
    [xi.zone.ABYSSEA_MISAREAUX]  = 'Abyssea-Misareaux',
    [xi.zone.ABYSSEA_ULEGUERAND] = 'Abyssea-Uleguerand',
}

-- xi.abyssea.qmOnTrigger only pops mob ids listed in the zone's IDs table. That table is rebuilt when the zone
-- loads, so the NM is registered right before each check.
local function register(zoneId, qm, mobId)
    zones[zoneId].mob[string.format('CUSTOM_POP_%s', qm:upper())] = mobId
end

for zoneId, qms in pairs(data) do
    local dir = zoneDirs[zoneId]

    for qm, pop in pairs(qms) do
        if pop.items then
            m:addOverride(string.format('xi.zones.%s.npcs.%s.onTrade', dir, qm), function(player, npc, trade)
                xi.abyssea.qmOnTrade(player, npc, trade, pop.mob, pop.items)
            end)

            m:addOverride(string.format('xi.zones.%s.npcs.%s.onTrigger', dir, qm), function(player, npc)
                xi.abyssea.qmOnTrigger(player, npc, 0, 0, pop.items) -- shows the items to trade
            end)
        else
            m:addOverride(string.format('xi.zones.%s.npcs.%s.onTrigger', dir, qm), function(player, npc)
                register(zoneId, qm, pop.mob)
                xi.abyssea.qmOnTrigger(player, npc, pop.mob, pop.kis)
            end)
        end
    end
end

-----------------------------------
-- Myrmecoleon
-----------------------------------
local MYRMECOLEON = 16961939 -- Abyssea - Tahrongi (Lachrymater: 16961928, ??? qm_lachrymater)

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    if isKiller and player and mob:getZoneID() == xi.zone.ABYSSEA_TAHRONGI and mob:getName() == 'Lachrymater' then
        local nm = GetMobByID(MYRMECOLEON)

        if nm and not nm:isSpawned() then
            nm:setSpawn(mob:getXPos(), mob:getYPos(), mob:getZPos())
            SpawnMob(MYRMECOLEON):updateClaim(player)
            nm:setLocalVar('[ClaimedBy]', player:getID())
        end
    end

    return super(mob, player, isKiller, isWeaponSkillKill)
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.abysseaPops = data -- for tests

return m
