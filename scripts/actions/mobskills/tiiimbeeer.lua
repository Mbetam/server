-----------------------------------
-- Tiiimbeeer
-- Family: Yggdreant (Yumcax, Wopket)
-- Description: AoE earth damage. Doom, Plague, Bind, stat downs
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.EARTH,
    power = 6,
    effects =
    {
        { xi.effect.DOOM, 10, 3, 30 },
        { xi.effect.PLAGUE, 10, 3, 60 },
        { xi.effect.BIND, 1, 0, 20 },
        { xi.effect.STR_DOWN, 20, 0, 60 },
        { xi.effect.DEX_DOWN, 20, 0, 60 },
        { xi.effect.VIT_DOWN, 20, 0, 60 },
        { xi.effect.AGI_DOWN, 20, 0, 60 },
        { xi.effect.INT_DOWN, 20, 0, 60 },
        { xi.effect.MND_DOWN, 20, 0, 60 },
        { xi.effect.CHR_DOWN, 20, 0, 60 },
    },
})
