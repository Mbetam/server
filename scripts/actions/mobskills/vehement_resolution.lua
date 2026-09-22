-----------------------------------
-- Vehement Resolution
-- Family: Humanoid (Trust: Morimar)
-- Description: Consumes his TP, fully restores his HP and removes his debuffs, and makes him glow: his next weapon skill
--              is 12 Blades of Remorse (BG Wiki BGWiki:Trusts). 3 minute cooldown, kept by the gambit in morimar.lua.
-- Notes: The glow is the local var below; 12_blades_of_remorse.lua clears it. No visual glow.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:delStatusEffectsByFlag(xi.effectFlag.WALTZABLE, false)
    mob:delStatusEffectsByFlag(xi.effectFlag.ERASABLE, false)
    mob:setLocalVar('[Morimar]Resolve', 1)

    local params = {}

    params.primaryMessage = xi.msg.basic.SELF_HEAL
    params.baseHeal       = mob:getMaxHP()
    params.fTP =
    {
        { tp = 1000, modifier = 1.0 },
        { tp = 2000, modifier = 1.0 },
        { tp = 3000, modifier = 1.0 },
    }

    return xi.mobskills.mobHealMove(mob, mob, skill, action, params)
end

return mobskillObject
