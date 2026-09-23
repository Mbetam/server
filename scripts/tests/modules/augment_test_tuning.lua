-----------------------------------
-- Test helper for the augment tests (no tests of its own). Pins the prices and amounts those tests were written
-- against, so retuning modules/custom/lua/augment_config.lua for players never breaks them. The logic under test
-- (tier unlocks, "a bonus two tiers share costs the lower price", removal price per tier, ...) needs fixed numbers,
-- and Triple Attack's {1, 1, 2, 2} is the example of a shared bonus the tests use.
-- The live config is changed in place for the rest of the test run; nothing outside the augment tests reads it.
-----------------------------------

local tuning = {}

local pinnedPrices  = { 10000, 50000, 250000, 1000000 }
local pinnedRemoval = 5000
local pinnedAmounts =
{
    triple_attack = { 1, 1, 2, 2 },
    gear_haste    = { 1, 1, 2, 2 },
    refresh       = { 1, 1, 2, 2 },
    regen         = { 1, 2, 3, 4 },
}

-- Rewrites the given config table (the one augment_core and augmenter_flow share) in place.
tuning.apply = function(config)
    for tier, price in ipairs(pinnedPrices) do
        config.tiers[tier].price = price
    end

    config.removalPricePerTier = pinnedRemoval

    for _, stat in ipairs(config.stats) do
        local amounts = pinnedAmounts[stat.key]
        if amounts then
            for i, amount in ipairs(amounts) do
                stat.amounts[i] = amount
            end
        end
    end
end

return tuning
