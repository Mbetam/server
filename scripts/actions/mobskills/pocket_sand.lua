-----------------------------------
-- Pocket Sand
-- Family: Trust (Chacharoon)
-- Description: Conal dark damage. Additional effect: Blind.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown (or has no page for it); hits, fTP are estimates
--        (2026-10-04, Eric's go-ahead), in line with the trust's other moves.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 1.5, 2.0, 2.5 } -- TODO: Capture fTPs (estimate)
    params.element        = xi.element.DARK
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.DARK
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- BG Wiki: Blind up to -50 accuracy, 60 s
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BLINDNESS, 50, 0, 60)
    end

    return info.damage
end

return mobskillObject
