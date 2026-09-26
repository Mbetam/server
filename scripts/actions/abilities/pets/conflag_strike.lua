-----------------------------------
-- Conflag Strike
-- Family: Avatar (Ifrit)
-- Description: Deals fire elemental damage. Additional effect: Burn.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: breath-type damage that
-- considers INT, Burn 30 HP/tick and INT -63 for 1 minute (Burn power 30 gives exactly that). fTP is an ESTIMATE, a step
-- above Nether Blast (the other breath-type pact).
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
    params.fTP             = { 6.5, 6.5, 6.5 }
    params.element         = xi.element.FIRE
    params.attackType      = xi.attackType.BREATH
    params.damageType      = xi.damageType.FIRE
    params.shadowBehavior  = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.canMagicBurst   = true
    params.primaryMessage  = xi.msg.basic.USES_JA_TAKE_DAMAGE
    params.int_wSC         = 0.30

    local info = xi.mobskills.mobMagicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)

        local effectTable =
        {
            [1] = { effectId = xi.effect.BURN, power = 30, tick = 3, duration = 60, bonusMacc = xi.summon.getSummoningSkillOverCap(pet) },
        }

        xi.combat.action.executeMobskillStatusEffect(pet, target, petskill, effectTable, { messageBypass = true })
    end

    return info.damage
end

return abilityObject
