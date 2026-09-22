-----------------------------------
-- Camaraderie of the Crevasse
-- Family: Humanoid (Trust: Morimar)
-- Description: Single target great axe attack.
-- Detonation/Impaction skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown; hits and fTP are estimates (2026-09-22).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Not while he glows from Vehement Resolution: his next weapon skill must then be 12 Blades of Remorse
    if mob:getLocalVar('[Morimar]Resolve') == 1 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 2.25, 2.75, 3.25 } -- TODO: Capture fTPs (estimate)
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
