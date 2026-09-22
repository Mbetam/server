-- One-time setup for the AH bot: creates its account and character.
-- Run once, by hand: mysql -u mbetam -p mbetam_xi < tools/ah_bot/setup.sql
--
-- charid/accid 90000001 is reserved and must never be reused: real accounts are allocated
-- sequentially from the current MAX(id) (see src/login/auth_session.cpp), which is 1001 today, so this
-- is far out of range. If account creation is ever reopened, new real accounts continue from
-- 90000002 onward - harmless, just a permanent jump in the numbering. See docs/custom/NOTES.md.
--
-- The account's password is a random value nobody knows (openssl rand -hex 32), and its priv/status
-- are 0 (the lowest, same shape as a disabled account) - it is not meant to ever log in, only to own
-- rows in the auction_house and chars tables.

-- login is varchar(16); 'ah_bot_system' (13 chars) fits with room to spare.
INSERT INTO accounts (id, login, password, current_email, registration_email, timecreate, timelastmodify, content_ids, expansions, features, status, priv)
VALUES (90000001, 'ah_bot_system', SHA2(RAND(), 256), 'noreply@localhost', 'noreply@localhost', NOW(), NOW(), 16, 4094, 253, 0, 0);

INSERT INTO chars (charid, accid, charname, nation, pos_zone, home_zone)
VALUES (90000001, 90000001, 'AHBot', 0, 0, 0);
