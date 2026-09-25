-----------------------------------
-- Armor set bonuses for the Armor Upgrader's gear (2026-09-25). Adds to LSB's own sets (scripts/globals/gear_sets.lua)
-- without editing that file:
--   extraMembers: pieces LSB's sets are missing (retail counts them): Artifact +4 in the "AF1 119 +2/3" sets (93-115),
--                 Empyrean Reforged +2/+3 in the "109/119 AF3" sets (57-66, 132). Derived from the Upgrader chains.
--   newSets:      sets LSB does not have, for effects the engine already supports (numbers as LSB's older sets for
--                 the same effect). Other jobs' Empyrean effects need engine code first (docs/custom/NOTES.md).
--   mergeInto:    old Empyrean +2 sets folded into their Reforged set (retail counts them as one set).
--   Engine support added for: BLM (magic_state.cpp + damage_spell.lua), GEO (magic_state.cpp), SMN (summoner.lua +
--   the Blood Pact damage hook below), RDM (enhancing_spell.lua, enfeebling_spell.lua), DRK/BST/DRG/PUP (attackutils.cpp),
--   BRD (scripts/effects/ballad.lua; the other songs already use AUGMENT_SONG_STAT).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/gear_sets')
require('scripts/globals/mobskills')
-----------------------------------

