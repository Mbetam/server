-----------------------------------
-- Brownout
-- Family: Waktza (Hurkan, Cailimh)
-- Description: Conal thunder damage. Blind, Slow
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.THUNDER,
    power = 5,
    effects =
    {
        { xi.effect.BLINDNESS, 30, 0, 60 },
        { xi.effect.SLOW, 2000, 0, 60 },
    },
})
