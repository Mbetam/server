-- Bard trusts (2026-10-04): BG Wiki gives Joachim Valor Minuet I-V, Knight's Minne I-V and Erase, which his spell list
-- (323) lacks; his song logic (scripts/actions/spells/trust/joachim.lua) uses them when other bards cover March and
-- Madrigal. Levels as Ulmia's list (326); Erase as his WHM subjob.
INSERT IGNORE INTO `mob_spell_lists` (`spell_list_name`, `spell_list_id`, `spell_id`, `min_level`, `max_level`) VALUES
    ('TRUST_Joachim', 323, 389, 1, 255), ('TRUST_Joachim', 323, 390, 21, 255), ('TRUST_Joachim', 323, 391, 41, 255),
    ('TRUST_Joachim', 323, 392, 61, 255), ('TRUST_Joachim', 323, 393, 80, 255),  -- Knight's Minne I-V
    ('TRUST_Joachim', 323, 394, 3, 255), ('TRUST_Joachim', 323, 395, 23, 255), ('TRUST_Joachim', 323, 396, 43, 255),
    ('TRUST_Joachim', 323, 397, 63, 255), ('TRUST_Joachim', 323, 398, 87, 255),  -- Valor Minuet I-V
    ('TRUST_Joachim', 323, 143, 64, 255);                                          -- Erase
