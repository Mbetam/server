-----------------------------------
-- Sharp Eye
-- Family: Trust (Chacharoon)
-- Description: Conal: Gravity and Defense Down. No damage.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown (or has no page for it); hits, fTP, Gravity strength are estimates
--        (2026-10-04, Eric's go-ahead), in line with the trust's other moves.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- BG Wiki: Gravity II (60 s) and Defense Down 25% (30 s); Gravity strength is an estimate
    local result = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.WEIGHT, 50, 0, 60)

    xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 25, 0, 30)
    skill:setMsg(result)

    return xi.effect.WEIGHT
end

return mobskillObject
