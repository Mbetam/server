-----------------------------------
-- Spell: Mortal Ray
-- Inflicts Doom (gaze).
-- Level: 91, Type: Magical, Monster: Taurus (Demon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; very low accuracy (resist threshold raised to 0.75 here, ESTIMATE); Doom counts down over about 60 s
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = {}
    params.ecosystem       = xi.ecosystem.DEMON
    params.effect          = xi.effect.DOOM
    params.power           = 10
    params.tick            = 3
    params.duration        = 30
    params.resistThreshold = 0.75
    params.isGaze          = true
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
