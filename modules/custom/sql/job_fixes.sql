-- Job fixes that need database rows (2026-09-25). Applied by dbtool through modules/init.txt.
-- INSERT IGNORE: if upstream LSB adds the row, theirs wins.

-- RNG Hover Shot (level 95): LSB had no ability row, so the client never offered it. Id 395 and recast id 151 are the
-- client's own (Windower resources); self target, 3 min recast. Animation borrowed from Velocity Shot. Script:
-- scripts/actions/abilities/hover_shot.lua.
INSERT IGNORE INTO `abilities` VALUES (395,'hover_shot',11,95,1,180,151,0,0,186,2000,0,6,0,0,0,1,300,0,0,'SOA');

-- SCH Animus Augeo, Animus Minuo, Adloquium: LSB ships validTargets = 0 (the only three learnable spells with no valid
-- target), so they could never be cast. BG Wiki: target a party member -> 3 (self | party), as Regen / Phalanx II.
UPDATE `spell_list` SET `validTargets` = 3 WHERE `spellid` IN (308, 309, 495) AND `validTargets` = 0;

-- WHM Asylum and RNG Decoy Shot: LSB flags them as enemy-target (validTarget 4), so they could only be used on a
-- monster and put their buff on it. The client (and BG Wiki) have them as self-target -> 1. Found by comparing every
-- ability's target flags with the client's own data (Windower resources); the other differences are intentional.
UPDATE `abilities` SET `validTarget` = 1 WHERE `abilityId` IN (286, 325) AND `validTarget` = 4;
