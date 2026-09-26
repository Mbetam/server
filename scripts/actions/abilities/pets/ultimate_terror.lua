-----------------------------------
-- Ultimate Terror
-- Family: Avatar (Diabolos)
-- Description: Absorbs attributes from enemies within area of effect.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: absorbs 0-7 random
-- attributes per enemy, 21 points each, decaying over time (as the Absorb spells). Duration is not published: 90 s.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

local attributesDown =
{
    xi.effect.STR_DOWN,
    xi.effect.DEX_DOWN,
    xi.effect.VIT_DOWN,
    xi.effect.AGI_DOWN,
    xi.effect.INT_DOWN,
    xi.effect.MND_DOWN,
    xi.effect.CHR_DOWN,
}

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local shuffled = utils.shuffle(attributesDown)
    local drained  = 0

    for i = 1, math.randomInt(0, 7) do
        if xi.mobskills.mobDrainAttribute(pet, target, shuffled[i], 21, 3, xi.job_utils.summoner.wardDuration(summoner, 90)) > 0 then
            drained = drained + 1
        end
    end

    if drained > 0 then
        petskill:setMsg(xi.msg.basic.EFFECT_DRAINED)
    else
        petskill:setMsg(xi.msg.basic.SKILL_MISS)
    end

    target:updateEnmity(pet)

    return drained
end

return abilityObject
