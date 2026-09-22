"""Pure logic tests for pricing.py. Run with: python3 -m unittest tools/ah_bot/test_pricing.py (from the repo root,
with tools/ah_bot on sys.path - or just `cd tools/ah_bot && python3 -m unittest test_pricing`)."""

import unittest

from pricing import price_for, may_restock, may_buy_out
import config


class PriceForTests(unittest.TestCase):
    def test_uses_base_sell_when_it_has_one(self):
        self.assertEqual(price_for(base_sell=15), 15 * config.PRICE_MULTIPLIER)

    def test_falls_back_to_equipment_level_when_base_sell_is_zero(self):
        self.assertEqual(
            price_for(base_sell=0, equip_level=75),
            75 * config.EQUIP_LEVEL_UNIT_PRICE * config.PRICE_MULTIPLIER,
        )

    def test_base_sell_wins_over_equipment_level_when_both_are_present(self):
        # Equipment with a real BaseSell (rare, but possible) should be priced by that, not by level
        self.assertEqual(price_for(base_sell=1280, equip_level=50), 1280 * config.PRICE_MULTIPLIER)

    def test_none_when_neither_is_available(self):
        self.assertIsNone(price_for(base_sell=0, equip_level=None))
        self.assertIsNone(price_for(base_sell=0, equip_level=0))
        self.assertIsNone(price_for(base_sell=None, equip_level=None))

    def test_a_negative_base_sell_is_not_used(self):
        # BaseSell is unsigned in the database and should never be negative, but if bad data ever got
        # in, it must not produce a negative price - fall through to the equipment level instead
        self.assertEqual(price_for(base_sell=-5, equip_level=75), price_for(base_sell=0, equip_level=75))
        self.assertIsNone(price_for(base_sell=-5, equip_level=None))

    def test_never_returns_zero_or_negative(self):
        for base_sell in (0, 1, 5, 1000):
            for equip_level in (None, 0, 1, 99):
                price = price_for(base_sell, equip_level)
                self.assertTrue(price is None or price > 0, f'base_sell={base_sell} equip_level={equip_level} gave {price}')

    def test_higher_level_equipment_is_worth_more(self):
        low  = price_for(base_sell=0, equip_level=10)
        high = price_for(base_sell=0, equip_level=90)
        self.assertLess(low, high)


class MayRestockTests(unittest.TestCase):
    def test_stocks_a_priced_non_equipment_item(self):
        self.assertTrue(may_restock(base_sell=50, equip_level=None, min_base_sell=10))
        self.assertTrue(may_restock(base_sell=50, equip_level=0, min_base_sell=10))

    def test_never_stocks_equipment(self):
        self.assertFalse(may_restock(base_sell=5000, equip_level=75, min_base_sell=10))

    def test_never_stocks_below_the_minimum(self):
        self.assertFalse(may_restock(base_sell=5, equip_level=None, min_base_sell=10))

    def test_never_stocks_an_item_with_no_base_sell(self):
        self.assertFalse(may_restock(base_sell=0, equip_level=None, min_base_sell=10))
        self.assertFalse(may_restock(base_sell=None, equip_level=None, min_base_sell=10))


class MayBuyOutTests(unittest.TestCase):
    def test_buys_a_listing_priced_at_or_under_its_own_value(self):
        value = price_for(base_sell=100)  # 200 at the default multiplier (x2)
        self.assertTrue(may_buy_out(listed_price=value, base_sell=100, equip_level=None))
        self.assertTrue(may_buy_out(listed_price=value - 1, base_sell=100, equip_level=None))

    def test_never_pays_more_than_its_own_value(self):
        value = price_for(base_sell=100)
        self.assertFalse(may_buy_out(listed_price=value + 1, base_sell=100, equip_level=None))

    def test_never_buys_an_item_it_cannot_price(self):
        self.assertFalse(may_buy_out(listed_price=1, base_sell=0, equip_level=None))

    def test_buys_equipment_using_the_level_fallback(self):
        value = price_for(base_sell=0, equip_level=75)
        self.assertTrue(may_buy_out(listed_price=value, base_sell=0, equip_level=75))
        self.assertFalse(may_buy_out(listed_price=value + 1, base_sell=0, equip_level=75))

if __name__ == '__main__':
    unittest.main()
