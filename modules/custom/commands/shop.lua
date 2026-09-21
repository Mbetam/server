-----------------------------------
-- func: shop
-- desc: Opens a general supplies shop wherever you are. Not usable in battle, in events, or inside battlefields and instances.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

-- What the shop sells: { itemId, price }. Prices match the ones already used by NPC vendors in this repo.
local stock =
{
    { xi.item.POTION,              910 },
    { xi.item.HI_POTION,          4500 },
    { xi.item.ETHER,              4832 },
    { xi.item.HI_ETHER,          28000 },
    { xi.item.REMEDY,             3360 },
    { xi.item.ANTIDOTE,            316 },
    { xi.item.FLASK_OF_ECHO_DROPS, 800 },
    { xi.item.PICKAXE,             200 },
    { xi.item.HATCHET,             500 },
    { xi.item.SICKLE,              300 },
    { xi.item.WOODEN_ARROW,          4 },
    { xi.item.IRON_ARROW,            8 },
    { xi.item.SILVER_ARROW,         17 },
    { xi.item.BULLET,              100 },
    { xi.item.SHURIKEN,             50 },
}

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

    xi.shop.general(player, stock)
end

xi.module.registerCommand('shop', commandObj)
