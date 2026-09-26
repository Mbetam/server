-----------------------------------
-- Spell: Thunder Breath
-- Deals lightning breath damage in a cone.
-- Level: 97, Type: Breath (Thunder), Monster: Wyvern (Dragon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; the HP / level divisors are an ESTIMATE between Heat Breath and Wind Breath
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params      = {}
    params.ecosystem  = xi.ecosystem.DRAGON
    params.attackType = xi.attackType.BREATH
    params.damageType = xi.damageType.THUNDER
    params.hpMod      = 3
    params.lvlMod     = 0
    params.isConal    = true

    return xi.spells.blue.useBreathSpell(caster, target, spell, params)
end

return spellObject
