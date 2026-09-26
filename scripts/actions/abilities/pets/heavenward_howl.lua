-----------------------------------
-- Heavenward Howl
-- Family: Avatar (Fenrir)
-- Description: Grants the effect of HP Drain or MP Drain to party members within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; Endrain % of melee
-- damage while the moon waxes to full, Enaspir % while it wanes to new; 1 minute. Handled in battleutils::HandleEnspell.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

-- moon phase -> { effect, percent } (BG Wiki)
local byMoon =
{
    [xi.moonCycle.FIRST_QUARTER]           = { xi.effect.ENDRAIN, 5 },
    [xi.moonCycle.LESSER_WAXING_GIBBOUS]   = { xi.effect.ENDRAIN, 8 },
    [xi.moonCycle.GREATER_WAXING_GIBBOUS]  = { xi.effect.ENDRAIN, 12 },
    [xi.moonCycle.FULL_MOON]               = { xi.effect.ENDRAIN, 15 },
    [xi.moonCycle.GREATER_WANING_GIBBOUS]  = { xi.effect.ENDRAIN, 12 },
    [xi.moonCycle.LESSER_WANING_GIBBOUS]   = { xi.effect.ENDRAIN, 8 },
    [xi.moonCycle.THIRD_QUARTER]           = { xi.effect.ENASPIR, 1 },
    [xi.moonCycle.GREATER_WANING_CRESCENT] = { xi.effect.ENASPIR, 2 },
    [xi.moonCycle.LESSER_WANING_CRESCENT]  = { xi.effect.ENASPIR, 4 },
    [xi.moonCycle.NEW_MOON]                = { xi.effect.ENASPIR, 5 },
    [xi.moonCycle.LESSER_WAXING_CRESCENT]  = { xi.effect.ENASPIR, 4 },
    [xi.moonCycle.GREATER_WAXING_CRESCENT] = { xi.effect.ENASPIR, 2 },
}

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local entry = byMoon[getVanadielMoonCycle()] or { xi.effect.ENDRAIN, 5 }

    target:delStatusEffect(xi.effect.ENDRAIN)
    target:delStatusEffect(xi.effect.ENASPIR)

    if target:addStatusEffect(entry[1], { power = entry[2], duration = xi.job_utils.summoner.wardDuration(summoner, 60), origin = pet }) then
        if target:getID() == action:getPrimaryTargetID() then
            petskill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT_2)
        else
            petskill:setMsg(xi.msg.basic.JA_GAIN_EFFECT)
        end
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return entry[1]
end

return abilityObject
