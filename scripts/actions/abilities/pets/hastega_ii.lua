-----------------------------------
-- Hastega II
-- Family: Avatar (Garuda)
-- Description: Gives party members within area of effect the effect of "Haste."
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; Magic Haste 307/1024
-- (29.98%), 3 minutes, plus the same summoning-skill bonus time as Hastega.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local bonusTime = utils.clamp(summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) - 300, 0, 200)

    local typeEffect = xi.effect.HASTE

    if target:addStatusEffect(typeEffect, { power = 2998, duration = xi.job_utils.summoner.wardDuration(summoner, 180 + bonusTime), origin = pet }) then
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
