-- Trust-unique moves written 2026-10-04 (estimated numbers, Eric's go-ahead): skillchain properties from BG Wiki's
-- trust page, AoE / self target where the wiki says so. Scripts: scripts/actions/mobskills/<name>.lua.
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 5, `tertiary_sc` = 0, `mob_skill_distance` = 25.0 WHERE `mob_skill_id` = 3286; -- Lock and Load
UPDATE `mob_skills` SET `primary_sc` = 8, `secondary_sc` = 6, `tertiary_sc` = 0, `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3284; -- Shockstorm Edge
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3283; -- Iniquitous Stab
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 10, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3285; -- Choreographed Carnage
UPDATE `mob_skills` SET `primary_sc` = 5, `secondary_sc` = 8, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3295; -- Songbird Swoop
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3292; -- Gyre Strike
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 10, `tertiary_sc` = 0, `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3294; -- Orcsbane
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 7, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3293; -- Stag's Charge
UPDATE `mob_skills` SET `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3291; -- Stag's Call
UPDATE `mob_skills` SET `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3442; -- Sharp Eye
UPDATE `mob_skills` SET `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3440; -- Pocket Sand
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3685; -- Howling Gust
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3169; -- Howling Gust
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 5, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3687; -- Starward Yowl
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 5, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3171; -- Starward Yowl
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3686; -- Righteous Rasp
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3170; -- Righteous Rasp
UPDATE `mob_skills` SET `primary_sc` = 3, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3684; -- Aurous Charge
UPDATE `mob_skills` SET `primary_sc` = 3, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3168; -- Aurous Charge
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0, `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3688; -- Stalking Prey
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3172; -- Stalking Prey

INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_aldo', 1045, 3286), ('TRUST_aldo', 1045, 3284), ('TRUST_aldo', 1045, 3283), ('TRUST_aldo', 1045, 3285),
    ('TRUST_excenmille_s', 1119, 3295), ('TRUST_excenmille_s', 1119, 3292), ('TRUST_excenmille_s', 1119, 3294), ('TRUST_excenmille_s', 1119, 3293),
    ('TRUST_chacharoon', 1078, 3442), ('TRUST_chacharoon', 1078, 3441), ('TRUST_chacharoon', 1078, 3440),
    ('TRUST_darrcuiln', 1106, 3685), ('TRUST_darrcuiln', 1106, 3687), ('TRUST_darrcuiln', 1106, 3686), ('TRUST_darrcuiln', 1106, 3684), ('TRUST_darrcuiln', 1106, 3688);

-- More trust-unique moves (2026-10-04, estimated numbers): skillchain properties from BG Wiki's trust page,
-- AoE / self target where the wiki says so. Scripts: scripts/actions/mobskills/<name>.lua (trust_move_kit).
UPDATE `mob_skills` SET `primary_sc` = 8, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3556; -- Amatsu: Fuga
UPDATE `mob_skills` SET `primary_sc` = 8, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3732; -- Amatsu: Fuga
UPDATE `mob_skills` SET `primary_sc` = 5, `secondary_sc` = 8, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3558; -- Amatsu: Hanadoki
UPDATE `mob_skills` SET `primary_sc` = 5, `secondary_sc` = 8, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3734; -- Amatsu: Hanadoki
UPDATE `mob_skills` SET `primary_sc` = 3, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3559; -- Amatsu: Choun
UPDATE `mob_skills` SET `primary_sc` = 3, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3735; -- Amatsu: Choun
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3560; -- Amatsu: Gachirin
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3736; -- Amatsu: Gachirin
UPDATE `mob_skills` SET `primary_sc` = 7, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3733; -- Amatsu: Kyori
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3737; -- Amatsu: Suien
UPDATE `mob_skills` SET `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3738; -- Rise From Ashes
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 12, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3240; -- Meteoric Impact
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 12, `tertiary_sc` = 0 WHERE `mob_skill_id` = 2091; -- Meteoric Impact
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0, `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0, `mob_skill_distance` = 25.0 WHERE `mob_skill_id` = 3239; -- Typhonic Arrow
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 12, `tertiary_sc` = 0, `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0, `mob_skill_distance` = 25.0 WHERE `mob_skill_id` = 2090; -- Typhonic Arrow
UPDATE `mob_skills` SET `primary_sc` = 5, `secondary_sc` = 8, `tertiary_sc` = 0, `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 8.0 WHERE `mob_skill_id` = 3296; -- Temblor Blade
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 10, `tertiary_sc` = 0, `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3297; -- Cobra Clamp
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 11, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3454; -- Coming Up Roses
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3486; -- Tongue Lash
UPDATE `mob_skills` SET `primary_sc` = 4, `secondary_sc` = 6, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3252; -- Bisection
UPDATE `mob_skills` SET `primary_sc` = 2, `secondary_sc` = 0, `tertiary_sc` = 0, `mob_skill_distance` = 25.0 WHERE `mob_skill_id` = 3254; -- Akimbo Shot
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 10, `tertiary_sc` = 0, `mob_skill_distance` = 25.0 WHERE `mob_skill_id` = 3255; -- Grisly Horizon
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 9, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3503; -- Justicebreaker
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 4, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3633; -- Sinner's Cross
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 4, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3382; -- Sinner's Cross
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3632; -- Frenzied Thrust
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3381; -- Frenzied Thrust
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3634; -- Open Coffin
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3383; -- Open Coffin
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 10, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3636; -- Hemocladis
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 10, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3385; -- Hemocladis
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3617; -- Feast of Arrows
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 1, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3303; -- Feast of Arrows
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 9, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3620; -- Last Laugh
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 9, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3307; -- Last Laugh
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3618; -- Regurgitated Swarm
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3305; -- Regurgitated Swarm
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 7, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3619; -- Setting the Stage
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 7, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3306; -- Setting the Stage
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3666; -- Matriarchal Fiat
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3815; -- Deific Gambol
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 2982; -- Deific Gambol
UPDATE `mob_skills` SET `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3453; -- Guiding Light
UPDATE `mob_skills` SET `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3452; -- Illustrious Aid
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3451; -- Dynastic Gravitas
UPDATE `mob_skills` SET `primary_sc` = 10, `secondary_sc` = 4, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3699; -- Expunge Magic
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 5, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3700; -- Harmonic Displacement
UPDATE `mob_skills` SET `primary_sc` = 9, `secondary_sc` = 3, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3702; -- Darkest Hour
UPDATE `mob_skills` SET `primary_sc` = 12, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3701; -- Sight Unseen
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 11, `tertiary_sc` = 0, `mob_valid_targets` = 1 WHERE `mob_skill_id` = 3705; -- Naakual's Vengeance
UPDATE `mob_skills` SET `primary_sc` = 6, `secondary_sc` = 8, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3647; -- Merciless Strike
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 11, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3645; -- Inexorable Strike
UPDATE `mob_skills` SET `mob_skill_aoe` = 4, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 3644; -- Ruthlessness
UPDATE `mob_skills` SET `primary_sc` = 13, `secondary_sc` = 11, `tertiary_sc` = 0, `mob_skill_aoe` = 1, `mob_skill_aoe_radius` = 10.0 WHERE `mob_skill_id` = 2089; -- Salamander Flame
UPDATE `mob_skills` SET `primary_sc` = 11, `secondary_sc` = 2, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3538; -- Null Blast
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 0, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3264; -- Salvation Scythe
UPDATE `mob_skills` SET `primary_sc` = 14, `secondary_sc` = 9, `tertiary_sc` = 0 WHERE `mob_skill_id` = 3244; -- Sixth Element

-- Weapon skill lists: the trust-unique moves above, added to the trusts that use them
INSERT IGNORE INTO `mob_skill_lists` VALUES
    ('TRUST_iroha', 1112, 3556), ('TRUST_iroha', 1112, 3558), ('TRUST_iroha', 1112, 3559), ('TRUST_iroha', 1112, 3560),
    ('TRUST_iroha_ii', 1133, 3733), ('TRUST_iroha_ii', 1133, 3734), ('TRUST_iroha_ii', 1133, 3737), ('TRUST_iroha_ii', 1133, 3736),
    ('TRUST_zazarg', 1039, 3240), ('TRUST_najelith', 1044, 3239), ('TRUST_klara', 1063, 3296), ('TRUST_romaa_mihgo', 1064, 3297),
    ('TRUST_mayakov', 1081, 3454), ('TRUST_rongelouts', 1088, 3486),
    ('TRUST_luzaf', 1043, 3252), ('TRUST_luzaf', 1043, 3254), ('TRUST_luzaf', 1043, 3255), ('TRUST_naja_uc', 1123, 3503),
    ('TRUST_teodor', 1101, 3632), ('TRUST_teodor', 1101, 3633), ('TRUST_teodor', 1101, 3634), ('TRUST_teodor', 1101, 3635), ('TRUST_teodor', 1101, 3636),
    ('TRUST_balamor', 1098, 3617), ('TRUST_balamor', 1098, 3618), ('TRUST_balamor', 1098, 3619), ('TRUST_balamor', 1098, 3620),
    ('TRUST_rosulatia', 1100, 3662), ('TRUST_rosulatia', 1100, 3663), ('TRUST_rosulatia', 1100, 3666),
    ('TRUST_ygnas', 1113, 3815), ('TRUST_ygnas', 1113, 2979),
    ('TRUST_arciela', 1080, 3453), ('TRUST_arciela', 1080, 3451),
    ('TRUST_arciela_ii', 1132, 3699), ('TRUST_arciela_ii', 1132, 3700), ('TRUST_arciela_ii', 1132, 3701), ('TRUST_arciela_ii', 1132, 3702),
    ('TRUST_arciela_ii', 1132, 3703), ('TRUST_arciela_ii', 1132, 3704),
    ('TRUST_ingrid_ii', 1131, 3647), ('TRUST_ingrid_ii', 1131, 3645), ('TRUST_ingrid_ii', 1131, 3644), ('TRUST_ingrid_ii', 1131, 164),
    ('TRUST_gadalar', 1034, 2089), ('TRUST_robel-akbel', 1092, 3538), ('TRUST_d_shantotto', 1049, 3264),
    ('TRUST_ovjang', 1040, 3244), ('TRUST_ullegore', 1102, 3627);

-- Conditional heals used through gambits (Iroha II Rise From Ashes, Arciela Illustrious Aid, Arciela II Naakual's
-- Vengeance): no TP cost (flag 0x004, as Lilisette II's Rousing Samba), or the gambit waits for TP they don't need.
UPDATE `mob_skills` SET `mob_skill_flag` = `mob_skill_flag` | 4 WHERE `mob_skill_id` IN (3738, 3452, 3705);
