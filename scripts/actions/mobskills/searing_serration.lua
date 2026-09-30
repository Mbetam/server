-----------------------------------
-- Searing Serration
-- Family: Gabbrath (Achuka, Tojil)
-- Description: Single target physical. All attributes down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'physical',
    hits = 1,
    ftp = { 3, 3.5, 4 },
    effects =
    {
        { xi.effect.STR_DOWN, 20, 0, 60 },
        { xi.effect.DEX_DOWN, 20, 0, 60 },
        { xi.effect.VIT_DOWN, 20, 0, 60 },
        { xi.effect.AGI_DOWN, 20, 0, 60 },
        { xi.effect.INT_DOWN, 20, 0, 60 },
        { xi.effect.MND_DOWN, 20, 0, 60 },
        { xi.effect.CHR_DOWN, 20, 0, 60 },
    },
})
