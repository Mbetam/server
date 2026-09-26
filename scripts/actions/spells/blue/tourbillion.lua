-----------------------------------
-- Spell: Tourbillion
-- Area attack. Additional effect: Defense Down (duration varies with TP). (Unbridled Learning)
-- Level: 97, Type: Physical (Blunt), Monster: Khimaira (Beast)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Defense about -33%, 60-120 s by TP
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params          = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem      = xi.ecosystem.BEAST
    params.tpModifier     = xi.spells.blue.tpMod.DAMAGE
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.BLUNT
    params.skillchainType = xi.skillchainType.LIGHT

    params.numHits       = 1
    params.ftp0          = 4.0
    params.ftp1500       = 4.0
    params.ftp3000       = 4.0
    params.ftpAzure      = 4.5
    params.baseDamageCap = 100
    params.skillchainType2 = xi.skillchainType.FRAGMENTATION

    params.str_wsc = 0.25
    params.mnd_wsc = 0.25

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN, 33, 0, 60 + math.floor(caster:getTP() / 50) },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
