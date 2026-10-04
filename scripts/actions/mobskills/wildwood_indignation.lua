-----------------------------------
-- Wildwood Indignation
-- Family: Trust (Rosulatia)
-- Description: Earth damage.
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
    local damage, landed = kit.magical(mob, target, skill, action, { element = xi.element.EARTH, fTP = { 2.25, 2.75, 3.25 } })

    return damage
end

return mobskillObject
