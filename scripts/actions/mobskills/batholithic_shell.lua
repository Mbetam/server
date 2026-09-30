-----------------------------------
-- Batholithic Shell
-- Family: Gabbrath (Achuka, Tojil)
-- Description: The user gains Stoneskin and Defense Boost
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'self',
    buffs =
    {
        { xi.effect.STONESKIN, 2000, 0, 300 },
        { xi.effect.DEFENSE_BOOST, 50, 0, 120 },
    },
})
