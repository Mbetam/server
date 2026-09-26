-----------------------------------
-- xi.effect.TP_BONUS
-- Custom (2026-09-25): TP Bonus +power (Shiva's Crystal Blessing).
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    effect:addMod(xi.mod.TP_BONUS, effect:getPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
