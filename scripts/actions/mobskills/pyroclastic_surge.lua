-----------------------------------
-- Pyroclastic Surge
-- Family: Gabbrath (Achuka, Tojil)
-- Description: AoE fire damage. Addle
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.FIRE,
    power = 4.5,
    effects =
    {
        { xi.effect.ADDLE, 30, 0, 60 },
    },
})
