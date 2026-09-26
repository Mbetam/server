-----------------------------------
-- Spell: Bloodrake
-- Threefold attack. Damage varies with TP. Additional effect: HP Drain. (Unbridled Learning)
-- Level: 99, Type: Physical (Slashing), Monster: Vampyr (Undead)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; fTP at 3000 TP is an ESTIMATE (only 0 and 1500 are published); has an attack bonus (+25% here, ESTIMATE)
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
    params.skillchainType = xi.skillchainType.DARKNESS

    params.numHits       = 3
    params.ftp0          = 1.0
    params.ftp1500       = 1.1375
    params.ftp3000       = 1.275
    params.ftpAzure      = 1.35
    params.baseDamageCap = 100
    params.skillchainType2 = xi.skillchainType.DISTORTION
    params.attackMult    = 1.25
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3

    params.str_wsc = 0.3
    params.mnd_wsc = 0.3

    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then -- (params.hitsLanded is not filled in by usePhysicalSpell)
        return damage
    end

    -- Absorbs 100% of the damage dealt; hurts undead but does not heal from them (BG Wiki)
    if damage > 0 and target:getEcosystem() ~= xi.ecosystem.UNDEAD then
        caster:addHP(damage)
    end

    return damage
end

return spellObject
