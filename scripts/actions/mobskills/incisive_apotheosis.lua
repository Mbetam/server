-----------------------------------
-- Incisive Apotheosis
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: Conal wind damage. Weakness, resets enmity (below 25% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 8,
    resetHate = true,
    hpBelow = 25,
    effects =
    {
        { xi.effect.WEAKNESS, 1, 0, 30 },
    },
})
