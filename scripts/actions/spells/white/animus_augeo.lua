-----------------------------------
-- Spell: Animus Augeo
-- Facilitates enmity gain for target party member (Enmity +20).
-- Custom (2026-09-25): LSB had no script; values in xi.spells.enhancing's table (enhancing_spell.lua), from BG Wiki.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.enhancing.useEnhancingSpell(caster, target, spell)
end

return spellObject
