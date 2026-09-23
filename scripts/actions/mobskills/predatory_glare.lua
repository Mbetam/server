-----------------------------------
-- Predatory Glare
-- Family: Tiger (BST jug pet Ready move)
-- Description: Gaze. Inflicts Stun (BG Wiki).
-- Notes: Stun duration (4 s) is an estimate.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobGazeMove(mob, target, xi.effect.STUN, 1, 0, 4))

    return xi.effect.STUN
end

return mobskillObject
