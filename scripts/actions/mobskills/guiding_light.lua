-----------------------------------
-- Guiding Light
-- Family: Trust (Arciela)
-- Description: Party within range: Attack, Defense, Magic Attack and Magic Defense up for 30 s.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, the boost sizes are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- BG Wiki: 30 s; boost sizes estimated (+25% attack / defense, +25 magic attack / defense). Self-targeted.
    for _, member in ipairs(kit.party(mob, 15)) do
        member:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 25, duration = 30, origin = mob })
        member:addStatusEffect(xi.effect.DEFENSE_BOOST, { power = 25, duration = 30, origin = mob })
        member:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 25, duration = 30, origin = mob })
        member:addStatusEffect(xi.effect.MAGIC_DEF_BOOST, { power = 25, duration = 30, origin = mob })
    end

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)

    return xi.effect.ATTACK_BOOST
end

return mobskillObject
