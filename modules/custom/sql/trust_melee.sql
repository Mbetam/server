-- Melee trust fixes (2026-10-04): weapon skill lists that LSB left empty, for the trusts that only auto-attacked.
-- Retail moves from BG Wiki (BGWiki:Trusts); only moves with a working script (player weapon skills <= 255, or the
-- trust's own mob skill row). INSERT IGNORE: if upstream fills a list, theirs wins. Loads at xi_map start.
INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_selh_teus', 1094, 3621), -- Luminous Lance
    ('TRUST_selh_teus', 1094, 3623), -- Revelation
    ('TRUST_zazarg', 1039, 7), -- Howling Fist
    ('TRUST_zazarg', 1039, 8), -- Dragon Kick
    ('TRUST_zazarg', 1039, 9), -- Asuran Fists
    ('TRUST_luzaf', 1043, 3253), -- Leaden Salute
    ('TRUST_najelith', 1044, 20), -- Cyclone
    ('TRUST_najelith', 1044, 196), -- Sidewinder
    ('TRUST_najelith', 1044, 199), -- Empyreal Arrow
    ('TRUST_elivira', 1056, 216), -- Coronach
    ('TRUST_elivira', 1056, 212), -- Slug Shot
    ('TRUST_elivira', 1056, 214), -- Heavy Shot
    ('TRUST_elivira', 1056, 209), -- Split Shot
    ('TRUST_noillurie', 1057, 148), -- Tachi: Jinpu
    ('TRUST_noillurie', 1057, 150), -- Tachi: Yukikaze
    ('TRUST_noillurie', 1057, 151), -- Tachi: Gekko
    ('TRUST_noillurie', 1057, 152), -- Tachi: Kasha
    ('TRUST_noillurie', 1057, 153), -- Tachi: Kaiten
    ('TRUST_lhu_mhakaracca', 1058, 68), -- Spinning Axe
    ('TRUST_lhu_mhakaracca', 1058, 69), -- Rampage
    ('TRUST_lhu_mhakaracca', 1058, 73), -- Onslaught
    ('TRUST_lhu_mhakaracca', 1058, 72), -- Decimation
    ('TRUST_klara', 1063, 32), -- Fast Blade
    ('TRUST_klara', 1063, 40), -- Vorpal Blade
    ('TRUST_klara', 1063, 42), -- Savage Blade
    ('TRUST_romaa_mihgo', 1064, 32), -- Fast Blade
    ('TRUST_romaa_mihgo', 1064, 40), -- Vorpal Blade
    ('TRUST_romaa_mihgo', 1064, 42), -- Savage Blade
    ('TRUST_flaviria_uc', 1072, 118), -- Skewer
    ('TRUST_flaviria_uc', 1072, 120), -- Impulse Drive
    ('TRUST_abenzio', 1074, 3358), -- Blank Gaze
    ('TRUST_abenzio', 1074, 3357), -- Antiphase
    ('TRUST_abenzio', 1074, 3356), -- Uppercut
    ('TRUST_abenzio', 1074, 3355), -- Blow
    ('TRUST_babban', 1073, 3351), -- Wild Oats
    ('TRUST_babban', 1073, 3353), -- Petal Pirouette
    ('TRUST_lhe_lhangavo', 1079, 4), -- Backhand Blow
    ('TRUST_lhe_lhangavo', 1079, 5), -- Raging Fists
    ('TRUST_lhe_lhangavo', 1079, 8), -- Dragon Kick
    ('TRUST_lhe_lhangavo', 1079, 9), -- Asuran Fists
    ('TRUST_mayakov', 1081, 32), -- Fast Blade
    ('TRUST_mayakov', 1081, 41), -- Swift Blade
    ('TRUST_mayakov', 1081, 40), -- Vorpal Blade
    ('TRUST_rongelouts', 1088, 34), -- Red Lotus Blade
    ('TRUST_rongelouts', 1088, 42), -- Savage Blade
    ('TRUST_rongelouts', 1088, 37), -- Seraph Blade
    ('TRUST_maximilian', 1090, 32), -- Fast Blade
    ('TRUST_maximilian', 1090, 40), -- Vorpal Blade
    ('TRUST_maximilian', 1090, 41), -- Swift Blade
    ('TRUST_ayame_uc', 1120, 148), -- Tachi: Jinpu
    ('TRUST_ayame_uc', 1120, 149), -- Tachi: Koki
    ('TRUST_ayame_uc', 1120, 152), -- Tachi: Kasha
    ('TRUST_ayame_uc', 1120, 155), -- Tachi: Ageha
    ('TRUST_jakoh_uc', 1071, 23), -- Dancing Edge
    ('TRUST_jakoh_uc', 1071, 25), -- Evisceration
    ('TRUST_naja_uc', 1123, 3215), -- Peacebreaker
    ('TRUST_naja_uc', 1123, 168), -- Hexa Strike
    ('TRUST_naja_uc', 1123, 3502), -- Nott
    ('TRUST_naja_uc', 1123, 169), -- Black Halo
    ('TRUST_i_shield_uc', 1069, 86), -- Raging Rush
    ('TRUST_i_shield_uc', 1069, 88); -- Steel Cyclone
INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_lilisette', 1060, 2445), -- Whirling Edge (AoE)
    ('TRUST_lilisette', 1060, 2444); -- Dancer's Fury
-- Selh'teus's Rejuvenation (trust version): self-targeted; its script restores the party around him
-- (scripts/actions/mobskills/rejuvenation.lua). LSB had it enemy-targeted, which would have healed the monster.
UPDATE `mob_skills` SET `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3622 AND `mob_valid_targets` = 4;
-- Selh'teus: the engine loads a trust's mob hooks from scripts/actions/spells/trust/<mob_pools.name>.lua; his pool name
-- was 'Selhteus' (the script is selh_teus.lua), so his onMobSpawn never ran. The displayed name is packet_name.
UPDATE `mob_pools` SET `name` = 'selh_teus' WHERE `poolid` = 5979 AND `name` = 'Selhteus';
