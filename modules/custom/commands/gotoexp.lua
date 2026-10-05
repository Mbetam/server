-----------------------------------
-- func: gotoexp
-- desc: Shows EXP camps for your level (your party's lowest level in the zone) and teleports you there; the party
--       leader can bring the party. Free, no cooldown (Eric, 2026-10-05). Not usable in battle, in events, or inside
--       battlefields and instances. Logic: modules/custom/lua/gotoexp_core.lua.
-----------------------------------
require('modules/module_utils')
local core = require('modules/custom/lua/gotoexp_core')
-----------------------------------

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

commandObj.onTrigger = function(player)
    core.open(player)
end

xi.module.registerCommand('gotoexp', commandObj)
