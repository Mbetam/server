-----------------------------------
-- Lunar Bay
-- Family: Avatar (Fenrir)
-- Description: Deals darkness damage to an enemy.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; fTP is an ESTIMATE
-- (not published): the level-75 merit pacts' values.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local params = {}

    params.baseDamage      = pet:getMainLvl() + 2
    params.fTP             = { 5.3570, 8.0273, 10.7031 }
    params.element         = xi.element.DARK
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.DARK
    params.shadowBehavior  = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.canMagicBurst   = true
    params.primaryMessage  = xi.msg.basic.USES_JA_TAKE_DAMAGE
    params.int_wSC         = 0.30
    params.dStatMultiplier = 1.5

    local info = xi.mobskills.mobMagicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)
    end

    return info.damage
end

return abilityObject
