-----------------------------------
-- Spell: Stona
-- Removes petrification from target.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    if target:delStatusEffect(xi.effect.PETRIFICATION) then
        spell:setMsg(xi.msg.basic.MAGIC_REMOVE_EFFECT)
        xi.job_utils.white_mage.applyDivineCaress(caster, target, xi.effect.PETRIFICATION)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.PETRIFICATION
end

return spellObject
