-----------------------------------
-- Ruthlessness
-- Family: Trust (Ingrid II)
-- Description: Conal dark damage; drains HP.
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
    local damage, landed = kit.magical(mob, target, skill, action, { element = xi.element.DARK, fTP = { 1.75, 2.25, 2.75 }, drain = true })

    return damage
end

return mobskillObject
