-----------------------------------
-- Vespine Hurricane
-- Family: Bztavian (Colkhab, Muyingwa)
-- Description: Conal wind damage. Magic Def. Down, Attack Down (knockback per its row)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WIND,
    power = 5,
    effects =
    {
        { xi.effect.MAGIC_DEF_DOWN, 25, 0, 60 },
        { xi.effect.ATTACK_DOWN, 25, 0, 60 },
    },
})
