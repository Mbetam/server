-----------------------------------
-- Naakual's Vengeance
-- Family: Trust (Arciela II)
-- Description: Restores her own HP and MP fully.
-- Light/Fusion skillchain properties (BG Wiki trust page)
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
    -- Self-targeted; used at low HP on a 5-minute cooldown (her trust script)
    local hp = mob:getMaxHP() - mob:getHP()

    mob:addHP(hp)
    mob:addMP(mob:getMaxMP() - mob:getMP())
    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return hp
end

return mobskillObject
