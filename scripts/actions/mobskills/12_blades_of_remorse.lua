-----------------------------------
-- 12 Blades of Remorse
-- Family: Humanoid (Trust: Morimar)
-- Description: Single target great axe attack, available only after Vehement Resolution.
-- Light/Distortion skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown; hits and fTP are estimates (2026-09-22).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Only available after Vehement Resolution (BG Wiki)
    if mob:getLocalVar('[Morimar]Resolve') ~= 1 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 3.5, 4.0, 4.5 } -- TODO: Capture fTPs (estimate)
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    mob:setLocalVar('[Morimar]Resolve', 0)

    return info.damage
end

return mobskillObject
