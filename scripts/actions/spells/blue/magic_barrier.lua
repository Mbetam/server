-----------------------------------
-- Spell: Magic Barrier
-- Grants a Magic Shield effect.
-- Level: 82, Type: Magical, Monster: Ahriman (Demon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; absorbs magic damage equal to your Blue Magic skill, 5 minutes; a magic-only Stoneskin (sub type 2), so it is overwritten by Stoneskin as on retail
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)
    local power    = caster:getSkillLevel(xi.skill.BLUE_MAGIC)

    if target:hasStatusEffect(xi.effect.STONESKIN) or
        not target:addStatusEffect(xi.effect.STONESKIN, { power = power, duration = duration, origin = caster, subType = 2 })
    then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.STONESKIN
end

return spellObject
