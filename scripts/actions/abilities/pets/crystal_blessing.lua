-----------------------------------
-- Crystal Blessing
-- Family: Avatar (Shiva)
-- Description: Confers a TP bonus on party members within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; TP Bonus +250, 3 minutes.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local typeEffect = xi.effect.TP_BONUS

    if target:addStatusEffect(typeEffect, { power = 250, duration = xi.job_utils.summoner.wardDuration(summoner, 180), origin = pet }) then
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
