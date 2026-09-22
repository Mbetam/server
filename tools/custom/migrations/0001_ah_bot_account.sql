-- The AH bot's account and character, at its original id 90000001 ("AHBot"). 0003 moves it to 10000001.
-- Same rows as the original tools/ah_bot/setup.sql, and a no-op where they already exist (setup.sql was run by hand).
-- NOT EXISTS instead of INSERT IGNORE: the chars BEFORE INSERT trigger (char_insert, sql/triggers.sql) fills char_equip,
-- char_exp, ... with plain INSERTs, which fail with a duplicate key even under INSERT IGNORE when the character exists.

INSERT INTO accounts (id, login, password, current_email, registration_email, timecreate, timelastmodify, content_ids, expansions, features, status, priv)
SELECT 90000001, 'ah_bot_system', SHA2(RAND(), 256), 'noreply@localhost', 'noreply@localhost', NOW(), NOW(), 16, 4094, 253, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE id = 90000001);

INSERT INTO chars (charid, accid, charname, nation, pos_zone, home_zone)
SELECT 90000001, 90000001, 'AHBot', 0, 0, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM chars WHERE charid = 90000001);
