-----------------------------------
-- Zealous Snort
-- Family: Raaz (BST jug pet Ready move)
-- Description: Grants Haste and enhances Magic Defense (and Counter/Guard rate) (BG Wiki).
-- Notes: Counter and Guard are not done. Haste 15% and Magic Defense +25 for 3 min are estimates.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    xi.mobskills.mobBuffMove(mob, xi.effect.MAGIC_DEF_BOOST, 25, 0, 180)
    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.HASTE, 1500, 0, 180))

    return xi.effect.HASTE
end

return mobskillObject
