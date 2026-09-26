-----------------------------------
-- Spell: Vanity Dive
-- Damage varies with TP.
-- Level: 82, Type: Physical (Slashing), Monster: Wanderer (Empty)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; +66% attack and a large accuracy bonus
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params          = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem      = xi.ecosystem.EMPTY
    params.tpModifier     = xi.spells.blue.tpMod.DAMAGE
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.skillchainType = xi.skillchainType.SCISSION

    params.numHits       = 1
    params.ftp0          = 3.0
    params.ftp1500       = 4.0
    params.ftp3000       = 4.5
    params.ftpAzure      = 4.75
    params.baseDamageCap = 100
    params.attackMult    = 1.66
    params.bonusAcc      = 60

    params.dex_wsc = 0.5

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    return damage
end

return spellObject
