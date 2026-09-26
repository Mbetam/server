-----------------------------------
-- Spell: Harden Shell
-- Enhances defense. (Unbridled Learning)
-- Level: 95, Type: Magical, Monster: Adamantoise (Lizard)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Defense +100%, 90 s, works with Diffusion
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 90)

    if not target:addStatusEffect(xi.effect.DEFENSE_BOOST, { power = 100, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.DEFENSE_BOOST
end

return spellObject
