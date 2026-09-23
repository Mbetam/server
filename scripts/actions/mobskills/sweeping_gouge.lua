-----------------------------------
-- Sweeping Gouge
-- Family: Raaz (BST jug pet Ready move)
-- Description: Two-hit cone attack. Additional effect: Defense Down (~16%, 90 s) (BG Wiki).
-- Notes: Defense Down 16% / 90 s is retail (BG Wiki); fTP is an estimate (the retail 1.0 is the Blue Magic version).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 2
    params.fTP            = { 1.5, 1.75, 2.0 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.BLUNT
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_2

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 16, 0, 90)
    end

    return info.damage
end

return mobskillObject
