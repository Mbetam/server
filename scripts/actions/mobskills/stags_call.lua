-----------------------------------
-- Stag's Call
-- Family: Trust (Excenmille [S])
-- Description: Party Haste, Attack and Magic Attack boost.
-- No skillchain properties (BG Wiki)
-- Notes: BG Wiki lists every number for this skill as unknown (or has no page for it); hits, fTP are estimates
--        (2026-10-04, Eric's go-ahead), in line with the trust's other moves.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

-- BG Wiki (trust page): AoE Haste +15%, Attack +15%, MAB +15 for 3 minutes (recast 5 minutes); Haste and Haste II overwrite
-- its Haste. Self-targeted (mob_skills 3291); this gives it to his party within 15'.
local range = 15

local function partyOf(mob)
    local master = mob:isTrust() and mob:getMaster() or nil

    if master then
        return master:getPartyWithTrusts() or {}
    end

    return mob:getParty() or { mob }
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    for _, member in ipairs(partyOf(mob)) do
        if member:isAlive() and mob:checkDistance(member) <= range then
            member:addStatusEffect(xi.effect.HASTE, { power = 1500, duration = 180, origin = mob })
            member:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 15, duration = 180, origin = mob })
            member:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 15, duration = 180, origin = mob })
        end
    end

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)

    return xi.effect.HASTE
end

return mobskillObject
