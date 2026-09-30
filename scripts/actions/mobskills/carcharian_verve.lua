-----------------------------------
-- Carcharian Verve
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: The user gains Attack Boost and Haste (not on BG Wiki; approximated)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'self',
    buffs =
    {
        { xi.effect.ATTACK_BOOST, 50, 0, 90 },
        { xi.effect.HASTE, 2000, 0, 90 },
    },
})
