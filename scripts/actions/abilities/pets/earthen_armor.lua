-----------------------------------
-- Earthen Armor
-- Family: Avatar (Titan)
-- Description: Mitigates the impact of severely damaging attacks for party members within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; any single
-- action over 75% of max HP is reduced by 45%, 1 minute. The reduction is applied in battleutils::HandleSevereDamage.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local typeEffect = xi.effect.EARTHEN_ARMOR

    if target:addStatusEffect(typeEffect, { power = 45, duration = xi.job_utils.summoner.wardDuration(summoner, 60), origin = pet }) then
        if target:getID() == action:getPrimaryTargetID() then
            petskill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT_2)
        else
            petskill:setMsg(xi.msg.basic.JA_GAIN_EFFECT)
        end
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return typeEffect
end

return abilityObject
