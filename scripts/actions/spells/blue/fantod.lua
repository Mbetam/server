-----------------------------------
-- Spell: Fantod
-- Enhances attack and magic attack for your next attack.
-- Level: 85, Type: Magical, Monster: Hippogryph (Bird)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; each cast stacks: attack +2.7% (Boost, used up by the next attack) and magic attack +2 (3 minutes), up to 10 casts (+27% / +20)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)
    local stacks   = math.min(10, caster:getLocalVar('[Fantod]Stacks') + 1)

    if not caster:hasStatusEffect(xi.effect.BOOST) then
        stacks = 1
    end

    caster:setLocalVar('[Fantod]Stacks', stacks)

    caster:delStatusEffectSilent(xi.effect.BOOST)
    caster:addStatusEffect(xi.effect.BOOST, { power = math.floor(stacks * 2.7), duration = duration, origin = caster })

    caster:delStatusEffectSilent(xi.effect.MAGIC_ATK_BOOST)
    caster:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = stacks * 2, duration = duration, origin = caster })

    return xi.effect.BOOST
end

return spellObject
