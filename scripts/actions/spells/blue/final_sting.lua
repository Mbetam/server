-----------------------------------
-- Spell: Final Sting
-- Deals damage proportional to your HP, then reduces your HP to 1. Damage varies with TP.
-- Level: 81, Type: Physical (Piercing), Monster: Bee (Vermin)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; damage = your current HP, capped at 50% of the target's max HP (65% if it is far below you); no Weakness, and no HP lost if it fails. Ignores shadows
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params      = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem  = xi.ecosystem.VERMIN
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.PIERCING

    local hp = caster:getHP()

    if hp <= 1 then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return 0
    end

    local capShare = 0.50

    if caster:getMainLvl() - target:getMainLvl() >= 10 then
        capShare = 0.65
    end

    local damage = math.min(hp - 1, math.floor(target:getMaxHP() * capShare))

    damage = xi.spells.blue.applySpellDamage(caster, target, spell, damage, params)
    caster:setHP(1)

    return damage
end

return spellObject
