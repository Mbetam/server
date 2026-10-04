-- Caster trust fixes (2026-10-04): weapon skill lists that LSB left empty. Retail moves from BG Wiki (BGWiki:Trusts);
-- only moves with a working script are listed (player weapon skills <= 255, or the trust's own mob skill row).
-- The casting AI is in scripts/actions/spells/trust/<name>.lua. INSERT IGNORE: if upstream fills a list, theirs wins.
-- Trust data loads at xi_map start.
INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_D_Shantotto', 1049, 102), -- Guillotine
    ('TRUST_D_Shantotto', 1049, 103), -- Cross Reaper
    ('TRUST_D_Shantotto', 1049, 98),  -- Shadow of Death
    ('TRUST_Gadalar', 1034, 100),     -- Spinning Scythe
    ('TRUST_Gadalar', 1034, 104),     -- Spiral Hell
    ('TRUST_Gadalar', 1034, 101),     -- Vorpal Scythe
    ('TRUST_Leonoyne', 1089, 51),     -- Freezebite
    ('TRUST_Leonoyne', 1089, 58),     -- Herculean Slash
    ('TRUST_Leonoyne', 1089, 52),     -- Shockwave
    ('TRUST_Kayeel-Payeel', 1091, 185), -- Gate of Tartarus
    ('TRUST_Kayeel-Payeel', 1091, 240), -- Tartarus Torpor
    ('TRUST_Kayeel-Payeel', 1091, 180), -- Sunburst
    ('TRUST_Robel-Akbel', 1092, 183), -- Spirit Taker
    ('TRUST_Ullegore', 1102, 3626),   -- Envoutement
    ('TRUST_Ullegore', 1102, 3624),   -- Memento Mori
    ('TRUST_Ullegore', 1102, 3625),   -- Silence Seal
    ('TRUST_Zeid', 1021, 51),         -- Freezebite
    ('TRUST_Zeid', 1021, 56),         -- Ground Strike
    ('TRUST_Zeid', 1021, 3195),       -- Abyssal Drain
    ('TRUST_Zeid', 1021, 3196),       -- Abyssal Strike
    ('TRUST_Ovjang', 1040, 2067),     -- Knockout
    ('TRUST_Ovjang', 1040, 1943),     -- Slapstick
    ('TRUST_King_of_Hearts', 1104, 3689), -- Shuffle
    ('TRUST_King_of_Hearts', 1104, 3690), -- Double Down
    ('TRUST_King_of_Hearts', 1104, 3692), -- Deal Out
    ('TRUST_Pieuje_UC', 1068, 163),   -- Starlight
    ('TRUST_Pieuje_UC', 1068, 164),   -- Moonlight
    ('TRUST_Pieuje_UC', 1068, 3502);  -- Nott
