-----------------------------------
-- Dancer's Fury
-- Family: Humanoid (Trust: Lilisette II, and the Lilisette NPC)
-- Description: Single target dagger attack (made single target for the Alter Ego II version, BG Wiki).
-- Fragmentation/Scission skillchain properties (BG Wiki)
-- Notes: No published numbers; hits and fTP are estimates (2026-09-22).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 3
    params.fTP            = { 1.0, 1.25, 1.5 } -- TODO: Capture fTPs (estimate)
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
