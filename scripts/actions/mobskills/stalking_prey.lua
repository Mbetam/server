-----------------------------------
-- Stalking Prey
-- Family: Trust (Darrcuiln)
-- Description: Area of effect attack. Additional effect: Terror.
-- Light/Fragmentation skillchain properties (BG Wiki trust page)
-- Notes: BG Wiki lists every number for this skill as unknown (or has no page for it); hits, fTP, Terror 3 s are estimates
--        (2026-10-04, Eric's go-ahead), in line with the trust's other moves.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 1.5, 2.0, 2.5 } -- TODO: Capture fTPs (estimate)
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.HAND_TO_HAND
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 3)
    end

    return info.damage
end

return mobskillObject
