-----------------------------------
-- Stygian Sphere
-- Family: Caturae (Omen / Provenance)
-- Description: Heals about 2000 HP, removes enfeebles, Stoneskin
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'self',
    heal = 2000,
    erase = true,
    buffs =
    {
        { xi.effect.STONESKIN, 1500, 0, 300 },
    },
})
