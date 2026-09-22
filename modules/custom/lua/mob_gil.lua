-----------------------------------
-- Gil floor for mobs: every mob drops at least `baseGil`, however little (or nothing) it dropped before.
-- This is a helper file, not a module: it registers nothing. modules/custom/lua/mob_gil_floor.lua applies it on every kill.
--
-- How the game works (src/map/utils/charutils.cpp DistributeGil, src/map/entities/mob_entity.cpp):
--   * a mob rolls its gil from its GIL_MIN and GIL_MAX mob mods; with both unset the game uses a small level formula, and a mob
--     with neither mod nor GIL_BONUS drops no gil at all;
--   * the server's MOB_GIL_MULTIPLIER is applied to that roll afterwards, so the floor is stored divided by the multiplier;
--   * a negative GIL_MAX is how the game says "never drops gil" (Dynamis, Pirate's Chart, Promyvion and a few story bosses).
--     Every mob drops gil on this server, so a negative maximum is treated as "no gil of its own" and gets the floor too;
--   * a mob with a GIL_BONUS uses the level formula, and the bonus is applied AFTER the minimum (gil = max(formula, min) * bonus / 100),
--     so its minimum is stored divided by the bonus, the same way the floor is divided by the server multiplier.
-----------------------------------

local mobGil = {}

-- The gil every mob should drop at least, as the player receives it (after MOB_GIL_MULTIPLIER, before party splitting).
mobGil.baseGil = 875

-- What to store in the mob's gil mods so that, after the multiplier, the player receives at least `baseGil`.
mobGil.floorFor = function(multiplier)
    if multiplier == nil or multiplier <= 0 then
        multiplier = 1
    end

    return math.ceil(mobGil.baseGil / multiplier)
end

-- The minimum to store on a mob whose gil is multiplied by `bonus` percent afterwards, so that at least `wanted` results.
-- The game does that multiplication with a float, which can land a hair under a whole number and then round down, so when the
-- result would be exact (and the bonus is not the neutral 100) one extra point is added.
mobGil.minForBonus = function(wanted, bonus)
    local needed = math.ceil(wanted * 100 / bonus)

    if bonus ~= 100 and (wanted * 100) % bonus == 0 then
        needed = needed + 1
    end

    return needed
end

-- Raises this mob's gil to the floor. Never lowers a drop, and can safely be called any number of times.
mobGil.apply = function(mob, multiplier)
    local wanted  = mobGil.floorFor(multiplier)
    local low     = mob:getMobMod(xi.mobMod.GIL_MIN)
    local rawHigh = mob:getMobMod(xi.mobMod.GIL_MAX)
    local bonus   = mob:getMobMod(xi.mobMod.GIL_BONUS)

    -- A negative maximum means "never drops gil": here that just means it has none of its own
    local high = math.max(rawHigh, 0)

    if bonus > 0 and high > 0 then
        -- A maximum together with a bonus is a combination the game rolls in a way that a plain floor could lower. Left as it is.
        return
    end

    if bonus > 0 then
        -- No maximum, so the game rolls its level formula, raises it to the minimum, then applies the bonus
        local newLow = math.max(low, mobGil.minForBonus(wanted, bonus))

        if newLow ~= low then
            mob:setMobMod(xi.mobMod.GIL_MIN, newLow)
        end

        if rawHigh < 0 then
            mob:setMobMod(xi.mobMod.GIL_MAX, 0)
        end

        return
    end

    local newLow  = math.max(low, wanted)
    local newHigh = math.max(high, newLow)

    -- The game treats a range narrower than 2 as a mistake and falls back to its own formula, so make it exact instead
    if newHigh - newLow == 1 and newLow ~= low then
        newHigh = newLow
    end

    if newLow ~= low then
        mob:setMobMod(xi.mobMod.GIL_MIN, newLow)
    end

    if newHigh ~= rawHigh then
        mob:setMobMod(xi.mobMod.GIL_MAX, newHigh)
    end
end

return mobGil
