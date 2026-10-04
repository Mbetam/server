-----------------------------------
-- Rise From Ashes
-- Family: Trust (Iroha II)
-- Description: Party: restores 25% HP, restores MP, Stoneskin 500 HP.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, the MP amount are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- BG Wiki: 25% HP to all party members, restores MP (amount estimated: 25%), 500 HP Stoneskin. Self-targeted.
    for _, member in ipairs(kit.party(mob, 15)) do
        member:addHP(math.floor(member:getMaxHP() * 0.25))
        member:addMP(math.floor(member:getMaxMP() * 0.25))
        member:delStatusEffect(xi.effect.STONESKIN)
        member:addStatusEffect(xi.effect.STONESKIN, { power = 500, duration = 300, origin = mob })
    end

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)

    return xi.effect.STONESKIN
end

return mobskillObject
