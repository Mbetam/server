-----------------------------------
-- Spell: Benthic Typhoon
-- Area attack that lowers defense and magic defense. Damage varies with TP.
-- Level: 83, Type: Physical (Piercing), Monster: Murex (Aquan)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Defense -10% and Magic Defense -10 for 60 s
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params          = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem      = xi.ecosystem.AQUAN
    params.tpModifier     = xi.spells.blue.tpMod.DAMAGE
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.PIERCING
    params.skillchainType = xi.skillchainType.GRAVITATION

    params.numHits       = 1
    params.ftp0          = 4.0
    params.ftp1500       = 4.5
    params.ftp3000       = 5.0
    params.ftpAzure      = 5.25
    params.baseDamageCap = 100
    params.skillchainType2 = xi.skillchainType.TRANSFIXION

    params.agi_wsc = 0.6

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN, 10, 0, 60 },
        [2] = { xi.effect.MAGIC_DEF_DOWN, 10, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
