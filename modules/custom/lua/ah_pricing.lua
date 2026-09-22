-----------------------------------
-- The reference price the !ahprice command shows. Mirrors tools/ah_bot/pricing.py's price_for() exactly,
-- because that Python script is the actual Auction House bot - this command's whole point is to tell a
-- player what the bot itself would think an item is worth. Keep PRICE_MULTIPLIER and EQUIP_LEVEL_UNIT_PRICE
-- here in sync with tools/ah_bot/config.py by hand; Lua and that standalone script share no code.
-- This is a helper file, not a module: it registers nothing and is only loaded when a command module requires it.
-----------------------------------

local pricing = {}

pricing.PRICE_MULTIPLIER        = 30
pricing.EQUIP_LEVEL_UNIT_PRICE  = 10

-- The gil the bot considers this item worth, or nil if it has no opinion (baseSell 0-or-nil and no
-- equipLevel): never stocked, never bought, by the real bot either. equipLevel is nil/0 for non-equipment.
pricing.priceFor = function(baseSell, equipLevel)
    if baseSell ~= nil and baseSell > 0 then
        return math.floor(baseSell * pricing.PRICE_MULTIPLIER + 0.5)
    end

    if equipLevel ~= nil and equipLevel > 0 then
        return math.floor(equipLevel * pricing.EQUIP_LEVEL_UNIT_PRICE * pricing.PRICE_MULTIPLIER + 0.5)
    end

    return nil
end

return pricing
