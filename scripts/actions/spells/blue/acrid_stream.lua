-----------------------------------
-- Spell: Acrid Stream
-- Deals water damage in a cone. Additional effect: Magic Defense Down.
-- Level: 77, Type: Magical (Water), Monster: Clionid (Aquan)
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
    params.ftp0            = 2.296875
    params.dStatMultiplier = 2.0
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.mnd_wsc = 0.3

    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.MAGIC_DEF_DOWN, 10, 0, 120 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
