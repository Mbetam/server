-----------------------------------
-- xi.effect.MANA_WALL
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    -- Custom: the damage cut and MP payment are in CBattleEntity::takeDamage (battle_entity.cpp), as on retail
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
