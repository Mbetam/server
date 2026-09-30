-----------------------------------
-- Tidal Guillotine
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: Conal water damage. Very heavy (retail can KO outright; not here) (below 50% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WATER,
    power = 9,
    hpBelow = 50,
})
