-- Trust Matsui-P (2026-10-04): LSB gives him no spell list and no weapon skill list (mob_pools 6003: both 0), so he only
-- auto-attacked. Kit from BG Wiki (BGWiki:Trusts): Utsusemi Ichi / Ni / San, elemental ninjutsu, single-target nukes I,
-- Burn, Migawari / Kakka / Myoshu / Yurin / Aisha: Ichi, Aspir, Stun; Blade weapon skills by level.
-- New list ids: spell list 906 (next to the custom 900-905), skill list 1118 (trust skill lists are spell id + 115).
-- Levels: ninjutsu as NIN (Ichi 15, Ni 40, San 75), black magic as his BLM subjob.
INSERT IGNORE INTO `mob_spell_lists` (`spell_list_name`, `spell_list_id`, `spell_id`, `min_level`, `max_level`) VALUES
    ('TRUST_Matsui-P', 906, 338, 12, 255), -- Utsusemi: Ichi
    ('TRUST_Matsui-P', 906, 339, 37, 255), -- Utsusemi: Ni
    ('TRUST_Matsui-P', 906, 340, 95, 255), -- Utsusemi: San
    ('TRUST_Matsui-P', 906, 320, 15, 255), ('TRUST_Matsui-P', 906, 321, 40, 255), ('TRUST_Matsui-P', 906, 322, 75, 255), -- Katon
    ('TRUST_Matsui-P', 906, 323, 15, 255), ('TRUST_Matsui-P', 906, 324, 40, 255), ('TRUST_Matsui-P', 906, 325, 75, 255), -- Hyoton
    ('TRUST_Matsui-P', 906, 326, 15, 255), ('TRUST_Matsui-P', 906, 327, 40, 255), ('TRUST_Matsui-P', 906, 328, 75, 255), -- Huton
    ('TRUST_Matsui-P', 906, 329, 15, 255), ('TRUST_Matsui-P', 906, 330, 40, 255), ('TRUST_Matsui-P', 906, 331, 75, 255), -- Doton
    ('TRUST_Matsui-P', 906, 332, 15, 255), ('TRUST_Matsui-P', 906, 333, 40, 255), ('TRUST_Matsui-P', 906, 334, 75, 255), -- Raiton
    ('TRUST_Matsui-P', 906, 335, 15, 255), ('TRUST_Matsui-P', 906, 336, 40, 255), ('TRUST_Matsui-P', 906, 337, 75, 255), -- Suiton
    ('TRUST_Matsui-P', 906, 144, 13, 255), ('TRUST_Matsui-P', 906, 149, 17, 255), ('TRUST_Matsui-P', 906, 154, 9, 255),  -- Fire, Blizzard, Aero
    ('TRUST_Matsui-P', 906, 159, 1, 255), ('TRUST_Matsui-P', 906, 164, 21, 255), ('TRUST_Matsui-P', 906, 169, 5, 255),   -- Stone, Thunder, Water
    ('TRUST_Matsui-P', 906, 235, 24, 255), -- Burn
    ('TRUST_Matsui-P', 906, 247, 25, 255), -- Aspir
    ('TRUST_Matsui-P', 906, 252, 45, 255), -- Stun
    ('TRUST_Matsui-P', 906, 510, 88, 255), -- Migawari: Ichi
    ('TRUST_Matsui-P', 906, 509, 95, 255), -- Kakka: Ichi
    ('TRUST_Matsui-P', 906, 507, 85, 255), -- Myoshu: Ichi
    ('TRUST_Matsui-P', 906, 508, 88, 255), -- Yurin: Ichi
    ('TRUST_Matsui-P', 906, 319, 78, 255); -- Aisha: Ichi

INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_Matsui-P', 1118, 128), ('TRUST_Matsui-P', 1118, 129), ('TRUST_Matsui-P', 1118, 133), -- Blade: Rin, Retsu, Ei
    ('TRUST_Matsui-P', 1118, 134), ('TRUST_Matsui-P', 1118, 135), ('TRUST_Matsui-P', 1118, 136), -- Blade: Jin, Ten, Ku
    ('TRUST_Matsui-P', 1118, 138), ('TRUST_Matsui-P', 1118, 140), ('TRUST_Matsui-P', 1118, 141); -- Blade: Kamu, Hi, Shun

UPDATE `mob_pools` SET `spellList` = 906, `skill_list_id` = 1118 WHERE `poolid` = 6003 AND `spellList` = 0 AND `skill_list_id` = 0;
