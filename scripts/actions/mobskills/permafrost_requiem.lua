-----------------------------------
-- Permafrost Requiem
-- Family: Cehuetzi (Kumhau, Utkux)
-- Description: AoE ice damage. Terror
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.ICE,
    power = 4.5,
    effects =
    {
        { xi.effect.TERROR, 1, 0, 6 },
    },
})
