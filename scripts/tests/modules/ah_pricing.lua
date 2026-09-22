-----------------------------------
-- The !ahprice reference price (modules/custom/lua/ah_pricing.lua). Pure logic, no items or DB; the
-- real command against real items is in ahprice_engine.lua.
-- This must compute exactly the same number as tools/ah_bot/pricing.py's price_for() - the whole point
-- of the command is to tell a player what the real bot would pay/list at.
-----------------------------------
local pricing = require('modules/custom/lua/ah_pricing')
-----------------------------------

describe('!ahprice reference price', function()
    it('uses BaseSell x the multiplier when the item has one', function()
        assert(pricing.priceFor(15, nil) == 15 * pricing.PRICE_MULTIPLIER)
        assert(pricing.priceFor(1280, 0) == 1280 * pricing.PRICE_MULTIPLIER)
    end)

    it('falls back to equip level x the level unit x the multiplier when BaseSell is zero or nil', function()
        assert(pricing.priceFor(0, 75) == 75 * pricing.EQUIP_LEVEL_UNIT_PRICE * pricing.PRICE_MULTIPLIER)
        assert(pricing.priceFor(nil, 75) == 75 * pricing.EQUIP_LEVEL_UNIT_PRICE * pricing.PRICE_MULTIPLIER)
    end)

    it('prefers BaseSell over the equip level when both are present', function()
        assert(pricing.priceFor(1280, 50) == 1280 * pricing.PRICE_MULTIPLIER)
    end)

    it('returns nil when neither is available', function()
        assert(pricing.priceFor(0, nil) == nil)
        assert(pricing.priceFor(0, 0) == nil)
        assert(pricing.priceFor(nil, nil) == nil)
    end)

    it('never returns zero or a negative number', function()
        for _, baseSell in ipairs({ 0, 1, 5, 1000 }) do
            for _, level in ipairs({ nil, 0, 1, 99 }) do
                local price = pricing.priceFor(baseSell, level)
                assert(price == nil or price > 0, string.format('baseSell=%s level=%s gave %s', tostring(baseSell), tostring(level), tostring(price)))
            end
        end
    end)

    it('a negative BaseSell is not used, the same as no BaseSell', function()
        assert(pricing.priceFor(-5, 75) == pricing.priceFor(0, 75))
        assert(pricing.priceFor(-5, nil) == nil)
    end)

    it('matches tools/ah_bot/pricing.py\'s own numbers exactly (the two must never drift apart)', function()
        assert(pricing.PRICE_MULTIPLIER == 30, 'PRICE_MULTIPLIER here must match tools/ah_bot/config.py')
        assert(pricing.EQUIP_LEVEL_UNIT_PRICE == 10, 'EQUIP_LEVEL_UNIT_PRICE here must match tools/ah_bot/config.py')
    end)
end)
