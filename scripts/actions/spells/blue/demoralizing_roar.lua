-----------------------------------
-- Spell: Demoralizing Roar
-- Lowers the attack of enemies in range.
-- Level: 80, Type: Magical, Monster: Wivre (Beast)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; Attack -20% for 30 s
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = {}
    params.ecosystem       = xi.ecosystem.BEAST
    params.effect          = xi.effect.ATTACK_DOWN
    params.power           = 20
    params.tick            = 0
    params.duration        = 30
    params.resistThreshold = 0.50
    params.isGaze          = false
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
