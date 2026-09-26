-----------------------------------
-- Spell: Absolute Terror
-- Freezes the target in fear. (Unbridled Learning)
-- Level: 96, Type: Magical, Monster: Wyrm (Dragon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; duration is not published (30 s here, ESTIMATE); NMs often resist
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params           = {}
    params.ecosystem       = xi.ecosystem.DRAGON
    params.effect          = xi.effect.TERROR
    params.power           = 1
    params.tick            = 0
    params.duration        = 30
    params.resistThreshold = 0.50
    params.isGaze          = false
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
