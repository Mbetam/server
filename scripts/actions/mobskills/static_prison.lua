-----------------------------------
-- Static Prison
-- Family: Waktza (Hurkan, Cailimh)
-- Description: AoE thunder damage. Paralysis, Shock, dispels
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.THUNDER,
    power = 5,
    dispel = 2,
    effects =
    {
        { xi.effect.PARALYSIS, 25, 0, 60 },
        { xi.effect.SHOCK, 25, 3, 60 },
    },
})
