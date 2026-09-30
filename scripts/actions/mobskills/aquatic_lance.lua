-----------------------------------
-- Aquatic Lance
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: Conal physical. Defense Down, Magic Def. Down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'physical',
    hits = 2,
    ftp = { 2, 2.5, 3 },
    damageType = xi.damageType.PIERCING,
    effects =
    {
        { xi.effect.DEFENSE_DOWN, 25, 0, 60 },
        { xi.effect.MAGIC_DEF_DOWN, 25, 0, 60 },
    },
})
