-----------------------------------
-- xi.effect.ENDRAIN
-- Custom (2026-09-25): melee hits drain power% of their damage as HP (battleutils::HandleEnspell).
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
