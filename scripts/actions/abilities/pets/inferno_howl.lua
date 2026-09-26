-----------------------------------
-- Inferno Howl
-- Family: Avatar (Ifrit)
-- Description: Grants the effect of "Enfire" to party members within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; power 20 + (skill - 300) / 10
-- (BG formula), 1 minute.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local power = math.max(5, 20 + math.floor((summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) - 300) / 10))
    target:delStatusEffect(xi.effect.ENFIRE)

    local typeEffect = xi.effect.ENFIRE

    if target:addStatusEffect(typeEffect, { power = power, duration = xi.job_utils.summoner.wardDuration(summoner, 60), origin = pet }) then
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
