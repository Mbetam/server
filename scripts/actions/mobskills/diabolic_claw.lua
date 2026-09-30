-----------------------------------
-- Diabolic Claw
-- Family: Caturae (Omen / Provenance)
-- Description: Single target, 3-hit physical. Magic Def. Down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'physical',
    hits = 3,
    ftp = { 1.5, 1.75, 2 },
    effects =
    {
        { xi.effect.MAGIC_DEF_DOWN, 25, 0, 60 },
    },
})
