-----------------------------------
-- xi.effect.HOVER_SHOT
-- Custom (2026-09-25): power = stacks (0-25), see xi.job_utils.ranger.useHoverShot. Per stack: ranged damage +4%
-- (TRUE_SHOT_EFFECT, read for ranged attacks and ranged weapon skills), Ranged Accuracy +4, Enmity -2.
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    local stacks = effect:getPower()

    effect:addMod(xi.mod.TRUE_SHOT_EFFECT, 4 * stacks)
    effect:addMod(xi.mod.RACC, 4 * stacks)
    effect:addMod(xi.mod.ENMITY, -2 * stacks)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
