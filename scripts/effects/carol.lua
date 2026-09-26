-----------------------------------
-- xi.effect.CAROL
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    local subPower   = effect:getSubPower()
    local buff       = 0
    local nullChance = math.floor(subPower / 1000) -- Custom: Carol II nullification chance (enhancing_song.lua)

    subPower = subPower % 1000

    if subPower > xi.element.DARK then -- unpack and apply stat buff if present
        if subPower >= 400 then
            subPower = subPower - 400
            buff     = 4
        elseif subPower >= 300 then
            subPower = subPower - 300
            buff     = 3
        elseif subPower >= 200 then
            subPower = subPower - 200
            buff     = 2
        else
            subPower = subPower - 100
            buff     = 1
        end
    end

    effect:addMod(xi.data.element.getElementalMEVAModifier(subPower), effect:getPower())

    if nullChance > 0 then
        local nullMods =
        {
            [xi.element.FIRE]    = xi.mod.FIRE_NULL,
            [xi.element.ICE]     = xi.mod.ICE_NULL,
            [xi.element.WIND]    = xi.mod.WIND_NULL,
            [xi.element.EARTH]   = xi.mod.EARTH_NULL,
            [xi.element.THUNDER] = xi.mod.LTNG_NULL,
            [xi.element.WATER]   = xi.mod.WATER_NULL,
            [xi.element.LIGHT]   = xi.mod.LIGHT_NULL,
            [xi.element.DARK]    = xi.mod.DARK_NULL,
        }

        effect:addMod(nullMods[subPower], nullChance)
    end

    if subPower == xi.element.FIRE then -- fire add STR
        effect:addMod(xi.mod.STR, buff)
    elseif subPower == xi.element.ICE then -- ice add INT
        effect:addMod(xi.mod.INT, buff)
    elseif subPower == xi.element.WIND then -- wind add AGI
        effect:addMod(xi.mod.AGI, buff)
    elseif subPower == xi.element.EARTH then -- earth add VIT
        effect:addMod(xi.mod.VIT, buff)
    elseif subPower == xi.element.THUNDER then -- thunder add DEX
        effect:addMod(xi.mod.DEX, buff)
    elseif subPower == xi.element.WATER then -- water add MND
        effect:addMod(xi.mod.MND, buff)
    elseif subPower == xi.element.LIGHT then -- light add CHR
        effect:addMod(xi.mod.CHR, buff)
    elseif subPower == xi.element.DARK then -- dark add MP
        effect:addMod(xi.mod.MP, buff * 10)
    end
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
