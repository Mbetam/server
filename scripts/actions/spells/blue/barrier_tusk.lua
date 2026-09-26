-----------------------------------
-- Spell: Barrier Tusk
-- Reduces the damage you take.
-- Level: 91, Type: Magical, Monster: Marid (Beast)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; -15% damage taken after the damage-taken cap, 3 minutes; overwritten by but does not overwrite Phalanx, so it is a Phalanx effect with sub power 1 (effects/phalanx.lua)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    if target:hasStatusEffect(xi.effect.PHALANX) or
        not target:addStatusEffect(xi.effect.PHALANX, { power = 0, duration = duration, origin = caster, subPower = 1 })
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.PHALANX
end

return spellObject
