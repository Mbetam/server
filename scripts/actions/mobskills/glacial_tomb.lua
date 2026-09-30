-----------------------------------
-- Glacial Tomb
-- Family: Cehuetzi (Kumhau, Utkux)
-- Description: AoE ice damage. Encumbrance
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.ICE,
    power = 5,
    effects =
    {
        { xi.effect.ENCUMBRANCE_I, 15, 0, 60 },
    },
})
