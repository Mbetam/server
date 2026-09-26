-----------------------------------
-- Spell: Osmosis
-- Steals HP and one beneficial effect from an enemy. Ineffective against undead.
-- Level: 84, Type: Magical (Dark), Monster: Amoeban (Amorph)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; HP drained = floor(Blue Magic skill x 0.11) x 7; the effect steal cannot miss
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    if target:getEcosystem() == xi.ecosystem.UNDEAD then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return 0
    end

    local drain = math.floor(caster:getSkillLevel(xi.skill.BLUE_MAGIC) * 0.11) * 7
    drain       = math.min(drain, target:getHP())

    target:takeDamage(drain, caster, xi.attackType.MAGICAL, xi.damageType.DARK)
    caster:addHP(drain)
    target:updateEnmityFromDamage(caster, drain)

    caster:stealStatusEffect(target, xi.effectFlag.DISPELABLE)

    spell:setMsg(xi.msg.basic.MAGIC_DRAIN_HP)

    return drain
end

return spellObject
