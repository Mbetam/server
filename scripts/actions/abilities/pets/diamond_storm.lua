-----------------------------------
-- Diamond Storm
-- Family: Avatar (Shiva)
-- Description: Reduces evasion for enemies within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; Evasion -25, 3 minutes.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local effectTable =
    {
        [1] = { effectId = xi.effect.EVASION_DOWN, power = 25, duration = xi.job_utils.summoner.wardDuration(summoner, 180), bonusMacc = xi.summon.getSummoningSkillOverCap(pet) },
    }

    local effectId = xi.combat.action.executeMobskillStatusEffect(pet, target, petskill, effectTable, {})

    target:updateEnmity(pet)

    return effectId
end

return abilityObject
