-----------------------------------
-- Ability: Libra
-- Description: Examines the target's enmity level.
-- Obtained: SCH Level 76
-- Recast Time: 00:01:00
-- Custom (2026-09-25): LSB's script was empty. BG Wiki: shows the target's enmity (CE + VE) toward each party member
-- within 30' of the Scholar, as a percentage of the highest; needs a party member on the target's hate list.
-- Shown as system text to those party members (retail has its own display).
-----------------------------------
---@type TAbility
local abilityObject = {}

local function partyEnmity(player, target)
    local rows = {}
    local top  = 0

    for _, member in ipairs(player:getParty()) do
        if member:isAlive() and player:checkDistance(member) <= 30 then
            local enmity = target:getCE(member) + target:getVE(member)

            if enmity > 0 then
                table.insert(rows, { member = member, enmity = enmity })
                top = math.max(top, enmity)
            end
        end
    end

    return rows, top
end

abilityObject.onAbilityCheck = function(player, target, ability)
    if not target:isMob() then
        return xi.msg.basic.CANNOT_ON_THAT_TARG, 0
    end

    local rows = partyEnmity(player, target)

    if #rows == 0 then
        return xi.msg.basic.UNABLE_TO_USE_JA, 0
    end

    return 0, 0
end

abilityObject.onUseAbility = function(player, target, ability)
    local rows, top = partyEnmity(player, target)

    table.sort(rows, function(a, b)
        return a.enmity > b.enmity
    end)

    local lines = { string.format('Libra: %s', target:getName()) }

    for _, row in ipairs(rows) do
        table.insert(lines, string.format('  %s: %d%%', row.member:getName(), math.floor(row.enmity * 100 / top)))
    end

    for _, member in ipairs(player:getParty()) do
        if player:checkDistance(member) <= 30 then
            for _, line in ipairs(lines) do
                member:printToPlayer(line, xi.msg.channel.SYSTEM_3)
            end
        end
    end
end

return abilityObject
