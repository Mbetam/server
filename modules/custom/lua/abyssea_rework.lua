-----------------------------------
-- Abyssea rework (Eric, 2026-09-28; NocSouls baseline "reworked Abyssea, large cruor from NMs"):
-- 1. Cruor from kills. LSB leaves it off (charutils.cpp: the retail chain formula is unknown, and it only paid on kills
--    that give EXP, which a level 99 rarely gets from Abyssea's level 80-95 monsters). Here every kill in Abyssea pays
--    each alliance member in the zone: normal monsters level x cruorPerLevel, notorious monsters level x nmCruorPerLevel.
-- 2. Unlimited Visitant status: permanent from the moment you enter. The Conflux Surveyor's time purchase and the
--    Sturdy Pyxis time reward would turn it back into a timer, so they are switched off.
-- 3. (Removed 2026-09-29: the level 80 Empyrean weapon drops. The JSE weapon progression sells base weapons at the
--    Splintery Chest instead; see modules/custom/jse_progression/.)
-- 4. NM pop key items drop 50% of the time instead of 20% (a red proc still makes them certain). Atma rolls unchanged.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')
require('scripts/globals/abyssea/conflux_surveyor')
require('scripts/globals/abyssea/sturdypyxis/time')
require('scripts/globals/mobs')
-----------------------------------

local m = Module:new('abyssea_rework')

local config =
{
    popKeyItemChance = 50, -- percent; LSB (and roughly retail): 20

    cruorPerLevel   = 3,  -- a level 85 monster: 255 cruor
    nmCruorPerLevel = 30, -- a level 85 NM: 2,550 cruor
}

local abysseaZones =
{
    [xi.zone.ABYSSEA_KONSCHTAT]        = true,
    [xi.zone.ABYSSEA_TAHRONGI]         = true,
    [xi.zone.ABYSSEA_LA_THEINE]        = true,
    [xi.zone.ABYSSEA_ATTOHWA]          = true,
    [xi.zone.ABYSSEA_MISAREAUX]        = true,
    [xi.zone.ABYSSEA_VUNKERL]          = true,
    [xi.zone.ABYSSEA_ALTEPA]           = true,
    [xi.zone.ABYSSEA_ULEGUERAND]       = true,
    [xi.zone.ABYSSEA_GRAUBERG]         = true,
    [xi.zone.ABYSSEA_EMPYREAL_PARADOX] = true,
}

local rework = {}
rework.config = config

-- Cruor one member gets for a kill
rework.cruorFor = function(mob)
    return mob:getMainLvl() * (mob:isNM() and config.nmCruorPerLevel or config.cruorPerLevel)
end

-----------------------------------
-- 1: kills
-----------------------------------
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    local zoneId = mob:getZoneID()

    if player and player:isPC() and abysseaZones[zoneId] and player:getZoneID() == zoneId then
        local cruor = rework.cruorFor(mob)

        if cruor > 0 then
            player:addCurrency('cruor', cruor)
            player:messageSpecial(zones[zoneId].text.CRUOR_TOTAL, cruor, player:getCurrency('cruor'))
        end

    end

    return super(mob, player, isKiller, isWeaponSkillKill)
end)

-----------------------------------
-- 4: pop key items. giveNMDrops asks canGiveNMKI with 20 for the pop key items and 10 for other members' Atmas.
-----------------------------------
m:addOverride('xi.abyssea.canGiveNMKI', function(mob, dropChance)
    if dropChance == 20 then
        dropChance = config.popKeyItemChance
    end

    return super(mob, dropChance)
end)

-----------------------------------
-- 2: unlimited Visitant status
-----------------------------------
-- Permanent (no duration, no tick: no countdown) and with the Visitant icon (real status, not the 5-minute grace)
rework.makePermanent = function(player)
    local effect = player:getStatusEffect(xi.effect.VISITANT)

    if effect and effect:getIcon() == xi.effect.VISITANT and effect:getDuration() == 0 then
        return
    end

    player:delStatusEffectSilent(xi.effect.VISITANT)
    player:addStatusEffect(xi.effect.VISITANT, { icon = xi.effect.VISITANT, origin = player })
end

m:addOverride('xi.abyssea.afterZoneIn', function(player)
    rework.makePermanent(player)
end)

m:addOverride('xi.abyssea.surveyorOnTrigger', function(player, npc)
    rework.makePermanent(player)
    player:printToPlayer('Your visitant status never runs out on this server; no Traverser Stones needed.', xi.msg.channel.NS_SAY, 'Conflux Surveyor')
end)

m:addOverride('xi.pyxis.time.giveTime', function(npc, player)
    -- The chest's time reward: nothing to add to unlimited time
    player:printToPlayer('The chest held more time, but your visitant status is already unlimited.', xi.msg.channel.SYSTEM_3)
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.abysseaRework = rework -- for tests

return m
