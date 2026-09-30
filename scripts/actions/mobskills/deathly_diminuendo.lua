-----------------------------------
-- Deathly Diminuendo
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Bio, Curse
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 4,
    effects =
    {
        { xi.effect.BIO, 20, 3, 60 },
        { xi.effect.CURSE_I, 50, 0, 60 },
    },
})
