-----------------------------------
-- Volt Strike
-- Family: Avatar (Ramuh)
-- Description: Delivers a threefold attack that stuns target.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: STR & INT, fTP carries
-- to every hit, crit rate varies with TP, Stun 15 s, "deals more damage than Chaotic Strike" (so fTP is set just above
-- LSB's Chaotic Strike; ESTIMATE).
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local params = {}

    params.baseDamage        = pet:getWeaponDmg()
    params.numHits           = 3
    params.fTP               = { 11.0, 11.0, 11.0 }
    params.fTPSubsequentHits = { 11.0, 11.0, 11.0 }
    params.str_wSC           = 0.20
    params.int_wSC           = 0.20
    params.attackType        = xi.attackType.PHYSICAL
    params.damageType        = xi.damageType.BLUNT
    params.shadowBehavior    = xi.mobskills.shadowBehavior.NUMSHADOWS_3
    params.canCrit           = true
    params.criticalChance    = { 0.10, 0.20, 0.25 } -- as Chaotic Strike (ESTIMATE)
    params.primaryMessage    = xi.msg.basic.USES_JA_TAKE_DAMAGE

    local info = xi.mobskills.mobPhysicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)

        local effectTable =
        {
            [1] = { effectId = xi.effect.STUN, power = 1, duration = 15 },
        }

        xi.combat.action.executeMobskillStatusEffect(pet, target, petskill, effectTable, { messageBypass = true })
    end

    return info.damage
end

return abilityObject
