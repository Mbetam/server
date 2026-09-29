-----------------------------------
-- func: shop1
-- desc: Buys a Clear Abyssite (the Voidwalker key item) for 1,000 gil, the same as Assai Nybaem in Ru'Lude Gardens.
--       Not usable in battle, in events, or inside battlefields and instances.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

local PRICE = 1000 -- Assai Nybaem's price (scripts/globals/voidwalker.lua)

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

commandObj.onTrigger = function(player)
    local reason = qol.blockedReason(player)
    if reason then
        qol.say(player, reason)
        return
    end

    if player:hasKeyItem(xi.keyItem.CLEAR_ABYSSITE) then
        qol.say(player, 'You already have a Clear Abyssite.')
        return
    end

    if player:getGil() < PRICE then
        qol.say(player, string.format('A Clear Abyssite costs %d gil.', PRICE))
        return
    end

    player:delGil(PRICE)
    player:addKeyItem(xi.keyItem.CLEAR_ABYSSITE)
    qol.say(player, string.format('You bought a Clear Abyssite for %d gil. Use /heal in a Voidwalker field zone to find the monsters.', PRICE))
end

xi.module.registerCommand('shop1', commandObj)
xi.module.registerCommand('Shop1', commandObj) -- command names are matched exactly as typed; Eric's spelling works too
