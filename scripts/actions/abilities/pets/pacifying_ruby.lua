-----------------------------------
-- Pacifying Ruby
-- Family: Avatar (Carbuncle)
-- Description: Reduces enmity of target party member.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; every monster hating the
-- target loses 25% of its enmity toward them (like Accomplice, but the enmity is removed, not moved to Carbuncle).
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local lowered = 0

    for _, mob in ipairs(target:getNotorietyList()) do
        if mob:isMob() then
            mob:lowerEnmity(target, 25)
            lowered = lowered + 1
        end
    end

    if lowered > 0 then
        petskill:setMsg(xi.msg.basic.JA_ENMITY_DECREASE)
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return 0
end

return abilityObject
