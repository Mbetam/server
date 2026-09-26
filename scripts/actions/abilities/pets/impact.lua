-----------------------------------
-- Impact
-- Family: Avatar (Fenrir)
-- Description: Deals dark damage that lowers all of an enemy's attributes.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; fTP is an ESTIMATE
-- (BG: "pet TP adds a lot, similar to merit pacts"), set a step above the level-75 merit pacts. Stats down:
-- -floor(summoning skill / 20) each (BG), 3 minutes (as the Impact spell).
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
    params.fTP             = { 6.0, 9.0, 12.0 }
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

        local power = math.floor(summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) / 20)

        if power > 0 then
            for _, effectId in ipairs({ xi.effect.STR_DOWN, xi.effect.DEX_DOWN, xi.effect.VIT_DOWN, xi.effect.AGI_DOWN, xi.effect.INT_DOWN, xi.effect.MND_DOWN, xi.effect.CHR_DOWN }) do
                target:addStatusEffect(effectId, { power = power, duration = 180, origin = pet })
            end
        end
    end

    return info.damage
end

return abilityObject
