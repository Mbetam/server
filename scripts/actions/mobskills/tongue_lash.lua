-----------------------------------
-- Tongue Lash
-- Family: Trust (Rongelouts)
-- Description: Area of effect Terror (about 2 s). No damage.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 2))

    return xi.effect.TERROR
end

return mobskillObject
