-----------------------------------
-- Spell: Ice Carol II
-- Increases ice resistance and sometimes nullifies ice damage for party members within the area of effect.
-- Custom (2026-09-25): LSB had no script. Resistance +100, nullification 15% (+1% per Carol+, x2 Soul Voice,
-- x1.5 Marcato, cap 40%) per BG Wiki; see xi.spells.enhancing.useEnhancingSong and effects/carol.lua.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.enhancing.useEnhancingSong(caster, target, spell)
end

return spellObject
