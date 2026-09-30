-----------------------------------
-- Afflicting Gaze
-- Family: Caturae (Omen / Provenance)
-- Description: Gaze: strong Plague and Bind
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'none',
    gaze = true,
    effects =
    {
        { xi.effect.PLAGUE, 10, 3, 60 },
        { xi.effect.BIND, 1, 0, 30 },
    },
})
