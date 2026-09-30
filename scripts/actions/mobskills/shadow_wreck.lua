-----------------------------------
-- Shadow Wreck
-- Family: Caturae (Omen / Provenance)
-- Description: AoE dark damage. Defense Down
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.DARK,
    power = 4.5,
    effects =
    {
        { xi.effect.DEFENSE_DOWN, 25, 0, 60 },
    },
})
