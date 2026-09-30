-----------------------------------
-- Stygian Cyclone
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Silence
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 4,
    effects =
    {
        { xi.effect.SILENCE, 1, 0, 60 },
    },
})
