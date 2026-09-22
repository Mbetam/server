#!/usr/bin/env python3
"""
The Auction House bot: keeps the AH stocked (every category by default - see RESTOCK_AH_CATEGORIES in
config.py to narrow that), and buys out anything a player has listed that nobody bought within
BUYOUT_WAIT_HOURS. See config.py for the tunable numbers and why they are what they are, and
docs/custom/NOTES.md for the design.

Prints what it would do and does NOT touch the database unless run with --apply. Meant to be run
repeatedly (a cron job or a systemd timer - see docs/custom/NOTES.md for the unit files), not as a
long-running daemon: each run does one restock pass and one buyout pass, then exits.

    python3 ah_bot.py            # dry run: prints what it WOULD do
    python3 ah_bot.py --apply    # actually lists / buys items

Only touches items the game itself would let a player list: excludes anything flagged NoAuction
(flags & 64) and anything not assigned to a real Auction House category (aH between 1 and 98; 0 means
"not on the AH" and 99 is the column's unconfigured default, per docs/Auction Categories.txt).
"""

import argparse
import sys
import time

from config import (
    BOT_CHARID,
    BOT_CHARNAME,
    BUYOUT_WAIT_HOURS,
    MAX_BUYOUTS_PER_RUN,
    MAX_RESTOCK_ITEMS_PER_RUN,
    RESTOCK_AH_CATEGORIES,
    RESTOCK_EQUIPMENT_TARGET_QUANTITY,
    RESTOCK_MIN_BASE_SELL,
    RESTOCK_MIN_EQUIPMENT_LEVEL,
    RESTOCK_TARGET_QUANTITY,
)
from pricing import price_for

import db

# flags & 64: ItemFlag::NoAuction (src/map/enums/item_flag.h)
NO_AUCTION_FLAG = 64

# aH between 1 and 98: a real Auction House category. 0 = not on the AH at all; 99 is the column's
# unconfigured default and is not a real category (docs/Auction Categories.txt).
AUCTIONABLE_AH = 'b.aH BETWEEN 1 AND 98'
NOT_NO_AUCTION = f'(b.flags & {NO_AUCTION_FLAG}) = 0'


def restock_candidates(cur):
    """Everything eligible to be proactively stocked: itemid, name, base_sell, equip_level (None for
    non-equipment). A non-equipment item needs a real BaseSell; equipment needs a real level - most
    equipment has no BaseSell at all (see pricing.py). RESTOCK_AH_CATEGORIES, if set, narrows this to
    specific categories; None (the default) means every real category."""
    category_filter = ''
    params           = [RESTOCK_MIN_BASE_SELL, RESTOCK_MIN_EQUIPMENT_LEVEL]

    if RESTOCK_AH_CATEGORIES is not None:
        placeholders    = ', '.join(['%s'] * len(RESTOCK_AH_CATEGORIES))
        category_filter = f'AND b.aH IN ({placeholders})'
        params          = list(RESTOCK_AH_CATEGORIES) + params

    cur.execute(f"""
        SELECT b.itemid, b.name, b.BaseSell, e.level
        FROM item_basic b
        LEFT JOIN item_equipment e ON e.itemid = b.itemid
        WHERE {AUCTIONABLE_AH} AND {NOT_NO_AUCTION}
          {category_filter}
          AND (b.BaseSell >= %s OR e.level >= %s)
        ORDER BY RAND()
    """, params)

    return cur.fetchall()


def current_bot_stock(cur):
    """{itemid: count of the bot's own unsold listings}"""
    cur.execute('SELECT itemid, COUNT(*) FROM auction_house WHERE seller = %s AND sale = 0 GROUP BY itemid', (BOT_CHARID,))

    return dict(cur.fetchall())


def restock(cur, apply_changes):
    candidates = restock_candidates(cur)
    stock      = current_bot_stock(cur)
    listed     = 0
    now        = int(time.time())

    for itemid, name, base_sell, equip_level in candidates:
        if listed >= MAX_RESTOCK_ITEMS_PER_RUN:
            break

        target  = RESTOCK_EQUIPMENT_TARGET_QUANTITY if equip_level else RESTOCK_TARGET_QUANTITY
        have    = stock.get(itemid, 0)
        missing = target - have

        if missing <= 0:
            continue

        price   = price_for(base_sell, equip_level)
        missing = min(missing, MAX_RESTOCK_ITEMS_PER_RUN - listed)

        print(f'restock: {name} (item {itemid}) x{missing} at {price} gil each (had {have})')

        if apply_changes:
            rows = [(itemid, 0, BOT_CHARID, BOT_CHARNAME, now, price) for _ in range(missing)]
            cur.executemany(
                'INSERT INTO auction_house (itemid, stack, seller, seller_name, date, price) VALUES (%s, %s, %s, %s, %s, %s)',
                rows,
            )

        listed += missing

    print(f'restock: {listed} new listing(s){"" if apply_changes else " (dry run, nothing written)"}')

    return listed


def stale_listings(cur):
    """Real players' listings that have sat unsold for at least BUYOUT_WAIT_HOURS, with what the bot
    would need to know to price them: BaseSell, equipment level (if any) and stack size."""
    cutoff = int(time.time()) - BUYOUT_WAIT_HOURS * 3600

    cur.execute(f"""
        SELECT a.id, a.itemid, a.stack, a.price, a.seller, a.seller_name, b.name, b.BaseSell, b.stackSize, e.level
        FROM auction_house a
        JOIN item_basic b ON b.itemid = a.itemid
        LEFT JOIN item_equipment e ON e.itemid = a.itemid
        WHERE a.buyer_name IS NULL AND a.sale = 0
          AND a.seller != %s
          AND a.date <= %s
          AND {AUCTIONABLE_AH} AND {NOT_NO_AUCTION}
    """, (BOT_CHARID, cutoff))

    return cur.fetchall()


def buy_out(cur, apply_changes):
    bought = 0
    spent  = 0
    now    = int(time.time())

    for row_id, itemid, stack, price, seller, seller_name, name, base_sell, stack_size, equip_level in stale_listings(cur):
        if bought >= MAX_BUYOUTS_PER_RUN:
            break

        # A full-stack listing is worth stack_size times a single unit's price; a single-unit listing
        # (equipment always lists this way - gear never stacks) is worth exactly the per-unit price.
        units     = stack_size if stack else 1
        unit_price = price_for(base_sell, equip_level)

        if unit_price is None:
            continue  # nothing the bot has an opinion on

        total_value = unit_price * units

        if price > total_value:
            continue  # the seller is asking more than the bot would pay; leave it for a real buyer

        print(f'buy out: {name} (item {itemid}, row {row_id}) from {seller_name} for {price} gil (worth up to {total_value})')

        if apply_changes:
            cur.execute(
                'UPDATE auction_house SET buyer = %s, buyer_name = %s, sale = %s, sell_date = %s '
                'WHERE id = %s AND buyer_name IS NULL AND sale = 0',
                (BOT_CHARID, BOT_CHARNAME, price, now, row_id),
            )

        bought += 1
        spent  += price

    print(f'buy out: {bought} listing(s), {spent} gil{"" if apply_changes else " (dry run, nothing written)"}')

    return bought, spent


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--apply', action='store_true', help='Actually write to the database. Without this, only prints what would happen.')
    args = parser.parse_args()

    conn = db.connect()
    conn.autocommit = False

    try:
        cur = conn.cursor()

        restock(cur, args.apply)
        buy_out(cur, args.apply)

        if args.apply:
            conn.commit()
        else:
            conn.rollback()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == '__main__':
    sys.exit(main())
