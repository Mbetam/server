-----------------------------------
-- Nepenthic Plunge
-- Family: Snapweed (BST jug pet Ready move)
-- Description: Water damage in a cone. Additional effect: Weight and Drown (17/tick) (BG Wiki).
-- Notes: Drown 17/tick is retail (BG Wiki); fTP and Weight strength are estimates.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 3.0, 3.0, 3.0 }
    params.element        = xi.element.WATER
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.WATER
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.WEIGHT, 50, 0, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DROWN, 17, 3, 60)
    end

    return info.damage
end

return mobskillObject
