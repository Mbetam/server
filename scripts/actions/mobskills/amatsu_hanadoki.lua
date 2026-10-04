-----------------------------------
-- Amatsu: Hanadoki
-- Family: Trust (Iroha, Iroha II)
-- Description: Magical light damage. Iroha II: chance to Dispel.
-- Reverberation/Impaction skillchain properties (BG Wiki trust page)
-- Notes: BG Wiki lists this trust-unique move's numbers as unknown; fTP, the Dispel chance are estimates (2026-10-04, Eric's go-ahead).
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
    -- Iroha II's version (3734) has a chance to dispel one effect (chance estimated)
    if landed and skill:getID() == 3734 and math.random(100) <= 30 then
        target:dispelStatusEffect()
    end

    return damage
end

return mobskillObject
