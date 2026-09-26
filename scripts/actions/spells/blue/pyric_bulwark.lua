-----------------------------------
-- Spell: Pyric Bulwark
-- Grants immunity to physical damage for one attack. (Unbridled Learning)
-- Level: 98, Type: Magical, Monster: Hydra (Dragon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; lasts 5 minutes or one physical attack; the TAKE_DAMAGE listener ends it after the first physical hit
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    if not target:addStatusEffect(xi.effect.PHYSICAL_SHIELD, { power = 1, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return xi.effect.PHYSICAL_SHIELD
    end

    target:removeListener('PYRIC_BULWARK')
    target:addListener('TAKE_DAMAGE', 'PYRIC_BULWARK', function(entity, amount, attacker, attackType, damageType)
        if attackType == xi.attackType.PHYSICAL or attackType == xi.attackType.RANGED then
            entity:delStatusEffect(xi.effect.PHYSICAL_SHIELD)
            entity:removeListener('PYRIC_BULWARK')
        end
    end)

    return xi.effect.PHYSICAL_SHIELD
end

return spellObject
