-----------------------------------
-- Stinger Volley
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: Conal wind damage. Paralysis, brief Curse
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 5,
    effects =
    {
        { xi.effect.PARALYSIS, 25, 0, 60 },
        { xi.effect.CURSE_I, 50, 0, 10 },
    },
})
