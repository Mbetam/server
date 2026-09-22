-----------------------------------
-- Vivifying Waltz
-- Family: Humanoid (Trust: Lilisette II, and the Lilisette NPC)
-- Description: Restores HP to party members near her. Alter Ego II version (BG Wiki): used when 3 party members are
--              in yellow HP (under 75%), with at least 1000 TP.
-- Notes: The heal amount is an estimate (2026-09-22): 20% of each member's max HP at 1000 TP, 25% at 2000, 30% at 3000.
--        The skill targets herself (mob_skills 3313 is single target); this script heals the others, so nobody is healed twice.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local range      = 10
local hurtHPP    = 75
local neededHurt = 3
local minimumTP  = 1000

-- Her party, trusts included: through her master for a trust, her own party otherwise (the mission NPC)
local function partyOf(mob)
    local master = mob:isTrust() and mob:getMaster() or nil

    if master then
        return master:getPartyWithTrusts() or {}
    end

    return mob:getParty() or {}
end

local function hurtNearby(mob)
    local count = 0

    for _, member in ipairs(partyOf(mob)) do
        if member:isAlive() and member:getHPP() < hurtHPP and mob:checkDistance(member) <= range then
            count = count + 1
        end
    end

    return count
end

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getTP() < minimumTP or hurtNearby(mob) < neededHurt then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local share = 0.20 + 0.05 * math.floor((math.min(skill:getTP(), 3000) - 1000) / 1000)
    local own   = 0

    for _, member in ipairs(partyOf(mob)) do
        if member:isAlive() and mob:checkDistance(member) <= range then
            local amount = math.min(math.floor(member:getMaxHP() * share), member:getMaxHP() - member:getHP())

            member:addHP(amount)

            if member:getID() == mob:getID() then
                own = amount
            end
        end
    end

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return own
end

return mobskillObject
