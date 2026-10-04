-----------------------------------
-- Null Blast
-- Family: Trust (Robel-Akbel)
-- Description: Dark damage; restores MP equal to the damage. Magic Evasion Down.
-- Fusion/Compression skillchain properties (BG Wiki trust page)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, Magic Evasion Down 20 / 60 s are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local damage, landed = kit.magical(mob, target, skill, action, { element = xi.element.DARK, fTP = { 2.0, 2.5, 3.0 } })
    if landed and damage > 0 then
        mob:addMP(damage)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_EVASION_DOWN, 20, 0, 60)
    end

    return damage
end

return mobskillObject
