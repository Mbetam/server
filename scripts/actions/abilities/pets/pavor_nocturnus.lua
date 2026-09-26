-----------------------------------
-- Pavor Nocturnus
-- Family: Avatar (Diabolos)
-- Description: Lures an enemy into an eternal nightmare.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: tries Death, which
-- nearly only lands on a sleeping, non-NM target; if Death misses it Dispels one effect instead (accurate).
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local asleep =
        target:hasStatusEffect(xi.effect.SLEEP_I) or
        target:hasStatusEffect(xi.effect.SLEEP_II) or
        target:hasStatusEffect(xi.effect.LULLABY)

    if asleep and not target:isNM() and not xi.data.statusEffect.isTargetImmune(target, xi.effect.KO, xi.element.DARK) then
        local resist = xi.combat.magicHitRate.calculateResistRate(pet, target,
        {
            magicalElement = xi.element.DARK,
            bonusMacc      = xi.summon.getSummoningSkillOverCap(pet),
            actorStat      = xi.mod.INT,
        })

        if resist >= 0.5 then
            local damage = target:getHP()

            target:takeDamage(damage, pet, xi.attackType.MAGICAL, xi.damageType.DARK)
            petskill:setMsg(xi.msg.basic.USES_JA_TAKE_DAMAGE)

            return damage
        end
    end

    local effect = target:dispelStatusEffect()

    if effect == xi.effect.NONE then
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    else
        petskill:setMsg(xi.msg.basic.SKILL_ERASE)
    end

    target:updateEnmity(pet)

    return effect
end

return abilityObject
