-----------------------------------
-- Ruinous Omen
-- Family: Avatar (Diabolos)
-- Description: Uses all MP and reduces the HP of enemies in range by a random percentage.
-- Custom (2026-09-25): LSB had no script for this Blood Pact. Effect and duration from BG Wiki; BG: Astral Flow
-- only, consumes all MP, affected by magic attack/defense and resists, about 10% cap on NMs. The random range (5-25% of
-- current HP) is an ESTIMATE. It never KOs (as the monster version notes).
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    -- Consumes all MP (the level x2 requirement was checked by canUseBloodPact)
    if summoner and summoner:isPC() then
        summoner:setMP(0)
    end

    local resist = xi.combat.magicHitRate.calculateResistRate(pet, target,
    {
        magicalElement = xi.element.DARK,
        bonusMacc      = xi.summon.getSummoningSkillOverCap(pet),
        actorStat      = xi.mod.INT,
    })

    local percent = math.randomInt(5, 25)

    if target:isNM() then
        percent = math.min(percent, 10)
    end

    local damage = math.floor(target:getHP() * percent / 100 * resist)
    damage       = utils.clamp(damage, 0, math.max(target:getHP() - 1, 0))

    target:takeDamage(damage, pet, xi.attackType.MAGICAL, xi.damageType.DARK)
    target:updateEnmity(pet)
    petskill:setMsg(xi.msg.basic.USES_JA_TAKE_DAMAGE)

    return damage
end

return abilityObject
