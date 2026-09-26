-----------------------------------
-- Ability: Hover Shot
-- Description: Ranged damage and accuracy rise and enmity falls with each shot taken from a new spot.
-- Obtained: RNG Level 95
-- Recast Time: 00:03:00
-- Duration: 01:00:00
-- Custom (2026-09-25): LSB had no ability row or script (row in modules/custom/sql/job_fixes.sql).
-----------------------------------
---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.ranger.checkHoverShot(player, target, ability)
end

abilityObject.onUseAbility = function(player, target, ability, action)
    return xi.job_utils.ranger.useHoverShot(player, target, ability, action)
end

return abilityObject
