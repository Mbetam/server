-- One-time setup for the AH bot: creates its account and character (accid/charid 10000001, "AHBot").
-- Normally NOT needed by hand: the custom migrations (tools/custom/migrations/0001 + 0003, run by deploy.sh or
-- `tools/custom/migrate.py apply`) create it. Kept for a bare database. Safe to run again: existing rows are left alone.
--
-- Why 10000001: the game gives new accounts and characters MAX(id) + 1 (src/login/auth_session.cpp, login_helpers.cpp),
-- so the bot sits above every real id (new players continue from 10,000,002, a harmless one-time jump), and below
-- 20,000,000, because xi_test deletes every account/character from 20,000,000 up after a test run (src/test/test_char.cpp).
-- It used to be 90000001 and was wiped by every test run; migration 0003 moved it. Never reuse this id by hand.
--
-- The account's password is a random value nobody knows, and its priv/status are 0 (the lowest, same shape as a
-- disabled account) - it is not meant to ever log in, only to own rows in the auction_house and chars tables.
-- NOT EXISTS instead of INSERT IGNORE: the chars insert trigger (char_insert) fails on a duplicate even under IGNORE.

INSERT INTO accounts (id, login, password, current_email, registration_email, timecreate, timelastmodify, content_ids, expansions, features, status, priv)
SELECT 10000001, 'ah_bot_system', SHA2(RAND(), 256), 'noreply@localhost', 'noreply@localhost', NOW(), NOW(), 16, 4094, 253, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE id = 10000001);

INSERT INTO chars (charid, accid, charname, nation, pos_zone, home_zone)
SELECT 10000001, 10000001, 'AHBot', 0, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM chars WHERE charid = 10000001);
