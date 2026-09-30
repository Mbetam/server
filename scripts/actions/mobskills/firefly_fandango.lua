-----------------------------------
-- Firefly Fandango
-- Family: Yggdreant (Yumcax, Wopket)
-- Description: AoE light damage. Paralysis, Flash, Max MP Down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.LIGHT,
    power = 4.5,
    effects =
    {
        { xi.effect.PARALYSIS, 25, 0, 60 },
        { xi.effect.FLASH, 300, 0, 12 },
        { xi.effect.MAX_MP_DOWN, 30, 0, 60 },
    },
})
