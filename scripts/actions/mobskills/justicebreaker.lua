-----------------------------------
-- Justicebreaker
-- Family: Trust (Naja Salaheem (UC))
-- Description: Club attack. Defense Down 10% and Magic Defense Down 10% (60 s).
-- Dark/Gravitation skillchain properties (BG Wiki trust page)
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
    local damage, landed = kit.physical(mob, target, skill, action, { hits = 1, fTP = { 2.5, 3.0, 3.5 }, damageType = xi.damageType.BLUNT })
    if landed then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 10, 0, 60)
    end
    if landed then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_DEF_DOWN, 10, 0, 60)
    end

    return damage
end

return mobskillObject
