-----------------------------------
-- Besiegers Bane
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Bio, Zombie, Terror
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 5,
    effects =
    {
        { xi.effect.BIO, 25, 3, 60 },
        { xi.effect.CURSE_II, 1, 0, 30 },
        { xi.effect.TERROR, 1, 0, 5 },
    },
})
