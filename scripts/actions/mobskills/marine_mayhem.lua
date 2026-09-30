-----------------------------------
-- Marine Mayhem
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: AoE water damage. Very heavy (retail KOs at range; not here) (below 25% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WATER,
    power = 10,
    hpBelow = 25,
})
