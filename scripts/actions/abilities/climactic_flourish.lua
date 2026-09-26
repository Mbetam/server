-----------------------------------
-- Ability: Climactic Flourish
-- Description: Allows you to deal critical hits. Requires at least one finishing move.
-- Obtained: DNC Level 80
-- Recast Time: 00:01:30 (Flourishes III)
-- Duration: 00:01:00
-- Cost: 1-5 Finishing Move charges
-----------------------------------
---@type TAbility
local abilityObject = {}

-- Custom (2026-09-26): rewritten on the FINISHING_MOVE_1 count; see xi.job_utils.dancer.useClimacticFlourishAbility
abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.dancer.checkFlourishAbility(player, target, ability, false, 1)
end

abilityObject.onUseAbility = function(player, target, ability)
    return xi.job_utils.dancer.useClimacticFlourishAbility(player, target, ability)
end

return abilityObject
