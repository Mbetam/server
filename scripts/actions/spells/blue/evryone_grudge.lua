-----------------------------------
-- Spell: Everyone's Grudge
-- Deals damage based on the number of Tonberries you have defeated.
-- Level: 80, Type: Magical, Monster: Tonberry (Beastmen)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; damage = 5 per Tonberry kill (the counter the Tonberries' own Everyone's Grudge uses, EVERYONES_GRUDGE_KILLS), ignores shadows. The BLU multiplier is an ESTIMATE (the mob version's fTP 5)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params      = xi.spells.blue.getDefaultParams(caster)
    params.ecosystem  = xi.ecosystem.BEASTMEN
    params.attackType = xi.attackType.MAGICAL
    params.damageType = xi.damageType.DARK

    local damage = caster:getCharVar('EVERYONES_GRUDGE_KILLS') * 5

    if damage <= 0 then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return 0
    end

    return xi.spells.blue.applySpellDamage(caster, target, spell, damage, params)
end

return spellObject
