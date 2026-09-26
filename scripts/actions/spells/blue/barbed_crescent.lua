-----------------------------------
-- Spell: Barbed Crescent
-- Damage varies with TP. Additional effect: Accuracy Down.
-- Level: 99, Type: Physical (Slashing), Monster: Fomor (Undead)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Accuracy about -30 for 120 s; BG lists a flat fTP 2.0
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params          = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem      = xi.ecosystem.UNDEAD
    params.tpModifier     = xi.spells.blue.tpMod.DAMAGE
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.skillchainType = xi.skillchainType.DISTORTION

    params.numHits       = 1
    params.ftp0          = 2.0
    params.ftp1500       = 2.0
    params.ftp3000       = 2.0
    params.ftpAzure      = 2.25
    params.baseDamageCap = 100
    params.skillchainType2 = xi.skillchainType.LIQUEFACTION

    params.dex_wsc = 0.5

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.ACCURACY_DOWN, 30, 0, 120 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
