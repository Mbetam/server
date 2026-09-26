-----------------------------------
-- Spell: Endark II
-- Adds darkness damage to your attacks.
-- Custom (2026-09-25): LSB had no script. Uses the Endark effect (it replaces Endark on retail) with BG Wiki's
-- Endark II potency: skill >= 500: floor((floor((skill + 2) * 5 / 66) + 7) * 2.5), below: floor(floor((skill + 400) / 20) * 2.5).
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local skill   = target:getSkillLevel(xi.skill.DARK_MAGIC)
    local potency = 0

    if skill >= 500 then
        potency = math.floor((math.floor((skill + 2) * 5 / 66) + 7) * 2.5)
    else
        potency = math.floor(math.floor((skill + 400) / 20) * 2.5)
    end

    target:delStatusEffect(xi.effect.ENDARK)

    if target:addStatusEffect(xi.effect.ENDARK, { power = potency, duration = 180, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.ENDARK
end

return spellObject
