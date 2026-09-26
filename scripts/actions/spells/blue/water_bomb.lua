-----------------------------------
-- Spell: Water Bomb
-- Deals water damage in an area. Additional effect: Silence.
-- Level: 92, Type: Magical (Water), Monster: Poroggo (Aquan)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem       = xi.ecosystem.AQUAN
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.WATER
    params.dStat           = xi.mod.INT
    params.ftp0            = 2.0
    params.dStatMultiplier = 1.5
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.int_wsc = 0.2
    params.mnd_wsc = 0.1

    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.SILENCE, 1, 0, 90 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
