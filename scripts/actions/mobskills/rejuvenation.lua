-----------------------------------
-- Rejuvenation
-- Selh'teus: the mission NPC (1509) restores his own HP, MP and TP. The trust (3622, self-targeted since 2026-10-04,
-- modules/custom/sql/trust_melee.sql) restores HP and MP to his party within 20' (BG Wiki: "Restores HP, MP, TP to the
-- entire party"; the party's TP amount is unknown, so only his own TP is restored).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local partyRange = 20

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function restore(member)
    member:addHP(member:getMaxHP() - member:getHP())
    member:addMP(member:getMaxMP() - member:getMP())
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local hp = target:getMaxHP() - target:getHP()

    if mob:isTrust() and mob:getMaster() then
        for _, member in ipairs(mob:getMaster():getPartyWithTrusts()) do
            if member:getID() ~= mob:getID() and member:isAlive() and mob:checkDistance(member) <= partyRange then
                restore(member)
            end
        end
    end

    target:addHP(hp)
    target:addMP(target:getMaxMP() - target:getMP())
    target:addTP(3000 - target:getTP())
    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return hp
end

return mobskillObject
