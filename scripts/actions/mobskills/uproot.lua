-----------------------------------
-- Uproot
-- Family: Yggdreant (Yumcax, Wopket)
-- Description: AoE light damage. Slow, resets enmity; the user gains Regen
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.LIGHT,
    power = 7,
    resetHate = true,
    effects =
    {
        { xi.effect.SLOW, 2500, 0, 60 },
    },
    buffs =
    {
        { xi.effect.REGEN, 300, 3, 60 },
    },
})
