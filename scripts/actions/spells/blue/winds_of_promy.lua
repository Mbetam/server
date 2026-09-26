-----------------------------------
-- Spell: Winds of Promyvion
-- Removes one detrimental magic effect from party members in range.
-- Level: 89, Type: Magical, Monster: Thinker (Empty)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; removes what Erase would remove
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect = target:eraseStatusEffect()

    if effect == xi.effect.NONE then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_ERASE)
    end

    return effect
end

return spellObject