-- LSB set id -> item ids to add (raw ids: LSB's item enum has no names for most +3/+4 pieces)
local extraMembers =
{
    [57] =
    {
        23163, -- kasuga_domaru_+2
        23498, -- kasuga_domaru_+3
        23364, -- kasuga_sune-ate_+2
        23699, -- kasuga_sune-ate_+3
        23297, -- kasuga_haidate_+2
        23632, -- kasuga_haidate_+3
        23096, -- kasuga_kabuto_+2
        23431, -- kasuga_kabuto_+3
        23230, -- kasuga_kote_+2
        23565, -- kasuga_kote_+3
    },
    [58] =
    {
        23354, -- bhikku_gaiters_+2
        23689, -- bhikku_gaiters_+3
        23287, -- bhikku_hose_+2
        23622, -- bhikku_hose_+3
        23220, -- bhikku_gloves_+2
        23555, -- bhikku_gloves_+3
        23153, -- bhikku_cyclas_+2
        23488, -- bhikku_cyclas_+3
        23086, -- bhikku_crown_+2
        23421, -- bhikku_crown_+3
    },
    [59] =
    {
        23085, -- boii_mask_+2
        23420, -- boii_mask_+3
        23353, -- boii_calligae_+2
        23688, -- boii_calligae_+3
        23286, -- boii_cuisses_+2
        23621, -- boii_cuisses_+3
        23219, -- boii_mufflers_+2
        23554, -- boii_mufflers_+3
        23152, -- boii_lorica_+2
        23487, -- boii_lorica_+3
    },
    [60] =
    {
        23090, -- skulkers_bonnet_+2
        23425, -- skulkers_bonnet_+3
        23358, -- skulkers_poulaines_+2
        23693, -- skulkers_poulaines_+3
        23291, -- skulkers_culottes_+2
        23626, -- skulkers_culottes_+3
        23224, -- skulkers_armlets_+2
        23559, -- skulkers_armlets_+3
        23157, -- skulkers_vest_+2
        23492, -- skulkers_vest_+3
    },
    [61] =
    {
        23162, -- amini_caban_+2
        23497, -- amini_caban_+3
        23095, -- amini_gapette_+2
        23430, -- amini_gapette_+3
        23363, -- amini_bottillons_+2
        23698, -- amini_bottillons_+3
        23296, -- amini_bragues_+2
        23631, -- amini_bragues_+3
        23229, -- amini_glovelettes_+2
        23564, -- amini_glovelettes_+3
    },
    [62] =
    {
        23158, -- chevaliers_cuirass_+2
        23493, -- chevaliers_cuirass_+3
        23091, -- chevaliers_armet_+2
        23426, -- chevaliers_armet_+3
        23359, -- chevaliers_sabatons_+2
        23694, -- chevaliers_sabatons_+3
        23225, -- chevaliers_gauntlets_+2
        23560, -- chevaliers_gauntlets_+3
        23292, -- chevaliers_cuisses_+2
        23627, -- chevaliers_cuisses_+3
    },
    [63] =
    {
        23164, -- hattori_ningi_+2
        23499, -- hattori_ningi_+3
        23097, -- hattori_zukin_+2
        23432, -- hattori_zukin_+3
        23231, -- hattori_tekko_+2
        23566, -- hattori_tekko_+3
        23298, -- hattori_hakama_+2
        23633, -- hattori_hakama_+3
        23365, -- hattori_kyahan_+2
        23700, -- hattori_kyahan_+3
    },
    [64] =
    {
        23369, -- chasseurs_bottes_+2
        23704, -- chasseurs_bottes_+3
        23101, -- chasseurs_tricorne_+2
        23436, -- chasseurs_tricorne_+3
        23168, -- chasseurs_frac_+2
        23503, -- chasseurs_frac_+3
        23235, -- chasseurs_gants_+2
        23570, -- chasseurs_gants_+3
        23302, -- chasseurs_culottes_+2
        23637, -- chasseurs_culottes_+3
    },
    [65] =
    {
        23305, -- arbatel_pants_+2
        23640, -- arbatel_pants_+3
        23372, -- arbatel_loafers_+2
        23707, -- arbatel_loafers_+3
        23104, -- arbatel_bonnet_+2
        23439, -- arbatel_bonnet_+3
        23171, -- arbatel_gown_+2
        23506, -- arbatel_gown_+3
        23238, -- arbatel_bracers_+2
        23573, -- arbatel_bracers_+3
    },
    [66] =
    {
        23288, -- ebers_pantaloons_+2
        23623, -- ebers_pantaloons_+3
        23355, -- ebers_duckbills_+2
        23690, -- ebers_duckbills_+3
        23087, -- ebers_cap_+2
        23422, -- ebers_cap_+3
        23154, -- ebers_bliaut_+2
        23489, -- ebers_bliaut_+3
        23221, -- ebers_mitts_+2
        23556, -- ebers_mitts_+3
    },
    [93] =
    {
        24075, -- pummelers_calligae_+4
        24030, -- pummelers_cuisses_+4
        23985, -- pummelers_mufflers_+4
        23940, -- pummelers_lorica_+4
        23895, -- pummelers_mask_+4
    },
    [94] =
    {
        24076, -- anchorites_gaiters_+4
        24031, -- anchorites_hose_+4
        23986, -- anchorites_gloves_+4
        23941, -- anchorites_cyclas_+4
        23896, -- anchorites_crown_+4
    },
    [95] =
    {
        24077, -- theophany_duckbills_+4
        24032, -- theophany_pantaloons_+4
        23987, -- theophany_mitts_+4
        23942, -- theophany_bliaut_+4
        23897, -- theophany_cap_+4
    },
    [96] =
    {
        24078, -- spaekonas_sabots_+4
        24033, -- spaekonas_tonban_+4
        23988, -- spaekonas_gloves
        23943, -- spaekonas_coat_+4
        23898, -- spaekonas_petasos_+4
    },
    [97] =
    {
        24079, -- atrophy_boots_+4
        24034, -- atrophy_tights_+4
        23989, -- atrophy_gloves_+4
        23944, -- atrophy_tabard_+4
        23899, -- atrophy_chapeau_+4
    },
    [98] =
    {
        24080, -- pillagers_poulaines_+4
        24035, -- pillagers_culottes_+4
        23990, -- pillagers_armlets_+4
        23945, -- pillagers_vest_+4
        23900, -- pillagers_bonnet_+4
    },
    [99] =
    {
        24081, -- reverence_leggings_+4
        24036, -- reverence_breeches_+4
        23991, -- reverence_gauntlets_+4
        23946, -- reverence_surcoat_+4
        23901, -- reverence_coronet_+4
    },
    [100] =
    {
        24082, -- ignominy_sollerets_+4
        24037, -- ignominy_flanchard_+4
        23992, -- ignominy_finger_gauntlets_+4
        23947, -- ignominy_cuirass_+4
        23902, -- ignominy_burgeonet_+4
    },
    [101] =
    {
        24083, -- totemic_gaiters_+4
        24038, -- totemic_trousers_+4
        23993, -- totemic_gloves_+4
        23948, -- totemic_jackcoat_+4
        23903, -- totemic_helm_+4
    },
    [102] =
    {
        24084, -- brioso_slippers_+4
        24039, -- brioso_cannions_+4
        23994, -- brioso_cuffs_+4
        23949, -- brioso_justaucorps_+4
        23904, -- brioso_roundlet_+4
    },
    [103] =
    {
        24085, -- orion_socks_+4
        24040, -- orion_braccae_+4
        23995, -- orion_bracers_+4
        23950, -- orion_jerkin_+4
        23905, -- orion_beret_+4
    },
    [104] =
    {
        24086, -- wakido_sune-ate_+4
        24041, -- wakido_haidate_+4
        23996, -- wakido_kote_+4
        23951, -- wakido_domaru_+4
        23906, -- wakido_kabuto_+4
    },
    [105] =
    {
        24087, -- hachiya_kyahan_+4
        24042, -- hachiya_hakama_+4
        23997, -- hachiya_tekko_+4
        23952, -- hachiya_chainmail_+4
        23907, -- hachiya_hatsuburi_+4
    },
    [106] =
    {
        24088, -- vishap_greaves_+4
        24043, -- vishap_brais_+4
        23998, -- vishap_finger_gauntlets_+4
        23953, -- vishap_mail_+4
        23908, -- vishap_armet_+4
    },
    [107] =
    {
        24089, -- convokers_pigaches_+4
        24044, -- convokers_spats_+4
        23999, -- convokers_bracers_+4
        23954, -- convokers_doublet_+4
        23909, -- convokers_horn_+4
    },
    [108] =
    {
        24090, -- assimilators_charuqs_+4
        24045, -- assimilators_shalwar_+4
        24000, -- assimilators_bazubands_+4
        23955, -- assimilators_jubbah_+4
        23910, -- assimilators_keffiyeh_+4
    },
    [109] =
    {
        24091, -- laksamana_bottes_+4
        24046, -- laksamanas_trews_+4
        24001, -- laksamanas_gants_+4
        23956, -- laksamana_frac_+4
        23911, -- laksamana_tricorne_+4
    },
    [110] =
    {
        24092, -- foire_babouches_+4
        24047, -- foire_churidars_+4
        24002, -- foire_dastanas_+4
        23957, -- foire_tobe_+4
        23912, -- foire_taj_+4
    },
    [111] =
    {
        23913, -- maxixi_tiara_+4
        23958, -- maxixi_casaque_+4
        24003, -- maxixi_bangles_+4
        24048, -- maxixi_tights_+4
        24093, -- maxixi_toe_shoes_+4
    },
    [112] =
    {
        23914, -- maxixi_tiara_+4
        23959, -- maxixi_casaque_+4
        24004, -- maxixi_bangles_+4
        24049, -- maxixi_tights_+4
        24094, -- maxixi_toe_shoes_+4
    },
    [113] =
    {
        24095, -- academics_loafers_+4
        24050, -- academics_pants_+4
        24005, -- academics_bracers_+4
        23960, -- academics_gown_+4
        23915, -- academics_mortarboard_+4
    },
    [114] =
    {
        24096, -- geomancy_sandals_+4
        24051, -- geomancy_pants_+4
        24006, -- geomancy_mitaines_+4
        23961, -- geomancy_tunic_+4
        23916, -- geomancy_galero_+4
    },
    [115] =
    {
        24097, -- runeist_boots_+4
        24052, -- runeist_trousers_+4
        24007, -- runeist_mitons_+4
        23962, -- runeist_coat_+4
        23917, -- runeist_bandeau_+4
    },
    [132] =
    {
        11079, -- mavi_kavuk_+2 (old Empyrean +2: LSB has no Mavi set; retail counts it with Hashishin)
        11099, -- mavi_mintan_+2
        11119, -- mavi_bazubands_+2
        11139, -- mavi_tayt_+2
        11159, -- mavi_basmak_+2
        23100, -- hashishin_kavuk_+2
        23435, -- hashishin_kavuk_+3
        23167, -- hashishin_mintan_+2
        23502, -- hashishin_mintan_+3
        23234, -- hashishin_bazubands_+2
        23569, -- hashishin_bazubands_+3
        23301, -- hashishin_tayt_+2
        23636, -- hashishin_tayt_+3
        23368, -- hashishin_basmak_+2
        23703, -- hashishin_basmak_+3
    },
}

for setId, items in pairs(extraMembers) do
    for _, itemId in ipairs(items) do
        xi.gear_sets.itemToSetId[itemId] = xi.gear_sets.itemToSetId[itemId] or {}
        table.insert(xi.gear_sets.itemToSetId[itemId], setId)
    end
end

-- Retail counts the old Empyrean +2 pieces and every Reforged tier toward ONE set. LSB has them as two sets with the
-- same mod, so 2 old + 2 Reforged pieces gave two 2-piece bonuses instead of one 4-piece bonus. Old +2 set -> the set
-- its pieces now count toward (LSB's Reforged set, or one of the new sets below).
local mergeInto =
{
    [26] = 59,   -- WAR Ravager's +2 -> Boii
    [33] = 64,   -- COR Navarch's +2 -> Chasseur's
    [34] = 1001, -- DNC Charis +2 -> Maculele
    [35] = 63,   -- NIN Iga +2 -> Hattori
    [36] = 61,   -- RNG Sylvan +2 -> Amini
    [37] = 62,   -- PLD Creed +2 -> Chevalier's
    [38] = 57,   -- SAM Unkai +2 -> Kasuga
    [39] = 58,   -- MNK Tantra +2 -> Bhikku
    [40] = 60,   -- THF Raider's +2 -> Skulker's
    [41] = 66,   -- WHM Orison +2 -> Ebers
    [42] = 65,   -- SCH Savant's +2 -> Arbatel
}

local movedToNewSets = {} -- item id -> new set id, applied once newSets exists

for itemId, setIds in pairs(xi.gear_sets.itemToSetId) do
    for i = #setIds, 1, -1 do
        local target = mergeInto[setIds[i]]

        if target and target < 1000 then
            setIds[i] = target
        elseif target then
            table.remove(setIds, i)
            movedToNewSets[itemId] = target
        end
    end
end

-- New sets (ids from 1001 so they never collide with LSB's). mods: { mod, value at minEquipped, +1 piece, ... }
local newSets =
{
    [1001] = -- DNC Maculele Attire (Empyrean Reforged, all tiers): Augments "Samba", as LSB's Charis +2 set (34)
    {
        items =
        {
            26776, -- maculele_tiara
            26777, -- maculele_tiara_+1
            23103, -- maculele_tiara_+2
            23438, -- maculele_tiara_+3
            26934, -- maculele_casaque
            26935, -- maculele_casaque_+1
            23170, -- maculele_casaque_+2
            23505, -- maculele_casaque_+3
            27088, -- maculele_bangles
            27089, -- maculele_bangles_+1
            23237, -- maculele_bangles_+2
            23572, -- maculele_bangles_+3
            27273, -- maculele_tights
            27274, -- maculele_tights_+1
            23304, -- maculele_tights_+2
            23639, -- maculele_tights_+3
            27447, -- maculele_toe_shoes
            27448, -- maculele_toe_shoes_+1
            23371, -- maculele_toe_shoes_+2
            23706, -- maculele_toe_shoes_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.SAMBA_DOUBLE_DAMAGE, 2, 3, 4, 5 } },
    },
    [1002] = -- RUN Erilaz Armor (Empyrean Reforged, all tiers): Occasionally absorbs damage taken, as LSB's PLD sets (37, 62)
    {
        items =
        {
            26782, -- erilaz_galea
            26783, -- erilaz_galea_+1
            23106, -- erilaz_galea_+2
            23441, -- erilaz_galea_+3
            26940, -- erilaz_surcoat
            26941, -- erilaz_surcoat_+1
            23173, -- erilaz_surcoat_+2
            23508, -- erilaz_surcoat_+3
            27094, -- erilaz_gauntlets
            27095, -- erilaz_gauntlets_+1
            23240, -- erilaz_gauntlets_+2
            23575, -- erilaz_gauntlets_+3
            27279, -- erilaz_leg_guards
            27280, -- erilaz_leg_guards_+1
            23307, -- erilaz_leg_guards_+2
            23642, -- erilaz_leg_guards_+3
            27453, -- erilaz_greaves
            27454, -- erilaz_greaves_+1
            23374, -- erilaz_greaves_+2
            23709, -- erilaz_greaves_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.ABSORB_DMG_CHANCE, 2, 3, 4, 5 } },
    },
    [1003] = -- BLM Goetia +2 / Wicce (all tiers): Augments "Conserve MP" (spell damage x (1 + 2 x MP conserved)); BG: +5% per piece
    {
        items =
        {
            11067, -- goetia_petasos_+2
            26746, -- wicce_petasos
            26747, -- wicce_petasos_+1
            23088, -- wicce_petasos_+2
            23423, -- wicce_petasos_+3
            11087, -- goetia_coat_+2
            26904, -- wicce_coat
            26905, -- wicce_coat_+1
            23155, -- wicce_coat_+2
            23490, -- wicce_coat_+3
            11107, -- goetia_gloves_+2
            27058, -- wicce_gloves
            27059, -- wicce_gloves_+1
            23222, -- wicce_gloves_+2
            23557, -- wicce_gloves_+3
            11127, -- goetia_chausses_+2
            27243, -- wicce_chausses
            27244, -- wicce_chausses_+1
            23289, -- wicce_chausses_+2
            23624, -- wicce_chausses_+3
            11147, -- goetia_sabots_+2
            27417, -- wicce_sabots
            27418, -- wicce_sabots_+1
            23356, -- wicce_sabots_+2
            23691, -- wicce_sabots_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.AUGMENT_CONSERVE_MP, 10, 15, 20, 25 } },
    },
    [1004] = -- GEO Azimuth (all tiers): MP occasionally not depleted when using geomancy spells
    {
        items =
        {
            26780, -- azimuth_hood
            26781, -- azimuth_hood_+1
            23105, -- azimuth_hood_+2
            23440, -- azimuth_hood_+3
            26938, -- azimuth_coat
            26939, -- azimuth_coat_+1
            23172, -- azimuth_coat_+2
            23507, -- azimuth_coat_+3
            27092, -- azimuth_gloves
            27093, -- azimuth_gloves_+1
            23239, -- azimuth_gloves_+2
            23574, -- azimuth_gloves_+3
            27277, -- azimuth_tights
            27278, -- azimuth_tights_+1
            23306, -- azimuth_tights_+2
            23641, -- azimuth_tights_+3
            27451, -- azimuth_gaiters
            27452, -- azimuth_gaiters_+1
            23373, -- azimuth_gaiters_+2
            23708, -- azimuth_gaiters_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.GEOMANCY_MP_NO_DEPLETE, 2, 3, 4, 5 } },
    },
    [1005] = -- SMN Caller's +2 / Beckoner's (all tiers): Augments "Blood Boon" (Rage pact damage x (1 + MP saved))
    {
        items =
        {
            11078, -- callers_horn_+2
            26768, -- beckoners_horn
            26769, -- beckoners_horn_+1
            23099, -- beckoners_horn_+2
            23434, -- beckoners_horn_+3
            11098, -- callers_doublet_+2
            26926, -- beckoners_doublet
            26927, -- beckoners_doublet_+1
            23166, -- beckoners_doublet_+2
            23501, -- beckoners_doublet_+3
            11118, -- callers_bracers_+2
            27080, -- beckoners_bracers
            27081, -- beckoners_bracers_+1
            23233, -- beckoners_bracers_+2
            23568, -- beckoners_bracers_+3
            11138, -- callers_spats_+2
            27265, -- beckoners_spats
            27266, -- beckoners_spats_+1
            23300, -- beckoners_spats_+2
            23635, -- beckoners_spats_+3
            11158, -- callers_pigaches_+2
            27439, -- beckoners_pigaches
            27440, -- beckoners_pigaches_+1
            23367, -- beckoners_pigaches_+2
            23702, -- beckoners_pigaches_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.AUGMENT_BLOOD_BOON, 2, 3, 4, 5 } },
    },
    [1006] = -- RDM Estoqueur's +2 / Lethargy (all tiers): Augments "Composure" (while Composure is up: enhancing magic on
             -- others and enfeebling magic last +10/20/35/50%; enhancing_spell.lua / enfeebling_spell.lua)
    {
        items =
        {
            11068, -- estoqueurs_chappel_+2
            26748, -- lethargy_chappel
            26749, -- lethargy_chappel_+1
            23089, -- lethargy_chappel_+2
            23424, -- lethargy_chappel_+3
            11088, -- estoqueurs_sayon_+2
            26906, -- lethargy_sayon
            26907, -- lethargy_sayon_+1
            23156, -- lethargy_sayon_+2
            23491, -- lethargy_sayon_+3
            11108, -- estoqueurs_gantherots_+2
            27060, -- lethargy_gantherots
            27061, -- lethargy_gantherots_+1
            23223, -- lethargy_gantherots_+2
            23558, -- lethargy_gantherots_+3
            11128, -- estoqueurs_fuseau_+2
            27245, -- lethargy_fuseau
            27246, -- lethargy_fuseau_+1
            23290, -- lethargy_fuseau_+2
            23625, -- lethargy_fuseau_+3
            11148, -- estoqueurs_houseaux_+2
            27419, -- lethargy_houseaux
            27420, -- lethargy_houseaux_+1
            23357, -- lethargy_houseaux_+2
            23692, -- lethargy_houseaux_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.AUGMENT_COMPOSURE, 10, 20, 35, 50 } },
    },
    [1007] = -- BRD Aoidos' +2 / Fili (all tiers): Augments songs (recipients gain a stat by the song's element; LSB's song
             -- code already passes AUGMENT_SONG_STAT to every song effect). BG: +1 stat per piece from 2 pieces
    {
        items =
        {
            11073, -- aoidos_calot_+2
            26758, -- fili_calot
            26759, -- fili_calot_+1
            23094, -- fili_calot_+2
            23429, -- fili_calot_+3
            11093, -- aoidos_hongreline_+2
            26916, -- fili_hongreline
            26917, -- fili_hongreline_+1
            23161, -- fili_hongreline_+2
            23496, -- fili_hongreline_+3
            11113, -- aoidos_manchettes_+2
            27070, -- fili_manchettes
            27071, -- fili_manchettes_+1
            23228, -- fili_manchettes_+2
            23563, -- fili_manchettes_+3
            11133, -- aoidos_rhingrave_+2
            27255, -- fili_rhingrave
            27256, -- fili_rhingrave_+1
            23295, -- fili_rhingrave_+2
            23630, -- fili_rhingrave_+3
            11153, -- aoidos_cothurnes_+2
            27429, -- fili_cothurnes
            27430, -- fili_cothurnes_+1
            23362, -- fili_cothurnes_+2
            23697, -- fili_cothurnes_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.AUGMENT_SONG_STAT, 1, 2, 3, 4 } },
    },
    [1008] = -- DRK Bale +2 / Heathen's (all tiers): Attack occ. varies with HP (attackutils.cpp: % chance per hit, damage x (1 + HP%); pet sets boost the pet's own hits)
    {
        items =
        {
            11071, -- bale_burgeonet_+2
            26754, -- heathens_burgeonet
            26755, -- heathens_burgeonet_+1
            23092, -- heathens_burgeonet_+2
            23427, -- heathens_burgeonet_+3
            11091, -- bale_cuirass_+2
            26912, -- heathens_cuirass
            26913, -- heathens_cuirass_+1
            23159, -- heathens_cuirass_+2
            23494, -- heathens_cuirass_+3
            11111, -- bale_gauntlets_+2
            27066, -- heathens_gauntlets
            27067, -- heathens_gauntlets_+1
            23226, -- heathens_gauntlets_+2
            23561, -- heathens_gauntlets_+3
            11131, -- bale_flanchard_+2
            27251, -- heathens_flanchard
            27252, -- heathens_flanchard_+1
            23293, -- heathens_flanchard_+2
            23628, -- heathens_flanchards_+3
            11151, -- bale_sollerets_+2
            27425, -- heathens_sollerets
            27426, -- heathens_sollerets_+1
            23360, -- heathens_sollerets_+2
            23695, -- heathens_sollerets_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.ATT_VARIES_WITH_HP, 2, 3, 4, 5 } },
    },
    [1009] = -- BST Ferine +2 / Nukumi (all tiers): Attack occ. varies with pet's HP (attackutils.cpp: % chance per hit, damage x (1 + HP%); pet sets boost the pet's own hits)
    {
        items =
        {
            11072, -- ferine_cabasset_+2
            26756, -- nukumi_cabasset
            26757, -- nukumi_cabasset_+1
            23093, -- nukumi_cabasset_+2
            23428, -- nukumi_cabasset_+3
            11092, -- ferine_gausape_+2
            26914, -- nukumi_gausape
            26915, -- nukumi_gausape_+1
            23160, -- nukumi_gausape_+2
            23495, -- nukumi_gausape_+3
            11112, -- ferine_manoplas_+2
            27068, -- nukumi_manoplas
            27069, -- nukumi_manoplas_+1
            23227, -- nukumi_manoplas_+2
            23562, -- nukumi_manoplas_+3
            11132, -- ferine_quijotes_+2
            27253, -- nukumi_quijotes
            27254, -- nukumi_quijotes_+1
            23294, -- nukumi_quijotes_+2
            23629, -- nukumi_quijotes_+3
            11152, -- ferine_ocreae_+2
            27427, -- nukumi_ocreae
            27428, -- nukumi_ocreae_+1
            23361, -- nukumi_ocreae_+2
            23696, -- nukumi_ocreae_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.ATT_VARIES_WITH_PET_HP, 2, 3, 4, 5 } },
    },
    [1010] = -- DRG Lancer's +2 / Peltast's (all tiers): Attack occ. varies with wyvern's HP (attackutils.cpp: % chance per hit, damage x (1 + HP%); pet sets boost the pet's own hits)
    {
        items =
        {
            11077, -- lancers_mezail_+2
            26766, -- peltasts_mezail
            26767, -- peltasts_mezail_+1
            23098, -- peltasts_mezail_+2
            23433, -- peltasts_mezail_+3
            11097, -- lancers_plackart_+2
            26924, -- peltasts_plackart
            26925, -- peltasts_plackart_+1
            23165, -- peltasts_plackart_+2
            23500, -- peltasts_plackart_+3
            11117, -- lancers_vambraces_+2
            27078, -- peltasts_vambraces
            27079, -- peltasts_vambraces_+1
            23232, -- peltasts_vambraces_+2
            23567, -- peltasts_vambraces_+3
            11137, -- lancers_cuissots_+2
            27263, -- peltasts_cuissots
            27264, -- peltasts_cuissots_+1
            23299, -- peltasts_cuissots_+2
            23634, -- peltasts_cuissots_+3
            11157, -- lancers_schynbalds_+2
            27437, -- peltasts_schynbalds
            27438, -- peltasts_schynbalds_+1
            23366, -- peltasts_schynbalds_+2
            23701, -- peltasts_schynbalds_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.ATT_VARIES_WITH_PET_HP, 2, 3, 4, 5 } },
    },
    [1011] = -- PUP Cirque +2 / Karagoz (all tiers): Attack occ. varies with automaton's HP (attackutils.cpp: % chance per hit, damage x (1 + HP%); pet sets boost the pet's own hits)
    {
        items =
        {
            11081, -- cirque_cappello_+2
            26774, -- karagoz_cappello
            26775, -- karagoz_cappello_+1
            23102, -- karagoz_cappello_+2
            23437, -- karagoz_cappello_+3
            11101, -- cirque_farsetto_+2
            26932, -- karagoz_farsetto
            26933, -- karagoz_farsetto_+1
            23169, -- karagoz_farsetto_+2
            23504, -- karagoz_farsetto_+3
            11121, -- cirque_guanti_+2
            27086, -- karagoz_guanti
            27087, -- karagoz_guanti_+1
            23236, -- karagoz_guanti_+2
            23571, -- karagoz_guanti_+3
            11141, -- cirque_pantaloni_+2
            27271, -- karagoz_pantaloni
            27272, -- karagoz_pantaloni_+1
            23303, -- karagoz_pantaloni_+2
            23638, -- karagoz_pantaloni_+3
            11161, -- cirque_scarpe_+2
            27445, -- karagoz_scarpe
            27446, -- karagoz_scarpe_+1
            23370, -- karagoz_scarpe_+2
            23705, -- karagoz_scarpe_+3
        },
        minEquipped = 2,
        mods = { { xi.mod.ATT_VARIES_WITH_PET_HP, 2, 3, 4, 5 } },
    },
}

