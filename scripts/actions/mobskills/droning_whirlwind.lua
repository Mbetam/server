-----------------------------------
-- Droning Whirlwind
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: AoE wind damage. Dispel; the user gains 25 shadows
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 4,
    dispel = 1,
    buffs =
    {
        { xi.effect.BLINK, 25, 0, 300 },
    },
})
