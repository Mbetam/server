-----------------------------------
-- Fleet Wind
-- Family: Avatar (Garuda)
-- Description: Increases movement speed for party members within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; +20% movement speed
-- ("similar to Chocobo Mazurka"), 2 minutes. LSB has no Fleet Wind effect, so it uses Quickening (same speed cap).
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local typeEffect = xi.effect.QUICKENING

    if target:addStatusEffect(typeEffect, { power = 20, duration = xi.job_utils.summoner.wardDuration(summoner, 120), origin = pet }) then
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
