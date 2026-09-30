-----------------------------------
-- Polar Roar
-- Family: Cehuetzi (Kumhau, Utkux)
-- Description: AoE ice damage. Bind (knockback per its row)
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
        { xi.effect.BIND, 1, 0, 20 },
    },
})
