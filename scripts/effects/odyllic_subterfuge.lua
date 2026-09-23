-----------------------------------
-- xi.effect.ODYLLIC_SUBTERFUGE
-- power: Magic Accuracy reduction, subPower: Magic Attack Bonus reduction (job points)
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    effect:addMod(xi.mod.MACC, -effect:getPower())

    if effect:getSubPower() > 0 then
        effect:addMod(xi.mod.MATT, -effect:getSubPower())
    end
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
