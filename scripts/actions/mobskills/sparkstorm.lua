-----------------------------------
-- Sparkstorm
-- Family: Waktza (Hurkan, Cailimh)
-- Description: Conal thunder damage. Accuracy and Magic Acc. Down, TP loss
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
        { xi.effect.ACCURACY_DOWN, 30, 0, 60 },
        { xi.effect.MAGIC_ACC_DOWN, 30, 0, 60 },
    },
})
