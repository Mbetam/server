-----------------------------------
-- func: ahprice <item name>
-- desc: Shows the reference price the AH bot uses for an item, so you can tell roughly what something is
--       worth without browsing the whole Auction House by hand. Multi-word names work, with or without
--       underscores: !ahprice fire crystal.
--       This is the bot's OWN reference price (see tools/ah_bot/), the same number it lists items at and
--       the most it will pay for one - not a guarantee something is listed right now, and not the retail
--       "Latest Prices" history (which only fills in once real sales happen).
--       For a stackable item this is the price of ONE; a full stack is worth that times the stack size.
-----------------------------------
require('modules/module_utils')
local qol     = require('modules/custom/lua/qol_common')
local pricing = require('modules/custom/lua/ah_pricing')
-----------------------------------

-- 'fire_crystal' -> 'Fire Crystal'
local function prettyName(name)
    local words = {}

    for word in string.gmatch(name, '[^_]+') do
        table.insert(words, string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2))
    end

    return table.concat(words, ' ')
end

-- GetItemIDByName returns 0 for no match, a real item id for exactly one match, or a value just under
-- 65535 (0xFFFF, the special "gil" item id - real items top out around 29,700) for more than one match.
local AMBIGUOUS_ID_FLOOR = 60000

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = 'sssssss',
}

commandObj.onTrigger = function(player, ...)
    local words = {}

    for _, word in ipairs({ ... }) do
        if word ~= nil then
            table.insert(words, word)
        end
    end

    if #words == 0 then
        qol.say(player, 'Try !ahprice <item name>, for example !ahprice fire crystal.')

        return
    end

    local searched = table.concat(words, ' ')
    local id       = GetItemIDByName('%' .. table.concat(words, '_') .. '%')

    if id == 0 then
        qol.say(player, 'No item matches "' .. searched .. '".')

        return
    end

    if id >= AMBIGUOUS_ID_FLOOR then
        qol.say(player, '"' .. searched .. '" matches more than one item. Try a longer or more exact name.')

        return
    end

    local item = GetItemByID(id)
    if item == nil then
        qol.say(player, 'Could not look up an item with that name.')

        return
    end

    local name = prettyName(item:getName())

    if item:getAHCat() == 0 then
        qol.say(player, name .. ' cannot be sold on the Auction House.')

        return
    end

    local isEquipment = item:isType(xi.itemType.ARMOR) or item:isType(xi.itemType.WEAPON)
    local level       = isEquipment and item:getReqLvl() or 0
    local price       = pricing.priceFor(item:getBasePrice(), level)

    if price == nil then
        qol.say(player, name .. ': no reference price (no vendor value, and not equipment).')

        return
    end

    qol.say(player, string.format('%s: about %d gil. That is the AH bot\'s own price - the most it will ever pay for one, and what it lists it at.', name, price))
end

xi.module.registerCommand('ahprice', commandObj)
