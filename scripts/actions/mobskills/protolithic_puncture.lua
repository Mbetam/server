-----------------------------------
-- Protolithic Puncture
-- Family: Rockfin (Tchakka, Dakuwaqa)
-- Description: Single target water damage. Severe; resets enmity
-- Custom (LSB has the skill row and animation but had no script): built with modules/custom/htbf/mobskill_kit.lua from
-- BG Wiki's description, for the boss arenas.
-----------------------------------
return require('modules/custom/htbf/mobskill_kit').move(
{
    kind = 'magical',
    element = xi.element.WATER,
    power = 8,
    resetHate = true,
})
