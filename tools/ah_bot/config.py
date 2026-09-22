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
PRICE_MULTIPLIER = 30

# A stand-in for BaseSell on equipment that has none: level * this, then multiplied like everything else.
# A level 99 piece prices the same as an item with BaseSell 990 (990 * 30 = 29,700 gil).
EQUIP_LEVEL_UNIT_PRICE = 10

# Restocking: only items in these Auction House categories are proactively listed (see
# docs/Auction Categories.txt for the full list and what each number means). Chosen to match "keep
# common materials in stock" - crystals, crafting materials, food - and explicitly NOT weapons, armor,
# furnishings or anything else a real player would normally be the one selling. The first attempt at
# this list had no category filter at all and it immediately restocked Mog House furniture at
# 500,000+ gil each - see docs/custom/NOTES.md. Add or remove numbers here to change what gets stocked.
RESTOCK_AH_CATEGORIES = (
    35,  # Crystals
    38, 39, 40, 41, 42, 43, 44, 63,  # Materials: Smithing, Goldsmithing, Clothcraft, Leathercraft, Bonecraft, Woodworking, Alchemy, Alchemy 2
    33,  # Medicines
    51, 52, 53, 54, 55, 56, 57, 58, 59,  # Food: Fish, Meat&Eggs, Seafood, Vegetables, Soups, Breads&Rice, Sweets, Drinks, Ingredients
)

# How many of an item the bot keeps listed at once.
RESTOCK_TARGET_QUANTITY = 5

# The bot only restocks items whose BaseSell is at least this (skips near-worthless junk so the AH
# does not fill up with 1-gil clutter). Equipment is never restocked regardless of this value.
RESTOCK_MIN_BASE_SELL = 10

# Buying unwanted gear (and anything else priceable): a listing the bot will buy out once it has sat
# unsold this many hours, and only at or under the bot's own computed price (never the seller's asking
# price - a listing priced above what the bot would pay is left for a real buyer).
BUYOUT_WAIT_HOURS = 1

# The bot's own character, created once (see setup.sql). Never a real player's ID: see docs/custom/NOTES.md.
BOT_CHARID = 90000001
BOT_CHARNAME = 'AHBot'

# How many auction_house rows the bot will act on in a single run of each pass, so one run cannot take
# an unbounded amount of time or place an unbounded number of listings.
MAX_RESTOCK_ITEMS_PER_RUN = 200
MAX_BUYOUTS_PER_RUN = 200
