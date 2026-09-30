-----------------------------------
-- Volcanic Stasis
-- Family: Gabbrath (Achuka, Tojil)
-- Description: Conal fire damage. Stun, dispels 4
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.FIRE,
    power = 5,
    dispel = 4,
    effects =
    {
        { xi.effect.STUN, 1, 0, 4 },
    },
})
