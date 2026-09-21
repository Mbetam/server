-----------------------------------
-- Shared checks for the QoL command modules (!home, !tele, !telelist, !shop).
-- This is a helper file, not a module: it registers nothing and is only loaded when a command module requires it.
-----------------------------------

local qol = {}

-- Why the player cannot use a QoL command right now, or nil when they can.
qol.blockedReason = function(player)
    if player:isDead() then
        return 'You cannot do that while KO\'d.'
    end

    if player:isInEvent() then
        return 'You cannot do that during an event.'
    end

    if player:isEngaged() then
        return 'You cannot do that while engaged in battle.'
    end

    if player:getBattlefield() ~= nil or player:getInstance() ~= nil then
        return 'You cannot do that inside a battlefield or instance.'
    end

    return nil
end

qol.say = function(player, message)
    player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
end

return qol
