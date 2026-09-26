-----------------------------------
-- Spell: Gates of Hades
-- Deals fire damage in an area. Additional effect: Burn. (Unbridled Learning)
-- Level: 97, Type: Magical (Fire), Monster: Cerberus (Beast)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Burn 22 HP/tick and INT -47 (Burn power 22), 90 s
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
    params.damageType      = xi.damageType.FIRE
    params.dStat           = xi.mod.INT
    params.ftp0            = 5.0
    params.dStatMultiplier = 1.0
    params.baseDamageCap   = 999 -- uncapped, as LSB's other top-level magical spells
    params.str_wsc = 0.2
    params.dex_wsc = 0.2

    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.BURN, 22, 3, 90 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
