-----------------------------------
-- Incisive Denouement
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: Single target wind damage. Severe; resets enmity, stat downs (below 50% HP)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 9,
    resetHate = true,
    hpBelow = 50,
    effects =
    {
        { xi.effect.STR_DOWN, 25, 0, 60 },
        { xi.effect.DEX_DOWN, 25, 0, 60 },
        { xi.effect.VIT_DOWN, 25, 0, 60 },
        { xi.effect.AGI_DOWN, 25, 0, 60 },
        { xi.effect.INT_DOWN, 25, 0, 60 },
        { xi.effect.MND_DOWN, 25, 0, 60 },
        { xi.effect.CHR_DOWN, 25, 0, 60 },
    },
})
