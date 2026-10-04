-----------------------------------
-- Unceasing Dread
-- Family: Trust (Arciela II)
-- Description: Paralyze.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, Paralyze 25% / 60 s are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 25, 0, 60))

    return xi.effect.PARALYSIS
end

return mobskillObject
