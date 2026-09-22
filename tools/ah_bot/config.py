"""
Settings for the Auction House bot: the ONE file to edit when tuning it.

Pricing: BaseSell (the item's vendor sell-back price, already in item_basic) times a multiplier.
Most equipment has no BaseSell (it is 0 in the shipped item data - the retail client cannot sell gear
to an NPC), so equipment falls back to its own level times EQUIP_LEVEL_UNIT_PRICE. Anything with
neither a BaseSell nor an equipment level is left alone: never stocked, never bought from a player.
This is a rough approximation of real market value, not a real price feed - there is no way for the
running game server to reach an external site like ffxiah.com. Tune the numbers below by feel.
"""

# What a BaseSell (or, for equipment, a level) point is worth in gil, at multiplier 1.
PRICE_MULTIPLIER = 2

# A stand-in for BaseSell on equipment that has none: level * this, then multiplied like everything else.
# A level 99 piece prices the same as an item with BaseSell 990 (990 * 2 = 1,980 gil).
EQUIP_LEVEL_UNIT_PRICE = 10

# Which Auction House categories get proactively stocked. None means every real category (owner's
# choice: "I want the whole AH to be stocked"). The first attempt at this restricted it to materials
# only, because an unfiltered first draft immediately restocked Mog House furniture at 500,000+ gil
# each - see docs/custom/NOTES.md. That was a pricing surprise, not a bug: BaseSell-based pricing
# applies to every category exactly the same way, furniture included. Set this to a tuple of category
# numbers (see docs/Auction Categories.txt) to narrow it back down again.
RESTOCK_AH_CATEGORIES = None

# How many of an item the bot keeps listed at once. Equipment gets its own, smaller number: unlike a
# material, a weapon or armor piece is not used up by crafting, so keeping 5 identical copies of the
# same piece listed at once would look strange. Both are per item, not per category.
RESTOCK_TARGET_QUANTITY           = 5
RESTOCK_EQUIPMENT_TARGET_QUANTITY = 3

# The bot only restocks a non-equipment item whose BaseSell is at least this (skips near-worthless
# junk so the AH does not fill up with 1-gil clutter). Equipment has its own price floor below instead,
# since most equipment has no BaseSell at all and is priced by level.
RESTOCK_MIN_BASE_SELL = 10

# The bot only restocks equipment at or above this level (skips level 1-a-few starter gear, which is
# usually replaced within an hour anyway and not worth a permanent AH slot).
RESTOCK_MIN_EQUIPMENT_LEVEL = 10

# Buying unwanted gear (and anything else priceable): a listing the bot will buy out once it has sat
# unsold this many hours, and only at or under the bot's own computed price (never the seller's asking
# price - a listing priced above what the bot would pay is left for a real buyer).
BUYOUT_WAIT_HOURS = 1

# The bot's own character (see setup.sql). Must stay below 20,000,000: xi_test deletes every character from there up.
BOT_CHARID = 10000001
BOT_CHARNAME = 'AHBot'

# How many auction_house rows the bot will act on in a single run of each pass, so one run cannot take
# an unbounded amount of time or place an unbounded number of listings.
MAX_RESTOCK_ITEMS_PER_RUN = 200
MAX_BUYOUTS_PER_RUN = 200
