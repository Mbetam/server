-----------------------------------
-- Meteoric Impact
-- Family: Trust (Zazarg)
-- Description: Single target hand-to-hand attack.
-- Dark/Fragmentation skillchain properties (BG Wiki trust page)
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
    local damage, landed = kit.physical(mob, target, skill, action, { hits = 1, fTP = { 3.0, 3.5, 4.0 }, damageType = xi.damageType.HAND_TO_HAND })

    return damage
end

return mobskillObject
