-- Moves the AH bot from id 90000001 to 10000001 (accid and charid).
-- Why: xi_test cleans up by deleting every account/character with an id >= 20,000,000 (src/test/test_char.cpp,
-- MinTestCharId), together with their AH listings, so every test run on a server wiped the bot.
-- Why 10000001: the game gives new accounts and characters MAX(id) + 1, so the bot must sit above every real id
-- (new players continue from 10,000,002, a one-time jump in the numbering) and far enough below 20,000,000 to leave room.
-- If 10000001 is already taken by a real account or character, the first UPDATE fails on the duplicate key and
-- migrate.py stops here without changing anything else.

UPDATE accounts SET id = 10000001 WHERE id = 90000001;
UPDATE chars SET charid = 10000001, accid = 10000001 WHERE charid = 90000001;

-- The rows the char_insert trigger (and the game) create per character. No UPDATE triggers on these tables.
UPDATE char_blacklist               SET charid_owner = 10000001 WHERE charid_owner = 90000001;
UPDATE char_blacklist               SET charid_target = 10000001 WHERE charid_target = 90000001;
UPDATE char_chocobos                SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_effects                 SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_equip                   SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_equip_saved             SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_exp                     SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_fishing_contest_history SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_flags                   SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_history                 SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_inventory               SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_jobs                    SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_job_points              SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_look                    SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_merit                   SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_monstrosity             SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_pet                     SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_points                  SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_profile                 SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_recast                  SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_skills                  SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_spells                  SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_stats                   SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_storage                 SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_style                   SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_unlocks                 SET charid = 10000001 WHERE charid = 90000001;
UPDATE char_vars                    SET charid = 10000001 WHERE charid = 90000001;

-- Gil the bot received for its sales, still in its delivery box.
UPDATE delivery_box SET charid = 10000001 WHERE charid = 90000001;
UPDATE delivery_box SET senderid = 10000001 WHERE senderid = 90000001;

-- Only the bot's UNSOLD listings. Sold rows must not be touched: the auction_house_buy trigger fires on any UPDATE of
-- a row with sale != 0 and mails the sale's gil to the seller again. Sold rows stay under 90000001 as plain history
-- (seller_name/buyer_name still read "AHBot").
UPDATE auction_house SET seller = 10000001 WHERE seller = 90000001 AND sale = 0;

-- Where the bot did not exist (never set up, or wiped by xi_test), create it at the new id.
INSERT INTO accounts (id, login, password, current_email, registration_email, timecreate, timelastmodify, content_ids, expansions, features, status, priv)
SELECT 10000001, 'ah_bot_system', SHA2(RAND(), 256), 'noreply@localhost', 'noreply@localhost', NOW(), NOW(), 16, 4094, 253, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE id = 10000001);

INSERT INTO chars (charid, accid, charname, nation, pos_zone, home_zone)
SELECT 10000001, 10000001, 'AHBot', 0, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM chars WHERE charid = 10000001);
