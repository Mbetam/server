-----------------------------------
-- Illustrious Aid
-- Family: Trust (Arciela)
-- Description: Restores HP to party members nearby.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, the heal amount are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Heal amount estimated: 25% of each member's max HP. Self-targeted.
    for _, member in ipairs(kit.party(mob, 15)) do
        member:addHP(math.floor(member:getMaxHP() * 0.25))
    end

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return 0
end

return mobskillObject
