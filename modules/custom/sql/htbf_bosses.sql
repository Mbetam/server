-- Boss arenas for Rem's Tales (modules/custom/htbf/): the custom bosses of Tiers 3-5.
-- LSB has no data for the Glassy trio (Reisenjima Henge) or the Omen Caturae (Kin, Gin, Kei, Kyou, Fu, Ou): they are
-- built here from their families' retail pieces (models, NM skill lists, the Caturae skill list 450) and BG Wiki
-- (jobs, spells). Kyou is MNK/WHM (BG Wiki lists WAR, WHM and BLM subjobs; he needs MP for his Protect V, Shell V,
-- Holy, Comet and Meteor). The arena spawns them as dynamic mobs from these mob_groups rows (zone 183, the arena zone).
-- Re-run by dbtool on every update: REPLACE only, ids in custom ranges (pools 20001+, groups 900+ in zone 183,
-- resist ids 900+, spell lists 900+).

-- Resistances: Glassy (Empty, ~60% elemental resist), Caturae (Provenance's ranks)
REPLACE INTO `mob_resistances` VALUES (900,'HTBF_Glassy',0,0,0,0,0,0,0,0,0,0,0,0,0,6,6,6,6,6,6,6,6,4,4,4,4,4,4,4,4,0,4);
REPLACE INTO `mob_resistances` VALUES (901,'HTBF_Caturae',0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,2,4,2,4,0,8,4,4,2,4,4,4,8,8,0,4);

-- Spell lists (BG Wiki's spells for each boss)
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 900;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,219,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,21,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,245,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,247,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,503,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,218,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kin',900,880,1,255);
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 901;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,255,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,163,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,168,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,365,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,192,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Gin',901,197,1,255);
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 902;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,286,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,158,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,187,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,148,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,177,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kei',902,216,1,255);
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 903;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kyou',903,47,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kyou',903,52,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kyou',903,21,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kyou',903,219,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Kyou',903,218,1,255);
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 904;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,58,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,356,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,226,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,173,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,202,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,153,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,182,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Fu',904,360,1,255);
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 905;
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,148,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,153,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,158,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,163,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,168,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,173,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,177,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,182,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,187,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,192,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,197,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,202,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,286,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,260,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,357,1,255);
INSERT INTO `mob_spell_lists` VALUES ('HTBF_Ou',905,252,1,255);

-- Pools and groups
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20001,'Glassy_Craver','Glassy_Craver',281,UNHEX('0000730400000000000000000000000000000000'),1,5,8,240,100,0,1,1,0,2,0,0,0,135,13,0,0,0,0,707,900,3,16);
REPLACE INTO `mob_groups` VALUES (900,20001,183,'Glassy_Craver',0,128,0,20000,0,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20002,'Glassy_Gorger','Glassy_Gorger',283,UNHEX('00006D0400000000000000000000000000000000'),1,5,3,240,100,0,1,1,0,2,0,0,0,135,13,0,0,0,0,138,900,3,16);
REPLACE INTO `mob_groups` VALUES (901,20002,183,'Glassy_Gorger',0,128,0,20000,0,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20003,'Glassy_Thinker','Glassy_Thinker',288,UNHEX('0000680400000000000000000000000000000000'),1,5,7,240,100,0,1,1,0,2,0,0,0,135,13,0,0,0,0,706,900,3,16);
REPLACE INTO `mob_groups` VALUES (902,20003,183,'Glassy_Thinker',0,128,0,20000,0,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20004,'Kin','Kin',58,UNHEX('00000E0800000000000000000000000000000000'),4,1,5,240,100,0,1,1,0,2,0,0,0,415,1,0,900,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (903,20004,183,'Kin',0,128,0,30000,20000,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20005,'Gin','Gin',55,UNHEX('00000D0800000000000000000000000000000000'),6,4,5,240,100,0,1,1,0,2,0,0,0,1439,1,0,901,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (904,20005,183,'Gin',0,128,0,30000,20000,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20006,'Kei','Kei',53,UNHEX('0000360800000000000000000000000000000000'),3,4,12,240,100,0,1,1,0,2,0,0,0,415,0,0,902,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (905,20006,183,'Kei',0,128,0,30000,20000,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20007,'Kyou','Kyou',56,UNHEX('00000F0800000000000000000000000000000000'),2,3,1,240,100,0,1,1,0,2,0,0,0,415,4,0,903,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (906,20007,183,'Kyou',0,128,0,30000,20000,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20008,'Fu','Fu',57,UNHEX('00002D0800000000000000000000000000000000'),1,4,5,240,100,0,1,1,0,2,0,0,0,415,8,0,904,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (907,20008,183,'Fu',0,128,0,30000,20000,0,NULL);
REPLACE INTO `mob_pools` (`poolid`,`name`,`packet_name`,`speciesid`,`modelid`,`mJob`,`sJob`,`cmbSkill`,`cmbDelay`,`cmbDmgMult`,`behavior`,`aggro`,`true_detection`,`links`,`mobType`,`immunity`,`name_prefix`,`flag`,`entityFlags`,`animationsub`,`hasSpellScript`,`spellList`,`namevis`,`roamflag`,`skill_list_id`,`resist_id`,`modelSize`,`modelHitboxSize`) VALUES (20009,'Ou','Ou',54,UNHEX('00002E0800000000000000000000000000000000'),5,1,5,240,100,0,1,1,0,2,0,0,0,415,4,0,905,0,0,450,901,0,0);
REPLACE INTO `mob_groups` VALUES (908,20009,183,'Ou',0,128,0,50000,30000,0,NULL);
