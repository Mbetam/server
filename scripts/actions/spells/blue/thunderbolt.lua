-----------------------------------
-- Spell: Thunderbolt
-- Deals lightning damage in an area. Additional effect: Stun. (Unbridled Learning)
-- Level: 95, Type: Magical (Thunder), Monster: Behemoth (Beast)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; stun duration is not published (8 s here)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem       = xi.ecosystem.BEAST
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.THUNDER
    params.dStat           = xi.mod.INT
    params.ftp0            = 4.0
    params.dStatMultiplier = 2.0
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.int_wsc = 0.3
    params.mnd_wsc = 0.2

    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.STUN, 1, 0, 8 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
