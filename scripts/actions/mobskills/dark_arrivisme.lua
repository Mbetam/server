-----------------------------------
-- Dark Arrivisme
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Dispel, brief Terror (knockback per its row)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 5,
    dispel = 1,
    effects =
    {
        { xi.effect.TERROR, 1, 0, 5 },
    },
})
