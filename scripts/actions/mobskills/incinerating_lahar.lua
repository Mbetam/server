-----------------------------------
-- Incinerating Lahar
-- Family: Gabbrath (Achuka, Tojil)
-- Description: AoE fire damage. Weakness (below 50% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.FIRE,
    power = 7,
    hpBelow = 50,
    effects =
    {
        { xi.effect.WEAKNESS, 1, 0, 30 },
    },
})
