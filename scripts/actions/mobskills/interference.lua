-----------------------------------
-- Interference
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Dispel (below 25% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 6,
    dispel = 1,
    hpBelow = 25,
})
