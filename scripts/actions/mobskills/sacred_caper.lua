-----------------------------------
-- Sacred Caper
-- Family: Trust (Ygnas)
-- Description: Light damage. Additional effect: Rasp.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, Rasp 10 / 60 s are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local damage, landed = kit.magical(mob, target, skill, action, { element = xi.element.LIGHT, fTP = { 2.0, 2.5, 3.0 } })
    if landed then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.RASP, 10, 0, 60)
    end

    return damage
end

return mobskillObject
