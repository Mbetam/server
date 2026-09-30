-----------------------------------
-- Reverse Current
-- Family: Waktza (Hurkan, Cailimh)
-- Description: AoE thunder damage. Stun
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.THUNDER,
    power = 4.5,
    effects =
    {
        { xi.effect.STUN, 1, 0, 4 },
    },
})
