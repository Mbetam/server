-- AH bot pricing went from x30 to x2 (tools/ah_bot/config.py PRICE_MULTIPLIER). The bot only prices NEW listings,
-- so its unsold listings would keep the old x30 price. This reprices them with the same formula as
-- tools/ah_bot/pricing.py price_for() at multiplier 2, times the stack size for a full-stack listing, like restock() does.
-- Only the bot's own unsold listings are touched (seller 90000001, sale = 0). Players' listings and sale history are left alone.

UPDATE auction_house a
JOIN item_basic b ON b.itemid = a.itemid
LEFT JOIN item_equipment e ON e.itemid = a.itemid
SET a.price =
    (CASE WHEN b.BaseSell > 0 THEN b.BaseSell * 2 ELSE e.level * 10 * 2 END)
    * (CASE WHEN a.stack = 1 AND b.stackSize > 1 THEN b.stackSize ELSE 1 END)
WHERE a.seller = 90000001
  AND a.sale = 0
  AND (b.BaseSell > 0 OR e.level > 0);
