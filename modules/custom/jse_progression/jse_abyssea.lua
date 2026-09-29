-----------------------------------
-- JSE weapon progression, the Abyssea side (jse_config.lua):
-- 1. Material drops on the 27 NMs: one at 100% per kill, and for the "1-2 per kill" NMs a second one at twoChance
--    percent. Added to the normal loot roll (their existing drops stay); the server drop multiplier is divided out
--    of the second roll so 50 really means 50.
-- 2. Difficulty: HP, attack and magic attack scaled on every spawn of those NMs (family tier x megaboss extra).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
local config = require('modules/custom/jse_progression/jse_config')
-----------------------------------

local m = Module:new('jse_abyssea')

local abyssea = {}

-----------------------------------
-- 1: drops
-----------------------------------
abyssea.dropsFor = function(mob)
    local zoneDrops = config.drops[mob:getZoneID()]

    return zoneDrops and zoneDrops[mob:getName()]
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    local drop = isKiller and abyssea.dropsFor(mob)

    if drop then
        mob:addListener('ITEM_DROPS', 'JSE_MATERIAL_DROPS', function(mobArg, loot)
            loot:addItemFixed(drop[1], 1000)

            if drop[2] then
                local multiplier = math.max(1, xi.settings.map.DROP_RATE_MULTIPLIER or 1)
                loot:addItemFixed(drop[1], math.floor(drop[2] * 10 / multiplier))
            end
        end)
    end

    return super(mob, player, isKiller, isWeaponSkillKill)
end)

-----------------------------------
-- 2: difficulty
-----------------------------------
abyssea.multiplierFor = function(mob)
    local tier = config.difficulty.tiers[mob:getZoneID()] or 1

    if config.difficulty.megabosses[mob:getName()] then
        tier = tier * config.difficulty.megabossExtra
    end

    return tier
end

-- Applied on every spawn. The unscaled max HP is remembered the first time, so respawns never stack the bonus.
abyssea.scale = function(mob)
    local multiplier = abyssea.multiplierFor(mob)

    if multiplier == 1 then
        return
    end

    local baseHP = mob:getLocalVar('JSE_BASE_HP')

    if baseHP == 0 then
        baseHP = mob:getMaxHP()
        mob:setLocalVar('JSE_BASE_HP', baseHP)
    end

    local bonus = math.floor((multiplier - 1) * 100 + 0.5)

    mob:setMaxHP(math.floor(baseHP * multiplier))
    mob:setHP(mob:getMaxHP())
    mob:setMod(xi.mod.ATTP, bonus)
    mob:setMod(xi.mod.MATT, bonus)
end

local zoneScripts =
{
    [xi.zone.ABYSSEA_LA_THEINE]  = 'Abyssea-La_Theine',
    [xi.zone.ABYSSEA_TAHRONGI]   = 'Abyssea-Tahrongi',
    [xi.zone.ABYSSEA_KONSCHTAT]  = 'Abyssea-Konschtat',
    [xi.zone.ABYSSEA_VUNKERL]    = 'Abyssea-Vunkerl',
    [xi.zone.ABYSSEA_MISAREAUX]  = 'Abyssea-Misareaux',
    [xi.zone.ABYSSEA_ATTOHWA]    = 'Abyssea-Attohwa',
    [xi.zone.ABYSSEA_ALTEPA]     = 'Abyssea-Altepa',
    [xi.zone.ABYSSEA_ULEGUERAND] = 'Abyssea-Uleguerand',
    [xi.zone.ABYSSEA_GRAUBERG]   = 'Abyssea-Grauberg',
}

for zoneId, dir in pairs(zoneScripts) do
    require(string.format('scripts/zones/%s/Zone', dir))

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', dir), function(zone)
        super(zone)

        for name in pairs(config.drops[zoneId] or {}) do
            for _, mob in ipairs(zone:queryEntitiesByName(name) or {}) do
                mob:addListener('SPAWN', 'JSE_DIFFICULTY', abyssea.scale)
            end
        end
    end)
end

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.jseAbyssea = abyssea -- for tests

return m
