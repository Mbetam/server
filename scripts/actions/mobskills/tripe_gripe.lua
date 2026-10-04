-----------------------------------
-- Tripe Gripe
-- Family: Trust (Chacharoon)
-- Description: Amnesia, but also an Attack boost, on the target. No damage.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown (or has no page for it); hits, fTP, Attack boost size are estimates
--        (2026-10-04, Eric's go-ahead), in line with the trust's other moves.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- BG Wiki: Amnesia (about 30 s) and an Attack boost on the enemy (Zeid can take it with Absorb-Attri); boost size estimated
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.AMNESIA, 1, 0, 30))
    target:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 10, duration = 30, origin = mob })

    return xi.effect.AMNESIA
end

return mobskillObject
