-----------------------------------
-- Gil floor for mobs: every mob drops at least `baseGil`, however little (or nothing) it dropped before.
-- This is a helper file, not a module: it registers nothing. modules/custom/lua/mob_gil_floor.lua applies it on every kill.
--
-- How the game works (src/map/utils/charutils.cpp DistributeGil, src/map/entities/mob_entity.cpp):
--   * a mob rolls its gil from its GIL_MIN and GIL_MAX mob mods; with both unset the game uses a small level formula, and a mob
--     with neither mod nor GIL_BONUS drops no gil at all;
--   * the server's MOB_GIL_MULTIPLIER is applied to that roll afterwards, so the floor is stored divided by the multiplier;
--   * a negative GIL_MAX is how the game says "never drops gil" (Dynamis, Limbus and the like), so those mobs are left alone.
-----------------------------------

local mobGil = {}

-- The gil every mob should drop at least, as the player receives it (after MOB_GIL_MULTIPLIER, before party splitting).
mobGil.baseGil = 500

-- What to store in the mob's gil mods so that, after the multiplier, the player receives at least `baseGil`.
mobGil.floorFor = function(multiplier)
    if multiplier == nil or multiplier <= 0 then
        multiplier = 1
    end

    return math.ceil(mobGil.baseGil / multiplier)
end

-- Raises this mob's gil to the floor. Never lowers a drop, and can safely be called any number of times.
mobGil.apply = function(mob, multiplier)
    local low  = mob:getMobMod(xi.mobMod.GIL_MIN)
    local high = mob:getMobMod(xi.mobMod.GIL_MAX)

    if high < 0 then
        return
    end

    -- A mob with only a gil bonus uses the game's own level formula plus that bonus. Replacing that with a fixed floor
    -- could lower a special mob's drop, so those are left as they are.
    if low == 0 and high == 0 and mob:getMobMod(xi.mobMod.GIL_BONUS) > 0 then
        return
    end

    local newLow  = math.max(low, mobGil.floorFor(multiplier))
    local newHigh = math.max(high, newLow)

    -- The game treats a range narrower than 2 as a mistake and falls back to its own formula, so make it exact instead
    if newHigh - newLow == 1 and newLow ~= low then
        newHigh = newLow
    end

    if newLow ~= low then
        mob:setMobMod(xi.mobMod.GIL_MIN, newLow)
    end

    if newHigh ~= high then
        mob:setMobMod(xi.mobMod.GIL_MAX, newHigh)
    end
end

return mobGil
