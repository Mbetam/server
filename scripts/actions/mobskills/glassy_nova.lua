-----------------------------------
-- Glassy Nova
-- Family: Cehuetzi (Kumhau, Utkux)
-- Description: AoE ice damage. Full dispel, all attributes down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.ICE,
    power = 6,
    dispel = 8,
    effects =
    {
        { xi.effect.STR_DOWN, 30, 0, 60 },
        { xi.effect.DEX_DOWN, 30, 0, 60 },
        { xi.effect.VIT_DOWN, 30, 0, 60 },
        { xi.effect.AGI_DOWN, 30, 0, 60 },
        { xi.effect.INT_DOWN, 30, 0, 60 },
        { xi.effect.MND_DOWN, 30, 0, 60 },
        { xi.effect.CHR_DOWN, 30, 0, 60 },
    },
})
