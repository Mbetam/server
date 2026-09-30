-----------------------------------
-- Blistering Roar
-- Family: Gabbrath (Achuka, Tojil)
-- Description: AoE breath. Terror; the user gains Defense Boost
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'breath',
    element = xi.element.FIRE,
    power = 4,
    effects =
    {
        { xi.effect.TERROR, 1, 0, 6 },
    },
    buffs =
    {
        { xi.effect.DEFENSE_BOOST, 30, 0, 60 },
    },
})
