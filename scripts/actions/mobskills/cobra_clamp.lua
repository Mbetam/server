-----------------------------------
-- Cobra Clamp
-- Family: Trust (Romaa Mihgo)
-- Description: Conal attack. Additional effect: Stun and Paralyze.
-- Fragmentation/Distortion skillchain properties (BG Wiki trust page)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, Stun 4 s, Paralyze 15% / 60 s are estimates (2026-10-04, Eric's go-ahead).
-----------------------------------
local kit = require('modules/custom/lua/trust_move_kit')
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local damage, landed = kit.physical(mob, target, skill, action, { hits = 1, fTP = { 1.5, 2.0, 2.5 }, damageType = xi.damageType.SLASHING, ignoreShadows = true })
    if landed then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.STUN, 1, 0, 4)
    end
    if landed then
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 15, 0, 60)
    end

    return damage
end

return mobskillObject
