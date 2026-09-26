-----------------------------------
-- Spell: Bilgestorm
-- Area attack. Additional effect: Attack, Accuracy and Defense Down. (Unbridled Learning)
-- Level: 99, Type: Physical (Slashing), Monster: Dvergr
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Defense -25%, Attack -25%, Accuracy -10, each resisted separately, 30-60 s. fTP and WSC are not published: ESTIMATE
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params          = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem      = xi.ecosystem.UNCLASSIFIED
    params.tpModifier     = xi.spells.blue.tpMod.DAMAGE
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.skillchainType = xi.skillchainType.DARKNESS

    params.numHits       = 1
    params.ftp0          = 3.0
    params.ftp1500       = 3.5
    params.ftp3000       = 4.0
    params.ftpAzure      = 4.5
    params.baseDamageCap = 100
    params.skillchainType2 = xi.skillchainType.GRAVITATION

    params.str_wsc = 0.3
    params.vit_wsc = 0.3

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN, 25, 0, 60 },
        [2] = { xi.effect.ATTACK_DOWN, 25, 0, 60 },
        [3] = { xi.effect.ACCURACY_DOWN, 10, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
