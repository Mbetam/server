-----------------------------------
-- Canopierce
-- Family: Yggdreant (Yumcax, Wopket)
-- Description: AoE earth damage. Rasp
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.EARTH,
    power = 4.5,
    effects =
    {
        { xi.effect.RASP, 10, 3, 60 },
    },
})