for itemId, setId in pairs(movedToNewSets) do
    table.insert(newSets[setId].items, itemId)
end

local newSetOf = {}

for setId, set in pairs(newSets) do
    for _, itemId in ipairs(set.items) do
        newSetOf[itemId] = setId
    end
end

local m = Module:new('armor_sets')

-- LSB's check first (it clears and re-applies its own sets), then ours the same way
m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)

    local level  = player:getMainLvl()
    local counts = {}

    for slot = 0, xi.MAX_SLOTID do
        local item = player:getEquippedItem(slot)
        local setId = item and newSetOf[item:getID()]

        if setId and level >= item:getReqLvl() then
            counts[setId] = (counts[setId] or 0) + 1
        end
    end

    for setId, count in pairs(counts) do
        local set = newSets[setId]

        if count >= set.minEquipped then
            local tier = math.min(count, set.maxEquipped or 99) - set.minEquipped

            for _, modData in ipairs(set.mods) do
                player:addGearSetMod(setId, modData[1], modData[math.min(tier + 2, #modData)])
            end
        end
    end
end)

-- SMN Caller's / Beckoner's set "Augments Blood Boon": when Blood Boon and the set proc, the pact's damage rises by the
-- share of MP saved (BG Wiki). summoner.lua stores that share on the summoner for the current pact.
m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    local master = actor and actor:isPet() and actor:getMaster()

    if master and master:isPC() and info and info.damage and info.damage > 0 then
        local permille = master:getLocalVar('[BloodBoon]SavedPermille')

        if permille > 0 then
            info.damage = math.floor(info.damage * (1 + permille / 1000))
        end
    end

    return super(actor, target, skill, action, info)
end)
