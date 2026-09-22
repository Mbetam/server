"""
Pure pricing logic for the AH bot: no database, no side effects. See config.py for the tunable numbers
and why they are what they are.
"""

from config import PRICE_MULTIPLIER, EQUIP_LEVEL_UNIT_PRICE


def price_for(base_sell, equip_level=None):
    """
    The gil the bot considers this item worth, or None if it has no opinion (never stocked, never
    bought from a player).

    base_sell:   the item's item_basic.BaseSell (0 if it has none).
    equip_level: the item's item_equipment.level, or None for a non-equipment item.
    """
    if base_sell and base_sell > 0:
        return round(base_sell * PRICE_MULTIPLIER)

    if equip_level and equip_level > 0:
        return round(equip_level * EQUIP_LEVEL_UNIT_PRICE * PRICE_MULTIPLIER)

    return None


def may_restock(base_sell, equip_level, min_base_sell):
    """Only non-equipment items with a real BaseSell are proactively stocked; see config.py."""
    return equip_level in (None, 0) and base_sell is not None and base_sell >= min_base_sell


def may_buy_out(listed_price, base_sell, equip_level):
    """
    Whether the bot should buy out a listing at listed_price. False when the item has no computed
    price, or when the seller asked for more than the bot would pay - that listing is left for a real
    buyer instead of being quietly overpaid.
    """
    price = price_for(base_sell, equip_level)

    return price is not None and listed_price <= price
