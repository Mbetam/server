-----------------------------------
-- Spell: Orcish Counterstance
-- Increases your chance of countering.
-- Level: 98, Type: Magical, Monster: Orc (Beastmen)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Counter +10% and counter damage +50%, 3 minutes (effects/counter_boost.lua)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    if not target:addStatusEffect(xi.effect.COUNTER_BOOST, { power = 10, duration = duration, origin = caster, subPower = 50 }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.COUNTER_BOOST
end

return spellObject
