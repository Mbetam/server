-----------------------------------
-- Rousing Samba
-- Family: Humanoid (Trust: Lilisette II, and the Lilisette NPC)
-- Description: Critical hit rate up. Alter Ego II version (BG Wiki): a samba that costs 350 TP, so she keeps it up easily;
--              ~10% critical hit rate for the party, and about 75% for Lilisette herself.
-- Notes: No status effect for a critical hit rate boost exists, so only her own boost is done: +65 critical hit rate
--        (on top of her base) for as long as she is summoned. The party's +10% is not implemented. Estimate (2026-09-22).
--        mob_skills 3312 has the "no TP cost" flag; this script takes the 350 TP itself.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local tpCost = 350

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getLocalVar('[Lilisette]RousingSamba') == 1 or mob:getTP() < tpCost then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:addTP(-tpCost)

    if mob:getLocalVar('[Lilisette]RousingSamba') == 0 then
        mob:addMod(xi.mod.CRITHITRATE, 65)
        mob:setLocalVar('[Lilisette]RousingSamba', 1)
    end

    skill:setMsg(xi.msg.basic.USES)

    return 0
end

return mobskillObject
