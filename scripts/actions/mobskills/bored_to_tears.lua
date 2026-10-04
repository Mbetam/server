-----------------------------------
-- Bored to Tears
-- Family: Trust (Ullegore)
-- Description: Slow (less than Slow II). "The <target> has become noticeably bored."
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, Slow 15% / 90 s are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SLOW, 1500, 0, 90))

    return xi.effect.SLOW
end

return mobskillObject
