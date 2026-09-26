-----------------------------------
-- xi.effect.PHALANX
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    -- Custom: sub power 1 = Blue Magic Barrier Tusk (-15% damage taken, applied after the damage-taken cap)
    if effect:getSubPower() == 1 then
        effect:addMod(xi.mod.UDMGPHYS, -1500)
        effect:addMod(xi.mod.UDMGMAGIC, -1500)
        effect:addMod(xi.mod.UDMGBREATH, -1500)
        effect:addMod(xi.mod.UDMGRANGE, -1500)

        return
    end

    effect:addMod(xi.mod.PHALANX, effect:getPower() + target:getMod(xi.mod.PHALANX_RECEIVED))
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
