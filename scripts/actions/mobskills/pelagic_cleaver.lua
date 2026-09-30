-----------------------------------
-- Pelagic Cleaver
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: Conal physical. Sleep (not on BG Wiki; approximated)
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'physical',
    hits = 2,
    ftp = { 2, 2.5, 3 },
    effects =
    {
        { xi.effect.SLEEP_I, 1, 0, 20 },
    },
})
