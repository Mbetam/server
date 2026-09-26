-----------------------------------
-- Spell: Dark Orb
-- Deals dark damage to an enemy.
-- Level: 93, Type: Magical (Dark), Monster: Gargouille (Arcana)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem       = xi.ecosystem.ARCANA
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.DARK
    params.dStat           = xi.mod.INT
    params.ftp0            = 4.5
    params.dStatMultiplier = 2.0
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.int_wsc = 0.4

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
