# AH bot

Keeps the Auction House stocked with common materials, and buys out unsold player listings (gear
included) after a wait, so selling on the AH always pays even with a small population. See
`docs/custom/NOTES.md` for the design and why it works the way it does.

## One-time setup

```
mysql -u mbetam -p mbetam_xi < tools/ah_bot/setup.sql
```

Creates the bot's account and character (charid 90000001, "AHBot"). Only needs doing once, ever, on
this database.

## Running it

```
source ~/lsb-venv/bin/activate          # for the mariadb Python module
cd tools/ah_bot
python3 ah_bot.py                       # dry run: prints what it would do, changes nothing
python3 ah_bot.py --apply               # actually lists / buys items
```

Safe to run any time, including while players are online: it only ever inserts new listings and marks
existing ones sold, the same as a player using the real Auction House.

## Tuning

Everything adjustable is in `config.py`, with comments on each value. The two that matter most:

- `RESTOCK_AH_CATEGORIES`: which kinds of items get proactively stocked (materials, crystals, food by
  default - not weapons, armor or furnishings). Add or remove category numbers from
  `docs/Auction Categories.txt`.
- `PRICE_MULTIPLIER`: how many gil per BaseSell point (or per equipment-level point) an item is worth.

## Scheduling

This is a one-shot script, not a daemon: run it repeatedly (cron or a systemd timer), not in a loop.
See `docs/custom/NOTES.md` for a starter timer unit.

## Tests

```
cd tools/ah_bot
python3 -m unittest test_pricing
```

Pure logic only (pricing math, no database). The actual database queries in `ah_bot.py` are exercised
by running it with `--apply` for real - there is no offline way to test those.
