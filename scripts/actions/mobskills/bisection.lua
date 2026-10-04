-----------------------------------
-- Bisection
-- Family: Trust (Luzaf)
-- Description: Single target sword attack.
-- Scission/Detonation skillchain properties (BG Wiki trust page)
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
    local damage, landed = kit.physical(mob, target, skill, action, { hits = 1, fTP = { 2.0, 2.5, 3.0 }, damageType = xi.damageType.SLASHING })

    return damage
end

return mobskillObject
