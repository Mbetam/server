-----------------------------------
-- !buff EXP pool top-up.
-- Dedication drains its pool (subPower) by the bonus it pays on each kill. The pool can only be as large as the database column
-- allows (see buff_config.lua), so it is refilled after every kill; that keeps the !buff EXP bonus from running dry.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/experience_points')
local config = require('modules/custom/lua/buff_config')
-----------------------------------

local m = Module:new('buff_pool_topup')

m:addOverride('xi.experiencePoints.calculate', function(member, mob, data)
    local result = super(member, mob, data)

    -- Only touch the Dedication that !buff applied: a real Dedication effect never has this power.
    local dedication = member:getStatusEffect(xi.effect.DEDICATION)
    if dedication ~= nil and dedication:getPower() == config.expPercent then
        dedication:setSubPower(config.expPool)
    end

    return result
end)
