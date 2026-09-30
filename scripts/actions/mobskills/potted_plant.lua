-----------------------------------
-- Potted Plant
-- Family: Yggdreant (Yumcax, Wopket)
-- Description: AoE earth damage. Bind, potent Slow
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.EARTH,
    power = 4,
    effects =
    {
        { xi.effect.BIND, 1, 0, 20 },
        { xi.effect.SLOW, 3000, 0, 60 },
    },
})
