-----------------------------------
-- Spell: Blazing Bound
-- Deals fire damage to an enemy.
-- Level: 80, Type: Magical (Fire), Monster: Limule
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; BG: uses Magic Defense Bonus instead of Magic Attack Bonus (not modelled)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem       = xi.ecosystem.UNCLASSIFIED
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.FIRE
    params.dStat           = xi.mod.INT
    params.ftp0            = 3.0
    params.dStatMultiplier = 2.0
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.str_wsc = 0.3

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
