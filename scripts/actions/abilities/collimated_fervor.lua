-----------------------------------
-- Ability: Collimated Fervor
-- Increases the Cardinal Chant effect of your next elemental magic spell (x1.5).
-- Obtained: Geomancer Level 40
-- Recast Time: 00:05:00
-- Duration: 00:01:00
-----------------------------------
---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0, 0
end

abilityObject.onUseAbility = function(player, target, ability, action)
    return xi.job_utils.geomancer.collimatedFervor(player, target, ability)
end

return abilityObject
