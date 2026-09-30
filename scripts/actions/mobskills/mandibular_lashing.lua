-----------------------------------
-- Mandibular Lashing
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: Single target wind damage. Stun
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 6,
    effects =
    {
        { xi.effect.STUN, 1, 0, 4 },
    },
})
