-----------------------------------
-- Shock Squall
-- Family: Avatar (Ramuh)
-- Description: Temporarily prevents all enemies within area of effect from acting.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; Stun, 15 s unresisted.
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
        [1] = { effectId = xi.effect.STUN, power = 1, duration = xi.job_utils.summoner.wardDuration(summoner, 15), bonusMacc = xi.summon.getSummoningSkillOverCap(pet) },
    }

    local effectId = xi.combat.action.executeMobskillStatusEffect(pet, target, petskill, effectTable, {})

    target:updateEnmity(pet)

    return effectId
end

return abilityObject
