-----------------------------------
-- xi.effect.COUNTER_BOOST
-- Custom (2026-09-25): Orcish Counterstance. power = Counter %, subPower = counter damage %.
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    effect:addMod(xi.mod.COUNTER, effect:getPower())
    effect:addMod(xi.mod.COUNTER_DAMAGE, effect:getSubPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
