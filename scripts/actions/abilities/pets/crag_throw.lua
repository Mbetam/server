-----------------------------------
-- Crag Throw
-- Family: Avatar (Titan)
-- Description: Delivers a ranged attack that slows target.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: STR & AGI, Slow 30%
-- for 2 minutes, accuracy varies with TP. fTP is an ESTIMATE, a step above Mountain Buster.
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
    params.numHits           = 1
    params.fTP               = { 8.0, 10.0, 12.0 }
    params.fTPSubsequentHits = { 8.0, 10.0, 12.0 }
    params.str_wSC           = 0.20
    params.agi_wSC           = 0.20
    params.attackType        = xi.attackType.PHYSICAL
    params.damageType        = xi.damageType.BLUNT
    params.shadowBehavior    = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.primaryMessage    = xi.msg.basic.USES_JA_TAKE_DAMAGE
    params.accuracyModifier  = { 0, 30, 60 } -- BG: accuracy varies with TP (amounts are an ESTIMATE)

    local info = xi.mobskills.mobPhysicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)

        local effectTable =
        {
            [1] = { effectId = xi.effect.SLOW, power = 3000, duration = 120, bonusMacc = xi.summon.getSummoningSkillOverCap(pet) },
        }

        xi.combat.action.executeMobskillStatusEffect(pet, target, petskill, effectTable, { messageBypass = true })
    end

    return info.damage
end

return abilityObject
