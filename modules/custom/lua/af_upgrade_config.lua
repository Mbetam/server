-----------------------------------
-- Armor Upgrader: which armor it upgrades, the price of each step and where it stands. Not a module (loaded by require).
-- Eric's choice (2026-09-25): a gil path for Artifact, Relic and Empyrean armor instead of retail's sources (Dynamis
-- Divergence, Sortie/Odyssey, Abyssea... not in LSB). Every tier already exists as an item.
-- Each chain is the old set (base, +1, and +2 for Relic/Empyrean) followed by the Reforged set (Reforged, +1, +2, +3,
-- and +4 for Artifact/Relic; Empyrean ends at +3, as in retail). GEO and RUN have no old sets.
-- Generated from item_basic (names matched per job and slot; "-1" Dynamis items skipped) and checked. Two pieces carry
-- odd names in the item data: BLM Spaekona's Gloves +4 is "spaekonas_gloves" (23988), COR Relic head +2 is
-- "commodores_tricorne_+2" (10666).
-----------------------------------
local config = {}

-- Price of an upgrade, by the tier you upgrade TO
config.prices =
{
    oldPlus1      =   50000, -- base > +1
    oldPlus2      =   75000, -- +1 > +2 (Relic, Empyrean)
    reforged      =  100000, -- old set > Reforged
    reforgedPlus1 =  250000,
    reforgedPlus2 =  500000,
    reforgedPlus3 = 1000000,
    reforgedPlus4 = 2500000, -- Artifact, Relic
}

-- The NPC's look: the Moogle model the Augmenter and the Trust Vendor use
config.npcModel = 82

-- Where the NPC stands. Stand where you want it in game, use !pos, then edit here. Rotation 0-255 (0 = east).
config.placements =
{
    -- Norg, near the Augmenter and the Trust Vendor. Chosen by Eric with !pos (2026-09-25).
    { zone = 'Norg', x = -26.6567, y = 1.0977, z = -35.6453, rotation = 4 },

    -- GM Home, for testing
    { zone = 'GM_Home', x = 12.0, y = 0.0, z = 3.0, rotation = 128 },
}

-- family > job > one chain per slot (head, body, hands, legs, feet); DNC Artifact has a male and a female chain per slot
-- (both genders share item names; male is the lower id). Item ids, lowest tier first. Pieces are matched by slot AND
-- item word (a job can have two different items in one slot, e.g. COR Corsair's Hat vs Corsair's Tricorne).
config.chains =
{
    af =
    {
        WAR =
        {
            { base = { 12511, 15225 }, reforged = { 27663, 27684, 23040, 23375, 23895 } }, -- head: fighters_mask > fighters_mask_+1 > pummelers_mask > pummelers_mask_+1 > pummelers_mask_+2 > pummelers_mask_+3 > pummelers_mask_+4
            { base = { 12638, 14473 }, reforged = { 27807, 27828, 23107, 23442, 23940 } }, -- body: fighters_lorica > fighters_lorica_+1 > pummelers_lorica > pummelers_lorica_+1 > pummelers_lorica_+2 > pummelers_lorica_+3 > pummelers_lorica_+4
            { base = { 13961, 14890 }, reforged = { 27943, 27964, 23174, 23509, 23985 } }, -- hands: fighters_mufflers > fighters_mufflers_+1 > pummelers_mufflers > pummelers_mufflers_+1 > pummelers_mufflers_+2 > pummelers_mufflers_+3 > pummelers_mufflers_+4
            { base = { 14214, 15561 }, reforged = { 28090, 28111, 23241, 23576, 24030 } }, -- legs: fighters_cuisses > fighters_cuisses_+1 > pummelers_cuisses > pummelers_cuisses_+1 > pummelers_cuisses_+2 > pummelers_cuisses_+3 > pummelers_cuisses_+4
            { base = { 14089, 15352 }, reforged = { 28223, 28244, 23308, 23643, 24075 } }, -- feet: fighters_calligae > fighters_calligae_+1 > pummelers_calligae > pummelers_calligae_+1 > pummelers_calligae_+2 > pummelers_calligae_+3 > pummelers_calligae_+4
        },
        MNK =
        {
            { base = { 12512, 15226 }, reforged = { 27664, 27685, 23041, 23376, 23896 } }, -- head: temple_crown > temple_crown_+1 > anchorites_crown > anchorites_crown_+1 > anchorites_crown_+2 > anchorites_crown_+3 > anchorites_crown_+4
            { base = { 12639, 14474 }, reforged = { 27808, 27829, 23108, 23443, 23941 } }, -- body: temple_cyclas > temple_cyclas_+1 > anchorites_cyclas > anchorites_cyclas_+1 > anchorites_cyclas_+2 > anchorites_cyclas_+3 > anchorites_cyclas_+4
            { base = { 13962, 14891 }, reforged = { 27944, 27965, 23175, 23510, 23986 } }, -- hands: temple_gloves > temple_gloves_+1 > anchorites_gloves > anchorites_gloves_+1 > anchorites_gloves_+2 > anchorites_gloves_+3 > anchorites_gloves_+4
            { base = { 14215, 15562 }, reforged = { 28091, 28112, 23242, 23577, 24031 } }, -- legs: temple_hose > temple_hose_+1 > anchorites_hose > anchorites_hose_+1 > anchorites_hose_+2 > anchorites_hose_+3 > anchorites_hose_+4
            { base = { 14090, 15353 }, reforged = { 28224, 28245, 23309, 23644, 24076 } }, -- feet: temple_gaiters > temple_gaiters_+1 > anchorites_gaiters > anchorites_gaiters_+1 > anchorites_gaiters_+2 > anchorites_gaiters_+3 > anchorites_gaiters_+4
        },
        WHM =
        {
            { base = { 13855, 15227 }, reforged = { 27665, 27686, 23042, 23377, 23897 } }, -- head: healers_cap > healers_cap_+1 > theophany_cap > theophany_cap_+1 > theophany_cap_+2 > theophany_cap_+3 > theophany_cap_+4
            { base = { 12640, 14475 }, reforged = { 27809, 27830, 23109, 23444, 23942 } }, -- body: healers_bliaut > healers_bliaut_+1 > theophany_bliaut > theophany_bliaut_+1 > theophany_bliaut_+2 > theophany_bliaut_+3 > theophany_bliaut_+4
            { base = { 13963, 14892 }, reforged = { 27945, 27966, 23176, 23511, 23987 } }, -- hands: healers_mitts > healers_mitts_+1 > theophany_mitts > theophany_mitts_+1 > theophany_mitts_+2 > theophany_mitts_+3 > theophany_mitts_+4
            { base = { 14216, 15563 }, reforged = { 28092, 28113, 23243, 23578, 24032 } }, -- legs: healers_pantaloons > healers_pantaloons_+1 > theophany_pantaloons > theophany_pantaloons_+1 > theophany_pantaloons_+2 > theophany_pantaloons_+3 > theophany_pantaloons_+4
            { base = { 14091, 15354 }, reforged = { 28225, 28246, 23310, 23645, 24077 } }, -- feet: healers_duckbills > healers_duckbills_+1 > theophany_duckbills > theophany_duckbills_+1 > theophany_duckbills_+2 > theophany_duckbills_+3 > theophany_duckbills_+4
        },
        BLM =
        {
            { base = { 13856, 15228 }, reforged = { 27666, 27687, 23043, 23378, 23898 } }, -- head: wizards_petasos > wizards_petasos_+1 > spaekonas_petasos > spaekonas_petasos_+1 > spaekonas_petasos_+2 > spaekonas_petasos_+3 > spaekonas_petasos_+4
            { base = { 12641, 14476 }, reforged = { 27810, 27831, 23110, 23445, 23943 } }, -- body: wizards_coat > wizards_coat_+1 > spaekonas_coat > spaekonas_coat_+1 > spaekonas_coat_+2 > spaekonas_coat_+3 > spaekonas_coat_+4
            { base = { 13964, 14893 }, reforged = { 27946, 27967, 23177, 23512, 23988 } }, -- hands: wizards_gloves > wizards_gloves_+1 > spaekonas_gloves > spaekonas_gloves_+1 > spaekonas_gloves_+2 > spaekonas_gloves_+3 > spaekonas_gloves
            { base = { 14217, 15564 }, reforged = { 28093, 28114, 23244, 23579, 24033 } }, -- legs: wizards_tonban > wizards_tonban_+1 > spaekonas_tonban > spaekonas_tonban_+1 > spaekonas_tonban_+2 > spaekonas_tonban_+3 > spaekonas_tonban_+4
            { base = { 14092, 15355 }, reforged = { 28226, 28247, 23311, 23646, 24078 } }, -- feet: wizards_sabots > wizards_sabots_+1 > spaekonas_sabots > spaekonas_sabots_+1 > spaekonas_sabots_+2 > spaekonas_sabots_+3 > spaekonas_sabots_+4
        },
        RDM =
        {
            { base = { 12513, 15229 }, reforged = { 27667, 27688, 23044, 23379, 23899 } }, -- head: warlocks_chapeau > warlocks_chapeau_+1 > atrophy_chapeau > atrophy_chapeau_+1 > atrophy_chapeau_+2 > atrophy_chapeau_+3 > atrophy_chapeau_+4
            { base = { 12642, 14477 }, reforged = { 27811, 27832, 23111, 23446, 23944 } }, -- body: warlocks_tabard > warlocks_tabard_+1 > atrophy_tabard > atrophy_tabard_+1 > atrophy_tabard_+2 > atrophy_tabard_+3 > atrophy_tabard_+4
            { base = { 13965, 14894 }, reforged = { 27947, 27968, 23178, 23513, 23989 } }, -- hands: warlocks_gloves > warlocks_gloves_+1 > atrophy_gloves > atrophy_gloves_+1 > atrophy_gloves_+2 > atrophy_gloves_+3 > atrophy_gloves_+4
            { base = { 14218, 15565 }, reforged = { 28094, 28115, 23245, 23580, 24034 } }, -- legs: warlocks_tights > warlocks_tights_+1 > atrophy_tights > atrophy_tights_+1 > atrophy_tights_+2 > atrophy_tights_+3 > atrophy_tights_+4
            { base = { 14093, 15356 }, reforged = { 28227, 28248, 23312, 23647, 24079 } }, -- feet: warlocks_boots > warlocks_boots_+1 > atrophy_boots > atrophy_boots_+1 > atrophy_boots_+2 > atrophy_boots_+3 > atrophy_boots_+4
        },
        THF =
        {
            { base = { 12514, 15230 }, reforged = { 27668, 27689, 23045, 23380, 23900 } }, -- head: rogues_bonnet > rogues_bonnet_+1 > pillagers_bonnet > pillagers_bonnet_+1 > pillagers_bonnet_+2 > pillagers_bonnet_+3 > pillagers_bonnet_+4
            { base = { 12643, 14478 }, reforged = { 27812, 27833, 23112, 23447, 23945 } }, -- body: rogues_vest > rogues_vest_+1 > pillagers_vest > pillagers_vest_+1 > pillagers_vest_+2 > pillagers_vest_+3 > pillagers_vest_+4
            { base = { 13966, 14895 }, reforged = { 27948, 27969, 23179, 23514, 23990 } }, -- hands: rogues_armlets > rogues_armlets_+1 > pillagers_armlets > pillagers_armlets_+1 > pillagers_armlets_+2 > pillagers_armlets_+3 > pillagers_armlets_+4
            { base = { 14219, 15566 }, reforged = { 28095, 28116, 23246, 23581, 24035 } }, -- legs: rogues_culottes > rogues_culottes_+1 > pillagers_culottes > pillagers_culottes_+1 > pillagers_culottes_+2 > pillagers_culottes_+3 > pillagers_culottes_+4
            { base = { 14094, 15357 }, reforged = { 28228, 28249, 23313, 23648, 24080 } }, -- feet: rogues_poulaines > rogues_poulaines_+1 > pillagers_poulaines > pillagers_poulaines_+1 > pillagers_poulaines_+2 > pillagers_poulaines_+3 > pillagers_poulaines_+4
        },
        PLD =
        {
            { base = { 12515, 15231 }, reforged = { 27669, 27690, 23046, 23381, 23901 } }, -- head: gallant_coronet > gallant_coronet_+1 > reverence_coronet > reverence_coronet_+1 > reverence_coronet_+2 > reverence_coronet_+3 > reverence_coronet_+4
            { base = { 12644, 14479 }, reforged = { 27813, 27834, 23113, 23448, 23946 } }, -- body: gallant_surcoat > gallant_surcoat_+1 > reverence_surcoat > reverence_surcoat_+1 > reverence_surcoat_+2 > reverence_surcoat_+3 > reverence_surcoat_+4
            { base = { 13967, 14896 }, reforged = { 27949, 27970, 23180, 23515, 23991 } }, -- hands: gallant_gauntlets > gallant_gauntlets_+1 > reverence_gauntlets > reverence_gauntlets_+1 > reverence_gauntlets_+2 > reverence_gauntlets_+3 > reverence_gauntlets_+4
            { base = { 14220, 15567 }, reforged = { 28096, 28117, 23247, 23582, 24036 } }, -- legs: gallant_breeches > gallant_breeches_+1 > reverence_breeches > reverence_breeches_+1 > reverence_breeches_+2 > reverence_breeches_+3 > reverence_breeches_+4
            { base = { 14095, 15358 }, reforged = { 28229, 28250, 23314, 23649, 24081 } }, -- feet: gallant_leggings > gallant_leggings_+1 > reverence_leggings > reverence_leggings_+1 > reverence_leggings_+2 > reverence_leggings_+3 > reverence_leggings_+4
        },
        DRK =
        {
            { base = { 12516, 15232 }, reforged = { 27670, 27691, 23047, 23382, 23902 } }, -- head: chaos_burgeonet > chaos_burgeonet_+1 > ignominy_burgeonet > ignominy_burgeonet_+1 > ignominy_burgeonet_+2 > ignominy_burgeonet_+3 > ignominy_burgeonet_+4
            { base = { 12645, 14480 }, reforged = { 27814, 27835, 23114, 23449, 23947 } }, -- body: chaos_cuirass > chaos_cuirass_+1 > ignominy_cuirass > ignominy_cuirass_+1 > ignominy_cuirass_+2 > ignominy_cuirass_+3 > ignominy_cuirass_+4
            { base = { 13968, 14897 }, reforged = { 27950, 27971, 23181, 23516, 23992 } }, -- hands: chaos_gauntlets > chaos_gauntlets_+1 > ignominy_gauntlets > ignominy_gauntlets_+1 > ignominy_gauntlets_+2 > ignominy_gauntlets_+3 > ignominy_finger_gauntlets_+4
            { base = { 14221, 15568 }, reforged = { 28097, 28118, 23248, 23583, 24037 } }, -- legs: chaos_flanchard > chaos_flanchard_+1 > ignominy_flanchard > ignominy_flanchard_+1 > ignominy_flanchard_+2 > ignominy_flanchard_+3 > ignominy_flanchard_+4
            { base = { 14096, 15359 }, reforged = { 28230, 28251, 23315, 23650, 24082 } }, -- feet: chaos_sollerets > chaos_sollerets_+1 > ignominy_sollerets > ignominy_sollerets_+1 > ignominy_sollerets_+2 > ignominy_sollerets_+3 > ignominy_sollerets_+4
        },
        BST =
        {
            { base = { 12517, 15233 }, reforged = { 27671, 27692, 23048, 23383, 23903 } }, -- head: beast_helm > beast_helm_+1 > totemic_helm > totemic_helm_+1 > totemic_helm_+2 > totemic_helm_+3 > totemic_helm_+4
            { base = { 12646, 14481 }, reforged = { 27815, 27836, 23115, 23450, 23948 } }, -- body: beast_jackcoat > beast_jackcoat_+1 > totemic_jackcoat > totemic_jackcoat_+1 > totemic_jackcoat_+2 > totemic_jackcoat_+3 > totemic_jackcoat_+4
            { base = { 13969, 14898 }, reforged = { 27951, 27972, 23182, 23517, 23993 } }, -- hands: beast_gloves > beast_gloves_+1 > totemic_gloves > totemic_gloves_+1 > totemic_gloves_+2 > totemic_gloves_+3 > totemic_gloves_+4
            { base = { 14222, 15569 }, reforged = { 28098, 28119, 23249, 23584, 24038 } }, -- legs: beast_trousers > beast_trousers_+1 > totemic_trousers > totemic_trousers_+1 > totemic_trousers_+2 > totemic_trousers_+3 > totemic_trousers_+4
            { base = { 14097, 15360 }, reforged = { 28231, 28252, 23316, 23651, 24083 } }, -- feet: beast_gaiters > beast_gaiters_+1 > totemic_gaiters > totemic_gaiters_+1 > totemic_gaiters_+2 > totemic_gaiters_+3 > totemic_gaiters_+4
        },
        BRD =
        {
            { base = { 13857, 15234 }, reforged = { 27672, 27693, 23049, 23384, 23904 } }, -- head: choral_roundlet > choral_roundlet_+1 > brioso_roundlet > brioso_roundlet_+1 > brioso_roundlet_+2 > brioso_roundlet_+3 > brioso_roundlet_+4
            { base = { 12647, 14482 }, reforged = { 27816, 27837, 23116, 23451, 23949 } }, -- body: choral_justaucorps > choral_justaucorps_+1 > brioso_justaucorps > brioso_justaucorps_+1 > brioso_justaucorps_+2 > brioso_justaucorps_+3 > brioso_justaucorps_+4
            { base = { 13970, 14899 }, reforged = { 27952, 27973, 23183, 23518, 23994 } }, -- hands: choral_cuffs > choral_cuffs_+1 > brioso_cuffs > brioso_cuffs_+1 > brioso_cuffs_+2 > brioso_cuffs_+3 > brioso_cuffs_+4
            { base = { 14223, 15570 }, reforged = { 28099, 28120, 23250, 23585, 24039 } }, -- legs: choral_cannions > choral_cannions_+1 > brioso_cannions > brioso_cannions_+1 > brioso_cannions_+2 > brioso_cannions_+3 > brioso_cannions_+4
            { base = { 14098, 15361 }, reforged = { 28232, 28253, 23317, 23652, 24084 } }, -- feet: choral_slippers > choral_slippers_+1 > brioso_slippers > brioso_slippers_+1 > brioso_slippers_+2 > brioso_slippers_+3 > brioso_slippers_+4
        },
        RNG =
        {
            { base = { 12518, 15235 }, reforged = { 27673, 27694, 23050, 23385, 23905 } }, -- head: hunters_beret > hunters_beret_+1 > orion_beret > orion_beret_+1 > orion_beret_+2 > orion_beret_+3 > orion_beret_+4
            { base = { 12648, 14483 }, reforged = { 27817, 27838, 23117, 23452, 23950 } }, -- body: hunters_jerkin > hunters_jerkin_+1 > orion_jerkin > orion_jerkin_+1 > orion_jerkin_+2 > orion_jerkin_+3 > orion_jerkin_+4
            { base = { 13971, 14900 }, reforged = { 27953, 27974, 23184, 23519, 23995 } }, -- hands: hunters_bracers > hunters_bracers_+1 > orion_bracers > orion_bracers_+1 > orion_bracers_+2 > orion_bracers_+3 > orion_bracers_+4
            { base = { 14224, 15571 }, reforged = { 28100, 28121, 23251, 23586, 24040 } }, -- legs: hunters_braccae > hunters_braccae_+1 > orion_braccae > orion_braccae_+1 > orion_braccae_+2 > orion_braccae_+3 > orion_braccae_+4
            { base = { 14099, 15362 }, reforged = { 28233, 28254, 23318, 23653, 24085 } }, -- feet: hunters_socks > hunters_socks_+1 > orion_socks > orion_socks_+1 > orion_socks_+2 > orion_socks_+3 > orion_socks_+4
        },
        SAM =
        {
            { base = { 13868, 15236 }, reforged = { 27674, 27695, 23051, 23386, 23906 } }, -- head: myochin_kabuto > myochin_kabuto_+1 > wakido_kabuto > wakido_kabuto_+1 > wakido_kabuto_+2 > wakido_kabuto_+3 > wakido_kabuto_+4
            { base = { 13781, 14484 }, reforged = { 27818, 27839, 23118, 23453, 23951 } }, -- body: myochin_domaru > myochin_domaru_+1 > wakido_domaru > wakido_domaru_+1 > wakido_domaru_+2 > wakido_domaru_+3 > wakido_domaru_+4
            { base = { 13972, 14901 }, reforged = { 27954, 27975, 23185, 23520, 23996 } }, -- hands: myochin_kote > myochin_kote_+1 > wakido_kote > wakido_kote_+1 > wakido_kote_+2 > wakido_kote_+3 > wakido_kote_+4
            { base = { 14225, 15572 }, reforged = { 28101, 28122, 23252, 23587, 24041 } }, -- legs: myochin_haidate > myochin_haidate_+1 > wakido_haidate > wakido_haidate_+1 > wakido_haidate_+2 > wakido_haidate_+3 > wakido_haidate_+4
            { base = { 14100, 15363 }, reforged = { 28234, 28255, 23319, 23654, 24086 } }, -- feet: myochin_sune-ate > myochin_sune-ate_+1 > wakido_sune-ate > wakido_sune-ate_+1 > wakido_sune-ate_+2 > wakido_sune-ate_+3 > wakido_sune-ate_+4
        },
        NIN =
        {
            { base = { 13869, 15237 }, reforged = { 27675, 27696, 23052, 23387, 23907 } }, -- head: ninja_hatsuburi > ninja_hatsuburi_+1 > hachiya_hatsuburi > hachiya_hatsuburi_+1 > hachiya_hatsuburi_+2 > hachiya_hatsuburi_+3 > hachiya_hatsuburi_+4
            { base = { 13782, 14485 }, reforged = { 27819, 27840, 23119, 23454, 23952 } }, -- body: ninja_chainmail > ninja_chainmail_+1 > hachiya_chainmail > hachiya_chainmail_+1 > hachiya_chainmail_+2 > hachiya_chainmail_+3 > hachiya_chainmail_+4
            { base = { 13973, 14902 }, reforged = { 27955, 27976, 23186, 23521, 23997 } }, -- hands: ninja_tekko > ninja_tekko_+1 > hachiya_tekko > hachiya_tekko_+1 > hachiya_tekko_+2 > hachiya_tekko_+3 > hachiya_tekko_+4
            { base = { 14226, 15573 }, reforged = { 28102, 28123, 23253, 23588, 24042 } }, -- legs: ninja_hakama > ninja_hakama_+1 > hachiya_hakama > hachiya_hakama_+1 > hachiya_hakama_+2 > hachiya_hakama_+3 > hachiya_hakama_+4
            { base = { 14101, 15364 }, reforged = { 28235, 28256, 23320, 23655, 24087 } }, -- feet: ninja_kyahan > ninja_kyahan_+1 > hachiya_kyahan > hachiya_kyahan_+1 > hachiya_kyahan_+2 > hachiya_kyahan_+3 > hachiya_kyahan_+4
        },
        DRG =
        {
            { base = { 12519, 15238 }, reforged = { 27676, 27697, 23053, 23388, 23908 } }, -- head: drachen_armet > drachen_armet_+1 > vishap_armet > vishap_armet_+1 > vishap_armet_+2 > vishap_armet_+3 > vishap_armet_+4
            { base = { 12649, 14486 }, reforged = { 27820, 27841, 23120, 23455, 23953 } }, -- body: drachen_mail > drachen_mail_+1 > vishap_mail > vishap_mail_+1 > vishap_mail_+2 > vishap_mail_+3 > vishap_mail_+4
            { base = { 13974, 14903 }, reforged = { 27956, 27977, 23187, 23522, 23998 } }, -- hands: drachen_finger_gauntlets > drachen_finger_gauntlets_+1 > vishap_finger_gauntlets > vishap_finger_gauntlets_+1 > vishap_finger_gauntlets_+2 > vishap_finger_gauntlets_+3 > vishap_finger_gauntlets_+4
            { base = { 14227, 15574 }, reforged = { 28103, 28124, 23254, 23589, 24043 } }, -- legs: drachen_brais > drachen_brais_+1 > vishap_brais > vishap_brais_+1 > vishap_brais_+2 > vishap_brais_+3 > vishap_brais_+4
            { base = { 14102, 15365 }, reforged = { 28236, 28257, 23321, 23656, 24088 } }, -- feet: drachen_greaves > drachen_greaves_+1 > vishap_greaves > vishap_greaves_+1 > vishap_greaves_+2 > vishap_greaves_+3 > vishap_greaves_+4
        },
        SMN =
        {
            { base = { 12520, 15239 }, reforged = { 27677, 27698, 23054, 23389, 23909 } }, -- head: evokers_horn > evokers_horn_+1 > convokers_horn > convokers_horn_+1 > convokers_horn_+2 > convokers_horn_+3 > convokers_horn_+4
            { base = { 12650, 14487 }, reforged = { 27821, 27842, 23121, 23456, 23954 } }, -- body: evokers_doublet > evokers_doublet_+1 > convokers_doublet > convokers_doublet_+1 > convokers_doublet_+2 > convokers_doublet_+3 > convokers_doublet_+4
            { base = { 13975, 14904 }, reforged = { 27957, 27978, 23188, 23523, 23999 } }, -- hands: evokers_bracers > evokers_bracers_+1 > convokers_bracers > convokers_bracers_+1 > convokers_bracers_+2 > convokers_bracers_+3 > convokers_bracers_+4
            { base = { 14228, 15575 }, reforged = { 28104, 28125, 23255, 23590, 24044 } }, -- legs: evokers_spats > evokers_spats_+1 > convokers_spats > convokers_spats_+1 > convokers_spats_+2 > convokers_spats_+3 > convokers_spats_+4
            { base = { 14103, 15366 }, reforged = { 28237, 28258, 23322, 23657, 24089 } }, -- feet: evokers_pigaches > evokers_pigaches_+1 > convokers_pigaches > convokers_pigaches_+1 > convokers_pigaches_+2 > convokers_pigaches_+3 > convokers_pigaches_+4
        },
        BLU =
        {
            { base = { 15265, 11464 }, reforged = { 27678, 27699, 23055, 23390, 23910 } }, -- head: magus_keffiyeh > magus_keffiyeh_+1 > assimilators_keffiyeh > assimilators_keffiyeh_+1 > assimilators_keffiyeh_+2 > assimilators_keffiyeh_+3 > assimilators_keffiyeh_+4
            { base = { 14521, 11291 }, reforged = { 27822, 27843, 23122, 23457, 23955 } }, -- body: magus_jubbah > magus_jubbah_+1 > assimilators_jubbah > assimilators_jubbah_+1 > assimilators_jubbah_+2 > assimilators_jubbah_+3 > assimilators_jubbah_+4
            { base = { 14928, 15024 }, reforged = { 27958, 27979, 23189, 23524, 24000 } }, -- hands: magus_bazubands > magus_bazubands_+1 > assimilators_bazubands > assimilators_bazubands_+1 > assimilators_bazubands_+2 > assimilators_bazubands_+3 > assimilators_bazubands_+4
            { base = { 15600, 16345 }, reforged = { 28105, 28126, 23256, 23591, 24045 } }, -- legs: magus_shalwar > magus_shalwar_+1 > assimilators_shalwar > assimilators_shalwar_+1 > assimilators_shalwar_+2 > assimilators_shalwar_+3 > assimilators_shalwar_+4
            { base = { 15684, 11381 }, reforged = { 28238, 28259, 23323, 23658, 24090 } }, -- feet: magus_charuqs > magus_charuqs_+1 > assimilators_charuqs > assimilators_charuqs_+1 > assimilators_charuqs_+2 > assimilators_charuqs_+3 > assimilators_charuqs_+4
        },
        COR =
        {
            { base = { 15266, 11467 }, reforged = { 27679, 27700, 23056, 23391, 23911 } }, -- head: corsairs_tricorne > corsairs_tricorne_+1 > laksamanas_tricorne > laksamanas_tricorne_+1 > laksamanas_tricorne_+2 > laksamanas_tricorne_+3 > laksamana_tricorne_+4
            { base = { 14522, 11294 }, reforged = { 27823, 27844, 23123, 23458, 23956 } }, -- body: corsairs_frac > corsairs_frac_+1 > laksamanas_frac > laksamanas_frac_+1 > laksamanas_frac_+2 > laksamanas_frac_+3 > laksamana_frac_+4
            { base = { 14929, 15027 }, reforged = { 27959, 27980, 23190, 23525, 24001 } }, -- hands: corsairs_gants > corsairs_gants_+1 > laksamanas_gants > laksamanas_gants_+1 > laksamanas_gants_+2 > laksamanas_gants_+3 > laksamanas_gants_+4
            { base = { 15601, 16348 }, reforged = { 28106, 28127, 23257, 23592, 24046 } }, -- legs: corsairs_culottes > corsairs_culottes_+1 > laksamanas_trews > laksamanas_trews_+1 > laksamanas_trews_+2 > laksamanas_trews_+3 > laksamanas_trews_+4
            { base = { 15685, 11384 }, reforged = { 28239, 28260, 23324, 23659, 24091 } }, -- feet: corsairs_bottes > corsairs_bottes_+1 > laksamanas_bottes > laksamanas_bottes_+1 > laksamanas_bottes_+2 > laksamanas_bottes_+3 > laksamana_bottes_+4
        },
        PUP =
        {
            { base = { 15267, 11470 }, reforged = { 27680, 27701, 23057, 23392, 23912 } }, -- head: puppetry_taj > puppetry_taj_+1 > foire_taj > foire_taj_+1 > foire_taj_+2 > foire_taj_+3 > foire_taj_+4
            { base = { 14523, 11297 }, reforged = { 27824, 27845, 23124, 23459, 23957 } }, -- body: puppetry_tobe > puppetry_tobe_+1 > foire_tobe > foire_tobe_+1 > foire_tobe_+2 > foire_tobe_+3 > foire_tobe_+4
            { base = { 14930, 15030 }, reforged = { 27960, 27981, 23191, 23526, 24002 } }, -- hands: puppetry_dastanas > puppetry_dastanas_+1 > foire_dastanas > foire_dastanas_+1 > foire_dastanas_+2 > foire_dastanas_+3 > foire_dastanas_+4
            { base = { 15602, 16351 }, reforged = { 28107, 28128, 23258, 23593, 24047 } }, -- legs: puppetry_churidars > puppetry_churidars_+1 > foire_churidars > foire_churidars_+1 > foire_churidars_+2 > foire_churidars_+3 > foire_churidars_+4
            { base = { 15686, 11387 }, reforged = { 28240, 28261, 23325, 23660, 24092 } }, -- feet: puppetry_babouches > puppetry_babouches_+1 > foire_babouches > foire_babouches_+1 > foire_babouches_+2 > foire_babouches_+3 > foire_babouches_+4
        },
        DNC =
        {
            { base = { 16138, 11475 }, reforged = { 27681, 27702, 23058, 23393, 23913 } }, -- head (male): dancers_tiara > dancers_tiara_+1 > maxixi_tiara > maxixi_tiara_+1 > maxixi_tiara_+2 > maxixi_tiara_+3 > maxixi_tiara_+4
            { base = { 16139, 11476 }, reforged = { 27682, 27703, 23059, 23394, 23914 } }, -- head (female): dancers_tiara > dancers_tiara_+1 > maxixi_tiara > maxixi_tiara_+1 > maxixi_tiara_+2 > maxixi_tiara_+3 > maxixi_tiara_+4
            { base = { 14578, 11302 }, reforged = { 27825, 27846, 23125, 23460, 23958 } }, -- body (male): dancers_casaque > dancers_casaque_+1 > maxixi_casaque > maxixi_casaque_+1 > maxixi_casaque_+2 > maxixi_casaque_+3 > maxixi_casaque_+4
            { base = { 14579, 11303 }, reforged = { 27826, 27847, 23126, 23461, 23959 } }, -- body (female): dancers_casaque > dancers_casaque_+1 > maxixi_casaque > maxixi_casaque_+1 > maxixi_casaque_+2 > maxixi_casaque_+3 > maxixi_casaque_+4
            { base = { 15002, 15035 }, reforged = { 27961, 27982, 23192, 23527, 24003 } }, -- hands (male): dancers_bangles > dancers_bangles_+1 > maxixi_bangles > maxixi_bangles_+1 > maxixi_bangles_+2 > maxixi_bangles_+3 > maxixi_bangles_+4
            { base = { 15003, 15036 }, reforged = { 27962, 27983, 23193, 23528, 24004 } }, -- hands (female): dancers_bangles > dancers_bangles_+1 > maxixi_bangles > maxixi_bangles_+1 > maxixi_bangles_+2 > maxixi_bangles_+3 > maxixi_bangles_+4
            { base = { 15659, 16357 }, reforged = { 28108, 28129, 23259, 23594, 24048 } }, -- legs (male): dancers_tights > dancers_tights_+1 > maxixi_tights > maxixi_tights_+1 > maxixi_tights_+2 > maxixi_tights_+3 > maxixi_tights_+4
            { base = { 15660, 16358 }, reforged = { 28109, 28130, 23260, 23595, 24049 } }, -- legs (female): dancers_tights > dancers_tights_+1 > maxixi_tights > maxixi_tights_+1 > maxixi_tights_+2 > maxixi_tights_+3 > maxixi_tights_+4
            { base = { 15746, 11393 }, reforged = { 28241, 28262, 23326, 23661, 24093 } }, -- feet (male): dancers_toe_shoes > dancers_toe_shoes_+1 > maxixi_toe_shoes > maxixi_toe_shoes_+1 > maxixi_toe_shoes_+2 > maxixi_toe_shoes_+3 > maxixi_toe_shoes_+4
            { base = { 15747, 11394 }, reforged = { 28242, 28263, 23327, 23662, 24094 } }, -- feet (female): dancers_toe_shoes > dancers_toe_shoes_+1 > maxixi_toe_shoes > maxixi_toe_shoes_+1 > maxixi_toe_shoes_+2 > maxixi_toe_shoes_+3 > maxixi_toe_shoes_+4
        },
        SCH =
        {
            { base = { 16140, 11477 }, reforged = { 27683, 27704, 23060, 23395, 23915 } }, -- head: scholars_mortarboard > scholars_mortarboard_+1 > academics_mortarboard > academics_mortarboard_+1 > academics_mortarboard_+2 > academics_mortarboard_+3 > academics_mortarboard_+4
            { base = { 14580, 11304 }, reforged = { 27827, 27848, 23127, 23462, 23960 } }, -- body: scholars_gown > scholars_gown_+1 > academics_gown > academics_gown_+1 > academics_gown_+2 > academics_gown_+3 > academics_gown_+4
            { base = { 15004, 15037 }, reforged = { 27963, 27984, 23194, 23529, 24005 } }, -- hands: scholars_bracers > scholars_bracers_+1 > academics_bracers > academics_bracers_+1 > academics_bracers_+2 > academics_bracers_+3 > academics_bracers_+4
            { base = { 16311, 16359 }, reforged = { 28110, 28131, 23261, 23596, 24050 } }, -- legs: scholars_pants > scholars_pants_+1 > academics_pants > academics_pants_+1 > academics_pants_+2 > academics_pants_+3 > academics_pants_+4
            { base = { 15748, 11395 }, reforged = { 28243, 28264, 23328, 23663, 24095 } }, -- feet: scholars_loafers > scholars_loafers_+1 > academics_loafers > academics_loafers_+1 > academics_loafers_+2 > academics_loafers_+3 > academics_loafers_+4
        },
        GEO =
        {
            { base = {  }, reforged = { 27786, 27705, 23061, 23396, 23916 } }, -- head: geomancy_galero > geomancy_galero_+1 > geomancy_galero_+2 > geomancy_galero_+3 > geomancy_galero_+4
            { base = {  }, reforged = { 27926, 27849, 23128, 23463, 23961 } }, -- body: geomancy_tunic > geomancy_tunic_+1 > geomancy_tunic_+2 > geomancy_tunic_+3 > geomancy_tunic_+4
            { base = {  }, reforged = { 28066, 27985, 23195, 23530, 24006 } }, -- hands: geomancy_mitaines > geomancy_mitaines_+1 > geomancy_mitaines_+2 > geomancy_mitaines_+3 > geomancy_mitaines_+4
            { base = {  }, reforged = { 28206, 28132, 23262, 23597, 24051 } }, -- legs: geomancy_pants > geomancy_pants_+1 > geomancy_pants_+2 > geomancy_pants_+3 > geomancy_pants_+4
            { base = {  }, reforged = { 28346, 28265, 23329, 23664, 24096 } }, -- feet: geomancy_sandals > geomancy_sandals_+1 > geomancy_sandals_+2 > geomancy_sandals_+3 > geomancy_sandals_+4
        },
        RUN =
        {
            { base = {  }, reforged = { 27787, 27706, 23062, 23397, 23917 } }, -- head: runeist_bandeau > runeist_bandeau_+1 > runeist_bandeau_+2 > runeist_bandeau_+3 > runeist_bandeau_+4
            { base = {  }, reforged = { 27927, 27850, 23129, 23464, 23962 } }, -- body: runeist_coat > runeist_coat_+1 > runeist_coat_+2 > runeist_coat_+3 > runeist_coat_+4
            { base = {  }, reforged = { 28067, 27986, 23196, 23531, 24007 } }, -- hands: runeist_mitons > runeist_mitons_+1 > runeist_mitons_+2 > runeist_mitons_+3 > runeist_mitons_+4
            { base = {  }, reforged = { 28207, 28133, 23263, 23598, 24052 } }, -- legs: runeist_trousers > runeist_trousers_+1 > runeist_trousers_+2 > runeist_trousers_+3 > runeist_trousers_+4
            { base = {  }, reforged = { 28347, 28266, 23330, 23665, 24097 } }, -- feet: runeist_bottes > runeist_bottes_+1 > runeist_bottes_+2 > runeist_bottes_+3 > runeist_boots_+4
        },
    },
    relic =
    {
        WAR =
        {
            { base = { 15072, 15245, 10650 }, reforged = { 26624, 26625, 23063, 23398, 23918 } }, -- head: warriors_mask > warriors_mask_+1 > warriors_mask_+2 > agoge_mask > agoge_mask_+1 > agoge_mask_+2 > agoge_mask_+3 > agoge_mask_+4
            { base = { 15087, 14500, 10670 }, reforged = { 26800, 26801, 23130, 23465, 23963 } }, -- body: warriors_lorica > warriors_lorica_+1 > warriors_lorica_+2 > agoge_lorica > agoge_lorica_+1 > agoge_lorica_+2 > agoge_lorica_+3 > agoge_lorica_+4
            { base = { 15102, 14909, 10690 }, reforged = { 26976, 26977, 23197, 23532, 24008 } }, -- hands: warriors_mufflers > warriors_mufflers_+1 > warriors_mufflers_+2 > agoge_mufflers > agoge_mufflers_+1 > agoge_mufflers_+2 > agoge_mufflers_+3 > agoge_mufflers_+4
            { base = { 15117, 15580, 10710 }, reforged = { 27152, 27153, 23264, 23599, 24053 } }, -- legs: warriors_cuisses > warriors_cuisses_+1 > warriors_cuisses_+2 > agoge_cuisses > agoge_cuisses_+1 > agoge_cuisses_+2 > agoge_cuisses_+3 > agoge_cuisses_+4
            { base = { 15132, 15665, 10730 }, reforged = { 27328, 27329, 23331, 23666, 24098 } }, -- feet: warriors_calligae > warriors_calligae_+1 > warriors_calligae_+2 > agoge_calligae > agoge_calligae_+1 > agoge_calligae_+2 > agoge_calligae_+3 > agoge_calligae_+4
        },
        MNK =
        {
            { base = { 15073, 15246, 10651 }, reforged = { 26626, 26627, 23064, 23399, 23919 } }, -- head: melee_crown > melee_crown_+1 > melee_crown_+2 > hesychasts_crown > hesychasts_crown_+1 > hesychasts_crown_+2 > hesychasts_crown_+3 > hesychasts_crown_+4
            { base = { 15088, 14501, 10671 }, reforged = { 26802, 26803, 23131, 23466, 23964 } }, -- body: melee_cyclas > melee_cyclas_+1 > melee_cyclas_+2 > hesychasts_cyclas > hesychasts_cyclas_+1 > hesychasts_cyclas_+2 > hesychasts_cyclas_+3 > hesychasts_cyclas_+4
            { base = { 15103, 14910, 10691 }, reforged = { 26978, 26979, 23198, 23533, 24009 } }, -- hands: melee_gloves > melee_gloves_+1 > melee_gloves_+2 > hesychasts_gloves > hesychasts_gloves_+1 > hesychasts_gloves_+2 > hesychasts_gloves_+3 > hesychasts_gloves_+4
            { base = { 15118, 15581, 10711 }, reforged = { 27154, 27155, 23265, 23600, 24054 } }, -- legs: melee_hose > melee_hose_+1 > melee_hose_+2 > hesychasts_hose > hesychasts_hose_+1 > hesychasts_hose_+2 > hesychasts_hose_+3 > hesychasts_hose_+4
            { base = { 15133, 15666, 10731 }, reforged = { 27330, 27331, 23332, 23667, 24099 } }, -- feet: melee_gaiters > melee_gaiters_+1 > melee_gaiters_+2 > hesychasts_gaiters > hesychasts_gaiters_+1 > hesychasts_gaiters_+2 > hesychasts_gaiters_+3 > hesychasts_gaiters_+4
        },
        WHM =
        {
            { base = { 15074, 15247, 10652 }, reforged = { 26628, 26629, 23065, 23400, 23920 } }, -- head: clerics_cap > clerics_cap_+1 > clerics_cap_+2 > piety_cap > piety_cap_+1 > piety_cap_+2 > piety_cap_+3 > piety_cap_+4
            { base = { 15089, 14502, 10672 }, reforged = { 26804, 26805, 23132, 23467, 23965 } }, -- body: clerics_bliaut > clerics_bliaut_+1 > clerics_bliaut_+2 > piety_bliaut > piety_bliaut_+1 > piety_bliaut_+2 > piety_bliaut_+3 > piety_bliaut_+4
            { base = { 15104, 14911, 10692 }, reforged = { 26980, 26981, 23199, 23534, 24010 } }, -- hands: clerics_mitts > clerics_mitts_+1 > clerics_mitts_+2 > piety_mitts > piety_mitts_+1 > piety_mitts_+2 > piety_mitts_+3 > piety_mitts_+4
            { base = { 15119, 15582, 10712 }, reforged = { 27156, 27157, 23266, 23601, 24055 } }, -- legs: clerics_pantaloons > clerics_pantaloons_+1 > clerics_pantaloons_+2 > piety_pantaloons > piety_pantaloons_+1 > piety_pantaloons_+2 > piety_pantaloons_+3 > piety_pantaloons_+4
            { base = { 15134, 15667, 10732 }, reforged = { 27332, 27333, 23333, 23668, 24100 } }, -- feet: clerics_duckbills > clerics_duckbills_+1 > clerics_duckbills_+2 > piety_duckbills > piety_duckbills_+1 > piety_duckbills_+2 > piety_duckbills_+3 > piety_duckbills_+4
        },
        BLM =
        {
            { base = { 15075, 15248, 10653 }, reforged = { 26630, 26631, 23066, 23401, 23921 } }, -- head: sorcerers_petasos > sorcerers_petasos_+1 > sorcerers_petasos_+2 > archmages_petasos > archmages_petasos_+1 > archmages_petasos_+2 > archmages_petasos_+3 > archmages_petasos_+4
            { base = { 15090, 14503, 10673 }, reforged = { 26806, 26807, 23133, 23468, 23966 } }, -- body: sorcerers_coat > sorcerers_coat_+1 > sorcerers_coat_+2 > archmages_coat > archmages_coat_+1 > archmages_coat_+2 > archmages_coat_+3 > archmages_coat_+4
            { base = { 15105, 14912, 10693 }, reforged = { 26982, 26983, 23200, 23535, 24011 } }, -- hands: sorcerers_gloves > sorcerers_gloves_+1 > sorcerers_gloves_+2 > archmages_gloves > archmages_gloves_+1 > archmages_gloves_+2 > archmages_gloves_+3 > archmages_gloves_+4
            { base = { 15120, 15583, 10713 }, reforged = { 27158, 27159, 23267, 23602, 24056 } }, -- legs: sorcerers_tonban > sorcerers_tonban_+1 > sorcerers_tonban_+2 > archmages_tonban > archmages_tonban_+1 > archmages_tonban_+2 > archmages_tonban_+3 > archmages_tonban_+4
            { base = { 15135, 15668, 10733 }, reforged = { 27334, 27335, 23334, 23669, 24101 } }, -- feet: sorcerers_sabots > sorcerers_sabots_+1 > sorcerers_sabots_+2 > archmages_sabots > archmages_sabots_+1 > archmages_sabots_+2 > archmages_sabots_+3 > archmages_sabots_+4
        },
        RDM =
        {
            { base = { 15076, 15249, 10654 }, reforged = { 26632, 26633, 23067, 23402, 23922 } }, -- head: duelists_chapeau > duelists_chapeau_+1 > duelists_chapeau_+2 > vitiation_chapeau > vitiation_chapeau_+1 > vitiation_chapeau_+2 > vitiation_chapeau_+3 > vitiation_chapeau_+4
            { base = { 15091, 14504, 10674 }, reforged = { 26808, 26809, 23134, 23469, 23967 } }, -- body: duelists_tabard > duelists_tabard_+1 > duelists_tabard_+2 > vitiation_tabard > vitiation_tabard_+1 > vitiation_tabard_+2 > vitiation_tabard_+3 > vitiation_tabard_+4
            { base = { 15106, 14913, 10694 }, reforged = { 26984, 26985, 23201, 23536, 24012 } }, -- hands: duelists_gloves > duelists_gloves_+1 > duelists_gloves_+2 > vitiation_gloves > vitiation_gloves_+1 > vitiation_gloves_+2 > vitiation_gloves_+3 > vitiation_gloves_+4
            { base = { 15121, 15584, 10714 }, reforged = { 27160, 27161, 23268, 23603, 24057 } }, -- legs: duelists_tights > duelists_tights_+1 > duelists_tights_+2 > vitiation_tights > vitiation_tights_+1 > vitiation_tights_+2 > vitiation_tights_+3 > vitiation_tights_+4
            { base = { 15136, 15669, 10734 }, reforged = { 27336, 27337, 23335, 23670, 24102 } }, -- feet: duelists_boots > duelists_boots_+1 > duelists_boots_+2 > vitiation_boots > vitiation_boots_+1 > vitiation_boots_+2 > vitiation_boots_+3 > vitiation_boots_+4
        },
        THF =
        {
            { base = { 15077, 15250, 10655 }, reforged = { 26634, 26635, 23068, 23403, 23923 } }, -- head: assassins_bonnet > assassins_bonnet_+1 > assassins_bonnet_+2 > plunderers_bonnet > plunderers_bonnet_+1 > plunderers_bonnet_+2 > plunderers_bonnet_+3 > plunderers_bonnet_+4
            { base = { 15092, 14505, 10675 }, reforged = { 26810, 26811, 23135, 23470, 23968 } }, -- body: assassins_vest > assassins_vest_+1 > assassins_vest_+2 > plunderers_vest > plunderers_vest_+1 > plunderers_vest_+2 > plunderers_vest_+3 > plunderers_vest_+4
            { base = { 15107, 14914, 10695 }, reforged = { 26986, 26987, 23202, 23537, 24013 } }, -- hands: assassins_armlets > assassins_armlets_+1 > assassins_armlets_+2 > plunderers_armlets > plunderers_armlets_+1 > plunderers_armlets_+2 > plunderers_armlets_+3 > plunderers_armlets_+4
            { base = { 15122, 15585, 10715 }, reforged = { 27162, 27163, 23269, 23604, 24058 } }, -- legs: assassins_culottes > assassins_culottes_+1 > assassins_culottes_+2 > plunderers_culottes > plunderers_culottes_+1 > plunderers_culottes_+2 > plunderers_culottes_+3 > plunderers_culottes_+4
            { base = { 15137, 15670, 10735 }, reforged = { 27338, 27339, 23336, 23671, 24103 } }, -- feet: assassins_poulaines > assassins_poulaines_+1 > assassins_poulaines_+2 > plunderers_poulaines > plunderers_poulaines_+1 > plunderers_poulaines_+2 > plunderers_poulaines_+3 > plunderers_poulaines_+4
        },
        PLD =
        {
            { base = { 15078, 15251, 10656 }, reforged = { 26636, 26637, 23069, 23404, 23924 } }, -- head: valor_coronet > valor_coronet_+1 > valor_coronet_+2 > caballarius_coronet > caballarius_coronet_+1 > caballarius_coronet_+2 > caballarius_coronet_+3 > caballarius_coronet_+4
            { base = { 15093, 14506, 10676 }, reforged = { 26812, 26813, 23136, 23471, 23969 } }, -- body: valor_surcoat > valor_surcoat_+1 > valor_surcoat_+2 > caballarius_surcoat > caballarius_surcoat_+1 > caballarius_surcoat_+2 > caballarius_surcoat_+3 > caballarius_surcoat_+4
            { base = { 15108, 14915, 10696 }, reforged = { 26988, 26989, 23203, 23538, 24014 } }, -- hands: valor_gauntlets > valor_gauntlets_+1 > valor_gauntlets_+2 > caballarius_gauntlets > caballarius_gauntlets_+1 > caballarius_gauntlets_+2 > caballarius_gauntlets_+3 > caballarius_gauntlets_+4
            { base = { 15123, 15586, 10716 }, reforged = { 27164, 27165, 23270, 23605, 24059 } }, -- legs: valor_breeches > valor_breeches_+1 > valor_breeches_+2 > caballarius_breeches > caballarius_breeches_+1 > caballarius_breeches_+2 > caballarius_breeches_+3 > caballarius_breeches_+4
            { base = { 15138, 15671, 10736 }, reforged = { 27340, 27341, 23337, 23672, 24104 } }, -- feet: valor_leggings > valor_leggings_+1 > valor_leggings_+2 > caballarius_leggings > caballarius_leggings_+1 > caballarius_leggings_+2 > caballarius_leggings_+3 > caballarius_leggings_+4
        },
        DRK =
        {
            { base = { 15079, 15252, 10657 }, reforged = { 26638, 26639, 23070, 23405, 23925 } }, -- head: abyss_burgeonet > abyss_burgeonet_+1 > abyss_burgeonet_+2 > fallens_burgeonet > fallens_burgeonet_+1 > fallens_burgeonet_+2 > fallens_burgeonet_+3 > fallens_burgeonet_+4
            { base = { 15094, 14507, 10677 }, reforged = { 26814, 26815, 23137, 23472, 23970 } }, -- body: abyss_cuirass > abyss_cuirass_+1 > abyss_cuirass_+2 > fallens_cuirass > fallens_cuirass_+1 > fallens_cuirass_+2 > fallens_cuirass_+3 > fallens_cuirass_+4
            { base = { 15109, 14916, 10697 }, reforged = { 26990, 26991, 23204, 23539, 24015 } }, -- hands: abyss_gauntlets > abyss_gauntlets_+1 > abyss_gauntlets_+2 > fallens_finger_gauntlets > fallens_finger_gauntlets_+1 > fallens_finger_gauntlets_+2 > fallens_finger_gauntlets_+3 > fallens_finger_gauntlets_+4
            { base = { 15124, 15587, 10717 }, reforged = { 27166, 27167, 23271, 23606, 24060 } }, -- legs: abyss_flanchard > abyss_flanchard_+1 > abyss_flanchard_+2 > fallens_flanchard > fallens_flanchard_+1 > fallens_flanchard_+2 > fallens_flanchard_+3 > fallens_flanchard_+4
            { base = { 15139, 15672, 10737 }, reforged = { 27342, 27343, 23338, 23673, 24105 } }, -- feet: abyss_sollerets > abyss_sollerets_+1 > abyss_sollerets_+2 > fallens_sollerets > fallens_sollerets_+1 > fallens_sollerets_+2 > fallens_sollerets_+3 > fallens_sollerets_+4
        },
        BST =
        {
            { base = { 15080, 15253, 10658 }, reforged = { 26640, 26641, 23071, 23406, 23926 } }, -- head: monster_helm > monster_helm_+1 > monster_helm_+2 > ankusa_helm > ankusa_helm_+1 > ankusa_helm_+2 > ankusa_helm_+3 > ankusa_helm_+4
            { base = { 15095, 14508, 10678 }, reforged = { 26816, 26817, 23138, 23473, 23971 } }, -- body: monster_jackcoat > monster_jackcoat_+1 > monster_jackcoat_+2 > ankusa_jackcoat > ankusa_jackcoat_+1 > ankusa_jackcoat_+2 > ankusa_jackcoat_+3 > ankusa_jackcoat_+4
            { base = { 15110, 14917, 10698 }, reforged = { 26992, 26993, 23205, 23540, 24016 } }, -- hands: monster_gloves > monster_gloves_+1 > monster_gloves_+2 > ankusa_gloves > ankusa_gloves_+1 > ankusa_gloves_+2 > ankusa_gloves_+3 > ankusa_gloves_+4
            { base = { 15125, 15588, 10718 }, reforged = { 27168, 27169, 23272, 23607, 24061 } }, -- legs: monster_trousers > monster_trousers_+1 > monster_trousers_+2 > ankusa_trousers > ankusa_trousers_+1 > ankusa_trousers_+2 > ankusa_trousers_+3 > ankusa_trousers_+4
            { base = { 15140, 15673, 10738 }, reforged = { 27344, 27345, 23339, 23674, 24106 } }, -- feet: monster_gaiters > monster_gaiters_+1 > monster_gaiters_+2 > ankusa_gaiters > ankusa_gaiters_+1 > ankusa_gaiters_+2 > ankusa_gaiters_+3 > ankusa_gaiters_+4
        },
        BRD =
        {
            { base = { 15081, 15254, 10659 }, reforged = { 26642, 26643, 23072, 23407, 23927 } }, -- head: bards_roundlet > bards_roundlet_+1 > bards_roundlet_+2 > bihu_roundlet > bihu_roundlet_+1 > bihu_roundlet_+2 > bihu_roundlet_+3 > bihu_roundlet_+4
            { base = { 15096, 14509, 10679 }, reforged = { 26818, 26819, 23139, 23474, 23972 } }, -- body: bards_justaucorps > bards_justaucorps_+1 > bards_justaucorps_+2 > bihu_justaucorps > bihu_justaucorps_+1 > bihu_justaucorps_+2 > bihu_justaucorps_+3 > bihu_justaucorps_+4
            { base = { 15111, 14918, 10699 }, reforged = { 26994, 26995, 23206, 23541, 24017 } }, -- hands: bards_cuffs > bards_cuffs_+1 > bards_cuffs_+2 > bihu_cuffs > bihu_cuffs_+1 > bihu_cuffs_+2 > bihu_cuffs_+3 > bihu_cuffs_+4
            { base = { 15126, 15589, 10719 }, reforged = { 27170, 27171, 23273, 23608, 24062 } }, -- legs: bards_cannions > bards_cannions_+1 > bards_cannions_+2 > bihu_cannions > bihu_cannions_+1 > bihu_cannions_+2 > bihu_cannions_+3 > bihu_cannions_+4
            { base = { 15141, 15674, 10739 }, reforged = { 27346, 27347, 23340, 23675, 24107 } }, -- feet: bards_slippers > bards_slippers_+1 > bards_slippers_+2 > bihu_slippers > bihu_slippers_+1 > bihu_slippers_+2 > bihu_slippers_+3 > bihu_slippers_+4
        },
        RNG =
        {
            { base = { 15082, 15255, 10660 }, reforged = { 26644, 26645, 23073, 23408, 23928 } }, -- head: scouts_beret > scouts_beret_+1 > scouts_beret_+2 > arcadian_beret > arcadian_beret_+1 > arcadian_beret_+2 > arcadian_beret_+3 > arcadian_beret_+4
            { base = { 15097, 14510, 10680 }, reforged = { 26820, 26821, 23140, 23475, 23973 } }, -- body: scouts_jerkin > scouts_jerkin_+1 > scouts_jerkin_+2 > arcadian_jerkin > arcadian_jerkin_+1 > arcadian_jerkin_+2 > arcadian_jerkin_+3 > arcadian_jerkin_+4
            { base = { 15112, 14919, 10700 }, reforged = { 26996, 26997, 23207, 23542, 24018 } }, -- hands: scouts_bracers > scouts_bracers_+1 > scouts_bracers_+2 > arcadian_bracers > arcadian_bracers_+1 > arcadian_bracers_+2 > arcadian_bracers_+3 > arcadian_bracers_+4
            { base = { 15127, 15590, 10720 }, reforged = { 27172, 27173, 23274, 23609, 24063 } }, -- legs: scouts_braccae > scouts_braccae_+1 > scouts_braccae_+2 > arcadian_braccae > arcadian_braccae_+1 > arcadian_braccae_+2 > arcadian_braccae_+3 > arcadian_braccae_+4
            { base = { 15142, 15675, 10740 }, reforged = { 27348, 27349, 23341, 23676, 24108 } }, -- feet: scouts_socks > scouts_socks_+1 > scouts_socks_+2 > arcadian_socks > arcadian_socks_+1 > arcadian_socks_+2 > arcadian_socks_+3 > arcadian_socks_+4
        },
        SAM =
        {
            { base = { 15083, 15256, 10661 }, reforged = { 26646, 26647, 23074, 23409, 23929 } }, -- head: saotome_kabuto > saotome_kabuto_+1 > saotome_kabuto_+2 > sakonji_kabuto > sakonji_kabuto_+1 > sakonji_kabuto_+2 > sakonji_kabuto_+3 > sakonji_kabuto_+4
            { base = { 15098, 14511, 10681 }, reforged = { 26822, 26823, 23141, 23476, 23974 } }, -- body: saotome_domaru > saotome_domaru_+1 > saotome_domaru_+2 > sakonji_domaru > sakonji_domaru_+1 > sakonji_domaru_+2 > sakonji_domaru_+3 > sakonji_domaru_+4
            { base = { 15113, 14920, 10701 }, reforged = { 26998, 26999, 23208, 23543, 24019 } }, -- hands: saotome_kote > saotome_kote_+1 > saotome_kote_+2 > sakonji_kote > sakonji_kote_+1 > sakonji_kote_+2 > sakonji_kote_+3 > sakonji_kote_+4
            { base = { 15128, 15591, 10721 }, reforged = { 27174, 27175, 23275, 23610, 24064 } }, -- legs: saotome_haidate > saotome_haidate_+1 > saotome_haidate_+2 > sakonji_haidate > sakonji_haidate_+1 > sakonji_haidate_+2 > sakonji_haidate_+3 > sakonji_haidate_+4
            { base = { 15143, 15676, 10741 }, reforged = { 27350, 27351, 23342, 23677, 24109 } }, -- feet: saotome_sune-ate > saotome_sune-ate_+1 > saotome_sune-ate_+2 > sakonji_sune-ate > sakonji_sune-ate_+1 > sakonji_sune-ate_+2 > sakonji_sune-ate_+3 > sakonji_sune-ate_+4
        },
        NIN =
        {
            { base = { 15084, 15257, 10662 }, reforged = { 26648, 26649, 23075, 23410, 23930 } }, -- head: koga_hatsuburi > koga_hatsuburi_+1 > koga_hatsuburi_+2 > mochizuki_hatsuburi > mochizuki_hatsuburi_+1 > mochizuki_hatsuburi_+2 > mochizuki_hatsuburi_+3 > mochizuki_hatsuburi_+4
            { base = { 15099, 14512, 10682 }, reforged = { 26824, 26825, 23142, 23477, 23975 } }, -- body: koga_chainmail > koga_chainmail_+1 > koga_chainmail_+2 > mochizuki_chainmail > mochizuki_chainmail_+1 > mochizuki_chainmail_+2 > mochizuki_chainmail_+3 > mochizuki_chainmail_+4
            { base = { 15114, 14921, 10702 }, reforged = { 27000, 27001, 23209, 23544, 24020 } }, -- hands: koga_tekko > koga_tekko_+1 > koga_tekko_+2 > mochizuki_tekko > mochizuki_tekko_+1 > mochizuki_tekko_+2 > mochizuki_tekko_+3 > mochizuki_tekko_+4
            { base = { 15129, 15592, 10722 }, reforged = { 27176, 27177, 23276, 23611, 24065 } }, -- legs: koga_hakama > koga_hakama_+1 > koga_hakama_+2 > mochizuki_hakama > mochizuki_hakama_+1 > mochizuki_hakama_+2 > mochizuki_hakama_+3 > mochizuki_hakama_+4
            { base = { 15144, 15677, 10742 }, reforged = { 27352, 27353, 23343, 23678, 24110 } }, -- feet: koga_kyahan > koga_kyahan_+1 > koga_kyahan_+2 > mochizuki_kyahan > mochizuki_kyahan_+1 > mochizuki_kyahan_+2 > mochizuki_kyahan_+3 > mochizuki_kyahan_+4
        },
        DRG =
        {
            { base = { 15085, 15258, 10663 }, reforged = { 26650, 26651, 23076, 23411, 23931 } }, -- head: wyrm_armet > wyrm_armet_+1 > wyrm_armet_+2 > pteroslaver_armet > pteroslaver_armet_+1 > pteroslaver_armet_+2 > pteroslaver_armet_+3 > pteroslaver_armet_+4
            { base = { 15100, 14513, 10683 }, reforged = { 26826, 26827, 23143, 23478, 23976 } }, -- body: wyrm_mail > wyrm_mail_+1 > wyrm_mail_+2 > pteroslaver_mail > pteroslaver_mail_+1 > pteroslaver_mail_+2 > pteroslaver_mail_+3 > pteroslaver_mail_+4
            { base = { 15115, 14922, 10703 }, reforged = { 27002, 27003, 23210, 23545, 24021 } }, -- hands: wyrm_finger_gauntlets > wyrm_finger_gauntlets_+1 > wyrm_finger_gauntlets_+2 > pteroslaver_finger_gauntlets > pteroslaver_finger_gauntlets_+1 > pteroslaver_finger_gauntlets_+2 > pteroslaver_finger_gauntlets_+3 > pteroslaver_finger_gauntlets_+4
            { base = { 15130, 15593, 10723 }, reforged = { 27178, 27179, 23277, 23612, 24066 } }, -- legs: wyrm_brais > wyrm_brais_+1 > wyrm_brais_+2 > pteroslaver_brais > pteroslaver_brais_+1 > pteroslaver_brais_+2 > pteroslaver_brais_+3 > pteroslaver_brais_+4
            { base = { 15145, 15678, 10743 }, reforged = { 27354, 27355, 23344, 23679, 24111 } }, -- feet: wyrm_greaves > wyrm_greaves_+1 > wyrm_greaves_+2 > pteroslaver_greaves > pteroslaver_greaves_+1 > pteroslaver_greaves_+2 > pteroslaver_greaves_+3 > pteroslaver_greaves_+4
        },
        SMN =
        {
            { base = { 15086, 15259, 10664 }, reforged = { 26652, 26653, 23077, 23412, 23932 } }, -- head: summoners_horn > summoners_horn_+1 > summoners_horn_+2 > glyphic_horn > glyphic_horn_+1 > glyphic_horn_+2 > glyphic_horn_+3 > glyphic_horn_+4
            { base = { 15101, 14514, 10684 }, reforged = { 26828, 26829, 23144, 23479, 23977 } }, -- body: summoners_doublet > summoners_doublet_+1 > summoners_doublet_+2 > glyphic_doublet > glyphic_doublet_+1 > glyphic_doublet_+2 > glyphic_doublet_+3 > glyphic_doublet_+4
            { base = { 15116, 14923, 10704 }, reforged = { 27004, 27005, 23211, 23546, 24022 } }, -- hands: summoners_bracers > summoners_bracers_+1 > summoners_bracers_+2 > glyphic_bracers > glyphic_bracers_+1 > glyphic_bracers_+2 > glyphic_bracers_+3 > glyphic_bracers_+4
            { base = { 15131, 15594, 10724 }, reforged = { 27180, 27181, 23278, 23613, 24067 } }, -- legs: summoners_spats > summoners_spats_+1 > summoners_spats_+2 > glyphic_spats > glyphic_spats_+1 > glyphic_spats_+2 > glyphic_spats_+3 > glyphic_spats_+4
            { base = { 15146, 15679, 10744 }, reforged = { 27356, 27357, 23345, 23680, 24112 } }, -- feet: summoners_pigaches > summoners_pigaches_+1 > summoners_pigaches_+2 > glyphic_pigaches > glyphic_pigaches_+1 > glyphic_pigaches_+2 > glyphic_pigaches_+3 > glyphic_pigaches_+4
        },
        BLU =
        {
            { base = { 11465, 11466, 10665 }, reforged = { 26654, 26655, 23078, 23413, 23933 } }, -- head: mirage_keffiyeh > mirage_keffiyeh_+1 > mirage_keffiyeh_+2 > luhlaza_keffiyeh > luhlaza_keffiyeh_+1 > luhlaza_keffiyeh_+2 > luhlaza_keffiyeh_+3 > luhlaza_keffiyeh_+4
            { base = { 11292, 11293, 10685 }, reforged = { 26830, 26831, 23145, 23480, 23978 } }, -- body: mirage_jubbah > mirage_jubbah_+1 > mirage_jubbah_+2 > luhlaza_jubbah > luhlaza_jubbah_+1 > luhlaza_jubbah_+2 > luhlaza_jubbah_+3 > luhlaza_jubbah_+4
            { base = { 15025, 15026, 10705 }, reforged = { 27006, 27007, 23212, 23547, 24023 } }, -- hands: mirage_bazubands > mirage_bazubands_+1 > mirage_bazubands_+2 > luhlaza_bazubands > luhlaza_bazubands_+1 > luhlaza_bazubands_+2 > luhlaza_bazubands_+3 > luhlaza_bazubands_+4
            { base = { 16346, 16347, 10725 }, reforged = { 27182, 27183, 23279, 23614, 24068 } }, -- legs: mirage_shalwar > mirage_shalwar_+1 > mirage_shalwar_+2 > luhlaza_shalwar > luhlaza_shalwar_+1 > luhlaza_shalwar_+2 > luhlaza_shalwar_+3 > luhlaza_shalwar_+4
            { base = { 11382, 11383, 10745 }, reforged = { 27358, 27359, 23346, 23681, 24113 } }, -- feet: mirage_charuqs > mirage_charuqs_+1 > mirage_charuqs_+2 > luhlaza_charuqs > luhlaza_charuqs_+1 > luhlaza_charuqs_+2 > luhlaza_charuqs_+3 > luhlaza_charuqs_+4
        },
        COR =
        {
            { base = { 11468, 11469, 10666 }, reforged = { 26656, 26657, 23079, 23414, 23934 } }, -- head: commodore_tricorne > commodore_tricorne_+1 > commodores_tricorne_+2 > lanun_tricorne > lanun_tricorne_+1 > lanun_tricorne_+2 > lanun_tricorne_+3 > lanun_tricorne_+4
            { base = { 11295, 11296, 10686 }, reforged = { 26832, 26833, 23146, 23481, 23979 } }, -- body: commodore_frac > commodore_frac_+1 > commodore_frac_+2 > lanun_frac > lanun_frac_+1 > lanun_frac_+2 > lanun_frac_+3 > lanun_frac_+4
            { base = { 15028, 15029, 10706 }, reforged = { 27008, 27009, 23213, 23548, 24024 } }, -- hands: commodore_gants > commodore_gants_+1 > commodore_gants_+2 > lanun_gants > lanun_gants_+1 > lanun_gants_+2 > lanun_gants_+3 > lanun_gants_+4
            { base = { 16349, 16350, 10726 }, reforged = { 27184, 27185, 23280, 23615, 24069 } }, -- legs: commodore_trews > commodore_trews_+1 > commodore_trews_+2 > lanun_trews > lanun_trews_+1 > lanun_trews_+2 > lanun_trews_+3 > lanun_trews_+4
            { base = { 11385, 11386, 10746 }, reforged = { 27360, 27361, 23347, 23682, 24114 } }, -- feet: commodore_bottes > commodore_bottes_+1 > commodore_bottes_+2 > lanun_bottes > lanun_bottes_+1 > lanun_bottes_+2 > lanun_bottes_+3 > lanun_bottes_+4
        },
        PUP =
        {
            { base = { 11471, 11472, 10667 }, reforged = { 26658, 26659, 23080, 23415, 23935 } }, -- head: pantin_taj > pantin_taj_+1 > pantin_taj_+2 > pitre_taj > pitre_taj_+1 > pitre_taj_+2 > pitre_taj_+3 > pitre_taj_+4
            { base = { 11298, 11299, 10687 }, reforged = { 26834, 26835, 23147, 23482, 23980 } }, -- body: pantin_tobe > pantin_tobe_+1 > pantin_tobe_+2 > pitre_tobe > pitre_tobe_+1 > pitre_tobe_+2 > pitre_tobe_+3 > pitre_tobe_+4
            { base = { 15031, 15032, 10707 }, reforged = { 27010, 27011, 23214, 23549, 24025 } }, -- hands: pantin_dastanas > pantin_dastanas_+1 > pantin_dastanas_+2 > pitre_dastanas > pitre_dastanas_+1 > pitre_dastanas_+2 > pitre_dastanas_+3 > pitre_dastanas_+4
            { base = { 16352, 16353, 10727 }, reforged = { 27186, 27187, 23281, 23616, 24070 } }, -- legs: pantin_churidars > pantin_churidars_+1 > pantin_churidars_+2 > pitre_churidars > pitre_churidars_+1 > pitre_churidars_+2 > pitre_churidars_+3 > pitre_churidars_+4
            { base = { 11388, 11389, 10747 }, reforged = { 27362, 27363, 23348, 23683, 24115 } }, -- feet: pantin_babouches > pantin_babouches_+1 > pantin_babouches_+2 > pitre_babouches > pitre_babouches_+1 > pitre_babouches_+2 > pitre_babouches_+3 > pitre_babouches_+4
        },
        DNC =
        {
            { base = { 11478, 11479, 10668 }, reforged = { 26660, 26661, 23081, 23416, 23936 } }, -- head: etoile_tiara > etoile_tiara_+1 > etoile_tiara_+2 > horos_tiara > horos_tiara_+1 > horos_tiara_+2 > horos_tiara_+3 > horos_tiara_+4
            { base = { 11305, 11306, 10688 }, reforged = { 26836, 26837, 23148, 23483, 23981 } }, -- body: etoile_casaque > etoile_casaque_+1 > etoile_casaque_+2 > horos_casaque > horos_casaque_+1 > horos_casaque_+2 > horos_casaque_+3 > horos_casaque_+4
            { base = { 15038, 15039, 10708 }, reforged = { 27012, 27013, 23215, 23550, 24026 } }, -- hands: etoile_bangles > etoile_bangles_+1 > etoile_bangles_+2 > horos_bangles > horos_bangles_+1 > horos_bangles_+2 > horos_bangles_+3 > horos_bangles_+4
            { base = { 16360, 16361, 10728 }, reforged = { 27188, 27189, 23282, 23617, 24071 } }, -- legs: etoile_tights > etoile_tights_+1 > etoile_tights_+2 > horos_tights > horos_tights_+1 > horos_tights_+2 > horos_tights_+3 > horos_tights_+4
            { base = { 11396, 11397, 10748 }, reforged = { 27364, 27365, 23349, 23684, 24116 } }, -- feet: etoile_toe_shoes > etoile_toe_shoes_+1 > etoile_toe_shoes_+2 > horos_toe_shoes > horos_toe_shoes_+1 > horos_toe_shoes_+2 > horos_toe_shoes_+3 > horos_toe_shoes_+4
        },
        SCH =
        {
            { base = { 11480, 11481, 10669 }, reforged = { 26662, 26663, 23082, 23417, 23937 } }, -- head: argute_mortarboard > argute_mortarboard_+1 > argute_mortarboard_+2 > pedagogy_mortarboard > pedagogy_mortarboard_+1 > pedagogy_mortarboard_+2 > pedagogy_mortarboard_+3 > pedagogy_mortarboard_+4
            { base = { 11307, 11308, 10689 }, reforged = { 26838, 26839, 23149, 23484, 23982 } }, -- body: argute_gown > argute_gown_+1 > argute_gown_+2 > pedagogy_gown > pedagogy_gown_+1 > pedagogy_gown_+2 > pedagogy_gown_+3 > pedagogy_gown_+4
            { base = { 15040, 15041, 10709 }, reforged = { 27014, 27015, 23216, 23551, 24027 } }, -- hands: argute_bracers > argute_bracers_+1 > argute_bracers_+2 > pedagogy_bracers > pedagogy_bracers_+1 > pedagogy_bracers_+2 > pedagogy_bracers_+3 > pedagogy_bracers_+4
            { base = { 16362, 16363, 10729 }, reforged = { 27190, 27191, 23283, 23618, 24072 } }, -- legs: argute_pants > argute_pants_+1 > argute_pants_+2 > pedagogy_pants > pedagogy_pants_+1 > pedagogy_pants_+2 > pedagogy_pants_+3 > pedagogy_pants_+4
            { base = { 11398, 11399, 10749 }, reforged = { 27366, 27367, 23350, 23685, 24117 } }, -- feet: argute_loafers > argute_loafers_+1 > argute_loafers_+2 > pedagogy_loafers > pedagogy_loafers_+1 > pedagogy_loafers_+2 > pedagogy_loafers_+3 > pedagogy_loafers_+4
        },
        GEO =
        {
            { base = {  }, reforged = { 26664, 26665, 23083, 23418, 23938 } }, -- head: bagua_galero > bagua_galero_+1 > bagua_galero_+2 > bagua_galero_+3 > bagua_galero_+4
            { base = {  }, reforged = { 26840, 26841, 23150, 23485, 23983 } }, -- body: bagua_tunic > bagua_tunic_+1 > bagua_tunic_+2 > bagua_tunic_+3 > bagua_tunic_+4
            { base = {  }, reforged = { 27016, 27017, 23217, 23552, 24028 } }, -- hands: bagua_mitaines > bagua_mitaines_+1 > bagua_mitaines_+2 > bagua_mitaines_+3 > bagua_mitaines_+4
            { base = {  }, reforged = { 27192, 27193, 23284, 23619, 24073 } }, -- legs: bagua_pants > bagua_pants_+1 > bagua_pants_+2 > bagua_pants_+3 > bagua_pants_+4
            { base = {  }, reforged = { 27368, 27369, 23351, 23686, 24118 } }, -- feet: bagua_sandals > bagua_sandals_+1 > bagua_sandals_+2 > bagua_sandals_+3 > bagua_sandals_+4
        },
        RUN =
        {
            { base = {  }, reforged = { 26666, 26667, 23084, 23419, 23939 } }, -- head: futhark_bandeau > futhark_bandeau_+1 > futhark_bandeau_+2 > futhark_bandeau_+3 > futhark_bandeau_+4
            { base = {  }, reforged = { 26842, 26843, 23151, 23486, 23984 } }, -- body: futhark_coat > futhark_coat_+1 > futhark_coat_+2 > futhark_coat_+3 > futhark_coat_+4
            { base = {  }, reforged = { 27018, 27019, 23218, 23553, 24029 } }, -- hands: futhark_mitons > futhark_mitons_+1 > futhark_mitons_+2 > futhark_mitons_+3 > futhark_mitons_+4
            { base = {  }, reforged = { 27194, 27195, 23285, 23620, 24074 } }, -- legs: futhark_trousers > futhark_trousers_+1 > futhark_trousers_+2 > futhark_trousers_+3 > futhark_trousers_+4
            { base = {  }, reforged = { 27370, 27371, 23352, 23687, 24119 } }, -- feet: futhark_boots > futhark_boots_+1 > futhark_boots_+2 > futhark_boots_+3 > futhark_boots_+4
        },
    },
    empyrean =
    {
        WAR =
        {
            { base = { 12008, 11164, 11064 }, reforged = { 26740, 26741, 23085, 23420 } }, -- head: ravagers_mask > ravagers_mask_+1 > ravagers_mask_+2 > boii_mask > boii_mask_+1 > boii_mask_+2 > boii_mask_+3
            { base = { 12028, 11184, 11084 }, reforged = { 26898, 26899, 23152, 23487 } }, -- body: ravagers_lorica > ravagers_lorica_+1 > ravagers_lorica_+2 > boii_lorica > boii_lorica_+1 > boii_lorica_+2 > boii_lorica_+3
            { base = { 12048, 11204, 11104 }, reforged = { 27052, 27053, 23219, 23554 } }, -- hands: ravagers_mufflers > ravagers_mufflers_+1 > ravagers_mufflers_+2 > boii_mufflers > boii_mufflers_+1 > boii_mufflers_+2 > boii_mufflers_+3
            { base = { 12068, 11224, 11124 }, reforged = { 27237, 27238, 23286, 23621 } }, -- legs: ravagers_cuisses > ravagers_cuisses_+1 > ravagers_cuisses_+2 > boii_cuisses > boii_cuisses_+1 > boii_cuisses_+2 > boii_cuisses_+3
            { base = { 12088, 11244, 11144 }, reforged = { 27411, 27412, 23353, 23688 } }, -- feet: ravagers_calligae > ravagers_calligae_+1 > ravagers_calligae_+2 > boii_calligae > boii_calligae_+1 > boii_calligae_+2 > boii_calligae_+3
        },
        MNK =
        {
            { base = { 12009, 11165, 11065 }, reforged = { 26742, 26743, 23086, 23421 } }, -- head: tantra_crown > tantra_crown_+1 > tantra_crown_+2 > bhikku_crown > bhikku_crown_+1 > bhikku_crown_+2 > bhikku_crown_+3
            { base = { 12029, 11185, 11085 }, reforged = { 26900, 26901, 23153, 23488 } }, -- body: tantra_cyclas > tantra_cyclas_+1 > tantra_cyclas_+2 > bhikku_cyclas > bhikku_cyclas_+1 > bhikku_cyclas_+2 > bhikku_cyclas_+3
            { base = { 12049, 11205, 11105 }, reforged = { 27054, 27055, 23220, 23555 } }, -- hands: tantra_gloves > tantra_gloves_+1 > tantra_gloves_+2 > bhikku_gloves > bhikku_gloves_+1 > bhikku_gloves_+2 > bhikku_gloves_+3
            { base = { 12069, 11225, 11125 }, reforged = { 27239, 27240, 23287, 23622 } }, -- legs: tantra_hose > tantra_hose_+1 > tantra_hose_+2 > bhikku_hose > bhikku_hose_+1 > bhikku_hose_+2 > bhikku_hose_+3
            { base = { 12089, 11245, 11145 }, reforged = { 27413, 27414, 23354, 23689 } }, -- feet: tantra_gaiters > tantra_gaiters_+1 > tantra_gaiters_+2 > bhikku_gaiters > bhikku_gaiters_+1 > bhikku_gaiters_+2 > bhikku_gaiters_+3
        },
        WHM =
        {
            { base = { 12010, 11166, 11066 }, reforged = { 26744, 26745, 23087, 23422 } }, -- head: orison_cap > orison_cap_+1 > orison_cap_+2 > ebers_cap > ebers_cap_+1 > ebers_cap_+2 > ebers_cap_+3
            { base = { 12030, 11186, 11086 }, reforged = { 26902, 26903, 23154, 23489 } }, -- body: orison_bliaut > orison_bliaut_+1 > orison_bliaut_+2 > ebers_bliaut > ebers_bliaut_+1 > ebers_bliaut_+2 > ebers_bliaut_+3
            { base = { 12050, 11206, 11106 }, reforged = { 27056, 27057, 23221, 23556 } }, -- hands: orison_mitts > orison_mitts_+1 > orison_mitts_+2 > ebers_mitts > ebers_mitts_+1 > ebers_mitts_+2 > ebers_mitts_+3
            { base = { 12070, 11226, 11126 }, reforged = { 27241, 27242, 23288, 23623 } }, -- legs: orison_pantaloons > orison_pantaloons_+1 > orison_pantaloons_+2 > ebers_pantaloons > ebers_pantaloons_+1 > ebers_pantaloons_+2 > ebers_pantaloons_+3
            { base = { 12090, 11246, 11146 }, reforged = { 27415, 27416, 23355, 23690 } }, -- feet: orison_duckbills > orison_duckbills_+1 > orison_duckbills_+2 > ebers_duckbills > ebers_duckbills_+1 > ebers_duckbills_+2 > ebers_duckbills_+3
        },
        BLM =
        {
            { base = { 12011, 11167, 11067 }, reforged = { 26746, 26747, 23088, 23423 } }, -- head: goetia_petasos > goetia_petasos_+1 > goetia_petasos_+2 > wicce_petasos > wicce_petasos_+1 > wicce_petasos_+2 > wicce_petasos_+3
            { base = { 12031, 11187, 11087 }, reforged = { 26904, 26905, 23155, 23490 } }, -- body: goetia_coat > goetia_coat_+1 > goetia_coat_+2 > wicce_coat > wicce_coat_+1 > wicce_coat_+2 > wicce_coat_+3
            { base = { 12051, 11207, 11107 }, reforged = { 27058, 27059, 23222, 23557 } }, -- hands: goetia_gloves > goetia_gloves_+1 > goetia_gloves_+2 > wicce_gloves > wicce_gloves_+1 > wicce_gloves_+2 > wicce_gloves_+3
            { base = { 12071, 11227, 11127 }, reforged = { 27243, 27244, 23289, 23624 } }, -- legs: goetia_chausses > goetia_chausses_+1 > goetia_chausses_+2 > wicce_chausses > wicce_chausses_+1 > wicce_chausses_+2 > wicce_chausses_+3
            { base = { 12091, 11247, 11147 }, reforged = { 27417, 27418, 23356, 23691 } }, -- feet: goetia_sabots > goetia_sabots_+1 > goetia_sabots_+2 > wicce_sabots > wicce_sabots_+1 > wicce_sabots_+2 > wicce_sabots_+3
        },
        RDM =
        {
            { base = { 12012, 11168, 11068 }, reforged = { 26748, 26749, 23089, 23424 } }, -- head: estoqueurs_chappel > estoqueurs_chappel_+1 > estoqueurs_chappel_+2 > lethargy_chappel > lethargy_chappel_+1 > lethargy_chappel_+2 > lethargy_chappel_+3
            { base = { 12032, 11188, 11088 }, reforged = { 26906, 26907, 23156, 23491 } }, -- body: estoqueurs_sayon > estoqueurs_sayon_+1 > estoqueurs_sayon_+2 > lethargy_sayon > lethargy_sayon_+1 > lethargy_sayon_+2 > lethargy_sayon_+3
            { base = { 12052, 11208, 11108 }, reforged = { 27060, 27061, 23223, 23558 } }, -- hands: estoqueurs_gantherots > estoqueurs_gantherots_+1 > estoqueurs_gantherots_+2 > lethargy_gantherots > lethargy_gantherots_+1 > lethargy_gantherots_+2 > lethargy_gantherots_+3
            { base = { 12072, 11228, 11128 }, reforged = { 27245, 27246, 23290, 23625 } }, -- legs: estoqueurs_fuseau > estoqueurs_fuseau_+1 > estoqueurs_fuseau_+2 > lethargy_fuseau > lethargy_fuseau_+1 > lethargy_fuseau_+2 > lethargy_fuseau_+3
            { base = { 12092, 11248, 11148 }, reforged = { 27419, 27420, 23357, 23692 } }, -- feet: estoqueurs_houseaux > estoqueurs_houseaux_+1 > estoqueurs_houseaux_+2 > lethargy_houseaux > lethargy_houseaux_+1 > lethargy_houseaux_+2 > lethargy_houseaux_+3
        },
        THF =
        {
            { base = { 12013, 11169, 11069 }, reforged = { 26750, 26751, 23090, 23425 } }, -- head: raiders_bonnet > raiders_bonnet_+1 > raiders_bonnet_+2 > skulkers_bonnet > skulkers_bonnet_+1 > skulkers_bonnet_+2 > skulkers_bonnet_+3
            { base = { 12033, 11189, 11089 }, reforged = { 26908, 26909, 23157, 23492 } }, -- body: raiders_vest > raiders_vest_+1 > raiders_vest_+2 > skulkers_vest > skulkers_vest_+1 > skulkers_vest_+2 > skulkers_vest_+3
            { base = { 12053, 11209, 11109 }, reforged = { 27062, 27063, 23224, 23559 } }, -- hands: raiders_armlets > raiders_armlets_+1 > raiders_armlets_+2 > skulkers_armlets > skulkers_armlets_+1 > skulkers_armlets_+2 > skulkers_armlets_+3
            { base = { 12073, 11229, 11129 }, reforged = { 27247, 27248, 23291, 23626 } }, -- legs: raiders_culottes > raiders_culottes_+1 > raiders_culottes_+2 > skulkers_culottes > skulkers_culottes_+1 > skulkers_culottes_+2 > skulkers_culottes_+3
            { base = { 12093, 11249, 11149 }, reforged = { 27421, 27422, 23358, 23693 } }, -- feet: raiders_poulaines > raiders_poulaines_+1 > raiders_poulaines_+2 > skulkers_poulaines > skulkers_poulaines_+1 > skulkers_poulaines_+2 > skulkers_poulaines_+3
        },
        PLD =
        {
            { base = { 12014, 11170, 11070 }, reforged = { 26752, 26753, 23091, 23426 } }, -- head: creed_armet > creed_armet_+1 > creed_armet_+2 > chevaliers_armet > chevaliers_armet_+1 > chevaliers_armet_+2 > chevaliers_armet_+3
            { base = { 12034, 11190, 11090 }, reforged = { 26910, 26911, 23158, 23493 } }, -- body: creed_cuirass > creed_cuirass_+1 > creed_cuirass_+2 > chevaliers_cuirass > chevaliers_cuirass_+1 > chevaliers_cuirass_+2 > chevaliers_cuirass_+3
            { base = { 12054, 11210, 11110 }, reforged = { 27064, 27065, 23225, 23560 } }, -- hands: creed_gauntlets > creed_gauntlets_+1 > creed_gauntlets_+2 > chevaliers_gauntlets > chevaliers_gauntlets_+1 > chevaliers_gauntlets_+2 > chevaliers_gauntlets_+3
            { base = { 12074, 11230, 11130 }, reforged = { 27249, 27250, 23292, 23627 } }, -- legs: creed_cuisses > creed_cuisses_+1 > creed_cuisses_+2 > chevaliers_cuisses > chevaliers_cuisses_+1 > chevaliers_cuisses_+2 > chevaliers_cuisses_+3
            { base = { 12094, 11250, 11150 }, reforged = { 27423, 27424, 23359, 23694 } }, -- feet: creed_sabatons > creed_sabatons_+1 > creed_sabatons_+2 > chevaliers_sabatons > chevaliers_sabatons_+1 > chevaliers_sabatons_+2 > chevaliers_sabatons_+3
        },
        DRK =
        {
            { base = { 12015, 11171, 11071 }, reforged = { 26754, 26755, 23092, 23427 } }, -- head: bale_burgeonet > bale_burgeonet_+1 > bale_burgeonet_+2 > heathens_burgeonet > heathens_burgeonet_+1 > heathens_burgeonet_+2 > heathens_burgeonet_+3
            { base = { 12035, 11191, 11091 }, reforged = { 26912, 26913, 23159, 23494 } }, -- body: bale_cuirass > bale_cuirass_+1 > bale_cuirass_+2 > heathens_cuirass > heathens_cuirass_+1 > heathens_cuirass_+2 > heathens_cuirass_+3
            { base = { 12055, 11211, 11111 }, reforged = { 27066, 27067, 23226, 23561 } }, -- hands: bale_gauntlets > bale_gauntlets_+1 > bale_gauntlets_+2 > heathens_gauntlets > heathens_gauntlets_+1 > heathens_gauntlets_+2 > heathens_gauntlets_+3
            { base = { 12075, 11231, 11131 }, reforged = { 27251, 27252, 23293, 23628 } }, -- legs: bale_flanchard > bale_flanchard_+1 > bale_flanchard_+2 > heathens_flanchard > heathens_flanchard_+1 > heathens_flanchard_+2 > heathens_flanchards_+3
            { base = { 12095, 11251, 11151 }, reforged = { 27425, 27426, 23360, 23695 } }, -- feet: bale_sollerets > bale_sollerets_+1 > bale_sollerets_+2 > heathens_sollerets > heathens_sollerets_+1 > heathens_sollerets_+2 > heathens_sollerets_+3
        },
        BST =
        {
            { base = { 12016, 11172, 11072 }, reforged = { 26756, 26757, 23093, 23428 } }, -- head: ferine_cabasset > ferine_cabasset_+1 > ferine_cabasset_+2 > nukumi_cabasset > nukumi_cabasset_+1 > nukumi_cabasset_+2 > nukumi_cabasset_+3
            { base = { 12036, 11192, 11092 }, reforged = { 26914, 26915, 23160, 23495 } }, -- body: ferine_gausape > ferine_gausape_+1 > ferine_gausape_+2 > nukumi_gausape > nukumi_gausape_+1 > nukumi_gausape_+2 > nukumi_gausape_+3
            { base = { 12056, 11212, 11112 }, reforged = { 27068, 27069, 23227, 23562 } }, -- hands: ferine_manoplas > ferine_manoplas_+1 > ferine_manoplas_+2 > nukumi_manoplas > nukumi_manoplas_+1 > nukumi_manoplas_+2 > nukumi_manoplas_+3
            { base = { 12076, 11232, 11132 }, reforged = { 27253, 27254, 23294, 23629 } }, -- legs: ferine_quijotes > ferine_quijotes_+1 > ferine_quijotes_+2 > nukumi_quijotes > nukumi_quijotes_+1 > nukumi_quijotes_+2 > nukumi_quijotes_+3
            { base = { 12096, 11252, 11152 }, reforged = { 27427, 27428, 23361, 23696 } }, -- feet: ferine_ocreae > ferine_ocreae_+1 > ferine_ocreae_+2 > nukumi_ocreae > nukumi_ocreae_+1 > nukumi_ocreae_+2 > nukumi_ocreae_+3
        },
        BRD =
        {
            { base = { 12017, 11173, 11073 }, reforged = { 26758, 26759, 23094, 23429 } }, -- head: aoidos_calot > aoidos_calot_+1 > aoidos_calot_+2 > fili_calot > fili_calot_+1 > fili_calot_+2 > fili_calot_+3
            { base = { 12037, 11193, 11093 }, reforged = { 26916, 26917, 23161, 23496 } }, -- body: aoidos_hongreline > aoidos_hongreline_+1 > aoidos_hongreline_+2 > fili_hongreline > fili_hongreline_+1 > fili_hongreline_+2 > fili_hongreline_+3
            { base = { 12057, 11213, 11113 }, reforged = { 27070, 27071, 23228, 23563 } }, -- hands: aoidos_manchettes > aoidos_manchettes_+1 > aoidos_manchettes_+2 > fili_manchettes > fili_manchettes_+1 > fili_manchettes_+2 > fili_manchettes_+3
            { base = { 12077, 11233, 11133 }, reforged = { 27255, 27256, 23295, 23630 } }, -- legs: aoidos_rhingrave > aoidos_rhingrave_+1 > aoidos_rhingrave_+2 > fili_rhingrave > fili_rhingrave_+1 > fili_rhingrave_+2 > fili_rhingrave_+3
            { base = { 12097, 11253, 11153 }, reforged = { 27429, 27430, 23362, 23697 } }, -- feet: aoidos_cothurnes > aoidos_cothurnes_+1 > aoidos_cothurnes_+2 > fili_cothurnes > fili_cothurnes_+1 > fili_cothurnes_+2 > fili_cothurnes_+3
        },
        RNG =
        {
            { base = { 12018, 11174, 11074 }, reforged = { 26760, 26761, 23095, 23430 } }, -- head: sylvan_gapette > sylvan_gapette_+1 > sylvan_gapette_+2 > amini_gapette > amini_gapette_+1 > amini_gapette_+2 > amini_gapette_+3
            { base = { 12038, 11194, 11094 }, reforged = { 26918, 26919, 23162, 23497 } }, -- body: sylvan_caban > sylvan_caban_+1 > sylvan_caban_+2 > amini_caban > amini_caban_+1 > amini_caban_+2 > amini_caban_+3
            { base = { 12058, 11214, 11114 }, reforged = { 27072, 27073, 23229, 23564 } }, -- hands: sylvan_glovelettes > sylvan_glovelettes_+1 > sylvan_glovelettes_+2 > amini_glovelettes > amini_glovelettes_+1 > amini_glovelettes_+2 > amini_glovelettes_+3
            { base = { 12078, 11234, 11134 }, reforged = { 27257, 27258, 23296, 23631 } }, -- legs: sylvan_bragues > sylvan_bragues_+1 > sylvan_bragues_+2 > amini_bragues > amini_bragues_+1 > amini_bragues_+2 > amini_bragues_+3
            { base = { 12098, 11254, 11154 }, reforged = { 27431, 27432, 23363, 23698 } }, -- feet: sylvan_bottillons > sylvan_bottillons_+1 > sylvan_bottillons_+2 > amini_bottillons > amini_bottillons_+1 > amini_bottillons_+2 > amini_bottillons_+3
        },
        SAM =
        {
            { base = { 12019, 11175, 11075 }, reforged = { 26762, 26763, 23096, 23431 } }, -- head: unkai_kabuto > unkai_kabuto_+1 > unkai_kabuto_+2 > kasuga_kabuto > kasuga_kabuto_+1 > kasuga_kabuto_+2 > kasuga_kabuto_+3
            { base = { 12039, 11195, 11095 }, reforged = { 26920, 26921, 23163, 23498 } }, -- body: unkai_domaru > unkai_domaru_+1 > unkai_domaru_+2 > kasuga_domaru > kasuga_domaru_+1 > kasuga_domaru_+2 > kasuga_domaru_+3
            { base = { 12059, 11215, 11115 }, reforged = { 27074, 27075, 23230, 23565 } }, -- hands: unkai_kote > unkai_kote_+1 > unkai_kote_+2 > kasuga_kote > kasuga_kote_+1 > kasuga_kote_+2 > kasuga_kote_+3
            { base = { 12079, 11235, 11135 }, reforged = { 27259, 27260, 23297, 23632 } }, -- legs: unkai_haidate > unkai_haidate_+1 > unkai_haidate_+2 > kasuga_haidate > kasuga_haidate_+1 > kasuga_haidate_+2 > kasuga_haidate_+3
            { base = { 12099, 11255, 11155 }, reforged = { 27433, 27434, 23364, 23699 } }, -- feet: unkai_sune-ate > unkai_sune-ate_+1 > unkai_sune-ate_+2 > kasuga_sune-ate > kasuga_sune-ate_+1 > kasuga_sune-ate_+2 > kasuga_sune-ate_+3
        },
        NIN =
        {
            { base = { 12020, 11176, 11076 }, reforged = { 26764, 26765, 23097, 23432 } }, -- head: iga_zukin > iga_zukin_+1 > iga_zukin_+2 > hattori_zukin > hattori_zukin_+1 > hattori_zukin_+2 > hattori_zukin_+3
            { base = { 12040, 11196, 11096 }, reforged = { 26922, 26923, 23164, 23499 } }, -- body: iga_ningi > iga_ningi_+1 > iga_ningi_+2 > hattori_ningi > hattori_ningi_+1 > hattori_ningi_+2 > hattori_ningi_+3
            { base = { 12060, 11216, 11116 }, reforged = { 27076, 27077, 23231, 23566 } }, -- hands: iga_tekko > iga_tekko_+1 > iga_tekko_+2 > hattori_tekko > hattori_tekko_+1 > hattori_tekko_+2 > hattori_tekko_+3
            { base = { 12080, 11236, 11136 }, reforged = { 27261, 27262, 23298, 23633 } }, -- legs: iga_hakama > iga_hakama_+1 > iga_hakama_+2 > hattori_hakama > hattori_hakama_+1 > hattori_hakama_+2 > hattori_hakama_+3
            { base = { 12100, 11256, 11156 }, reforged = { 27435, 27436, 23365, 23700 } }, -- feet: iga_kyahan > iga_kyahan_+1 > iga_kyahan_+2 > hattori_kyahan > hattori_kyahan_+1 > hattori_kyahan_+2 > hattori_kyahan_+3
        },
        DRG =
        {
            { base = { 12021, 11177, 11077 }, reforged = { 26766, 26767, 23098, 23433 } }, -- head: lancers_mezail > lancers_mezail_+1 > lancers_mezail_+2 > peltasts_mezail > peltasts_mezail_+1 > peltasts_mezail_+2 > peltasts_mezail_+3
            { base = { 12041, 11197, 11097 }, reforged = { 26924, 26925, 23165, 23500 } }, -- body: lancers_plackart > lancers_plackart_+1 > lancers_plackart_+2 > peltasts_plackart > peltasts_plackart_+1 > peltasts_plackart_+2 > peltasts_plackart_+3
            { base = { 12061, 11217, 11117 }, reforged = { 27078, 27079, 23232, 23567 } }, -- hands: lancers_vambraces > lancers_vambraces_+1 > lancers_vambraces_+2 > peltasts_vambraces > peltasts_vambraces_+1 > peltasts_vambraces_+2 > peltasts_vambraces_+3
            { base = { 12081, 11237, 11137 }, reforged = { 27263, 27264, 23299, 23634 } }, -- legs: lancers_cuissots > lancers_cuissots_+1 > lancers_cuissots_+2 > peltasts_cuissots > peltasts_cuissots_+1 > peltasts_cuissots_+2 > peltasts_cuissots_+3
            { base = { 12101, 11257, 11157 }, reforged = { 27437, 27438, 23366, 23701 } }, -- feet: lancers_schynbalds > lancers_schynbalds_+1 > lancers_schynbalds_+2 > peltasts_schynbalds > peltasts_schynbalds_+1 > peltasts_schynbalds_+2 > peltasts_schynbalds_+3
        },
        SMN =
        {
            { base = { 12022, 11178, 11078 }, reforged = { 26768, 26769, 23099, 23434 } }, -- head: callers_horn > callers_horn_+1 > callers_horn_+2 > beckoners_horn > beckoners_horn_+1 > beckoners_horn_+2 > beckoners_horn_+3
            { base = { 12042, 11198, 11098 }, reforged = { 26926, 26927, 23166, 23501 } }, -- body: callers_doublet > callers_doublet_+1 > callers_doublet_+2 > beckoners_doublet > beckoners_doublet_+1 > beckoners_doublet_+2 > beckoners_doublet_+3
            { base = { 12062, 11218, 11118 }, reforged = { 27080, 27081, 23233, 23568 } }, -- hands: callers_bracers > callers_bracers_+1 > callers_bracers_+2 > beckoners_bracers > beckoners_bracers_+1 > beckoners_bracers_+2 > beckoners_bracers_+3
            { base = { 12082, 11238, 11138 }, reforged = { 27265, 27266, 23300, 23635 } }, -- legs: callers_spats > callers_spats_+1 > callers_spats_+2 > beckoners_spats > beckoners_spats_+1 > beckoners_spats_+2 > beckoners_spats_+3
            { base = { 12102, 11258, 11158 }, reforged = { 27439, 27440, 23367, 23702 } }, -- feet: callers_pigaches > callers_pigaches_+1 > callers_pigaches_+2 > beckoners_pigaches > beckoners_pigaches_+1 > beckoners_pigaches_+2 > beckoners_pigaches_+3
        },
        BLU =
        {
            { base = { 12023, 11179, 11079 }, reforged = { 26770, 26771, 23100, 23435 } }, -- head: mavi_kavuk > mavi_kavuk_+1 > mavi_kavuk_+2 > hashishin_kavuk > hashishin_kavuk_+1 > hashishin_kavuk_+2 > hashishin_kavuk_+3
            { base = { 12043, 11199, 11099 }, reforged = { 26928, 26929, 23167, 23502 } }, -- body: mavi_mintan > mavi_mintan_+1 > mavi_mintan_+2 > hashishin_mintan > hashishin_mintan_+1 > hashishin_mintan_+2 > hashishin_mintan_+3
            { base = { 12063, 11219, 11119 }, reforged = { 27082, 27083, 23234, 23569 } }, -- hands: mavi_bazubands > mavi_bazubands_+1 > mavi_bazubands_+2 > hashishin_bazubands > hashishin_bazubands_+1 > hashishin_bazubands_+2 > hashishin_bazubands_+3
            { base = { 12083, 11239, 11139 }, reforged = { 27267, 27268, 23301, 23636 } }, -- legs: mavi_tayt > mavi_tayt_+1 > mavi_tayt_+2 > hashishin_tayt > hashishin_tayt_+1 > hashishin_tayt_+2 > hashishin_tayt_+3
            { base = { 12103, 11259, 11159 }, reforged = { 27441, 27442, 23368, 23703 } }, -- feet: mavi_basmak > mavi_basmak_+1 > mavi_basmak_+2 > hashishin_basmak > hashishin_basmak_+1 > hashishin_basmak_+2 > hashishin_basmak_+3
        },
        COR =
        {
            { base = { 12024, 11180, 11080 }, reforged = { 26772, 26773, 23101, 23436 } }, -- head: navarchs_tricorne > navarchs_tricorne_+1 > navarchs_tricorne_+2 > chasseurs_tricorne > chasseurs_tricorne_+1 > chasseurs_tricorne_+2 > chasseurs_tricorne_+3
            { base = { 12044, 11200, 11100 }, reforged = { 26930, 26931, 23168, 23503 } }, -- body: navarchs_frac > navarchs_frac_+1 > navarchs_frac_+2 > chasseurs_frac > chasseurs_frac_+1 > chasseurs_frac_+2 > chasseurs_frac_+3
            { base = { 12064, 11220, 11120 }, reforged = { 27084, 27085, 23235, 23570 } }, -- hands: navarchs_gants > navarchs_gants_+1 > navarchs_gants_+2 > chasseurs_gants > chasseurs_gants_+1 > chasseurs_gants_+2 > chasseurs_gants_+3
            { base = { 12084, 11240, 11140 }, reforged = { 27269, 27270, 23302, 23637 } }, -- legs: navarchs_culottes > navarchs_culottes_+1 > navarchs_culottes_+2 > chasseurs_culottes > chasseurs_culottes_+1 > chasseurs_culottes_+2 > chasseurs_culottes_+3
            { base = { 12104, 11260, 11160 }, reforged = { 27443, 27444, 23369, 23704 } }, -- feet: navarchs_bottes > navarchs_bottes_+1 > navarchs_bottes_+2 > chasseurs_bottes > chasseurs_bottes_+1 > chasseurs_bottes_+2 > chasseurs_bottes_+3
        },
        PUP =
        {
            { base = { 12025, 11181, 11081 }, reforged = { 26774, 26775, 23102, 23437 } }, -- head: cirque_cappello > cirque_cappello_+1 > cirque_cappello_+2 > karagoz_cappello > karagoz_cappello_+1 > karagoz_cappello_+2 > karagoz_cappello_+3
            { base = { 12045, 11201, 11101 }, reforged = { 26932, 26933, 23169, 23504 } }, -- body: cirque_farsetto > cirque_farsetto_+1 > cirque_farsetto_+2 > karagoz_farsetto > karagoz_farsetto_+1 > karagoz_farsetto_+2 > karagoz_farsetto_+3
            { base = { 12065, 11221, 11121 }, reforged = { 27086, 27087, 23236, 23571 } }, -- hands: cirque_guanti > cirque_guanti_+1 > cirque_guanti_+2 > karagoz_guanti > karagoz_guanti_+1 > karagoz_guanti_+2 > karagoz_guanti_+3
            { base = { 12085, 11241, 11141 }, reforged = { 27271, 27272, 23303, 23638 } }, -- legs: cirque_pantaloni > cirque_pantaloni_+1 > cirque_pantaloni_+2 > karagoz_pantaloni > karagoz_pantaloni_+1 > karagoz_pantaloni_+2 > karagoz_pantaloni_+3
            { base = { 12105, 11261, 11161 }, reforged = { 27445, 27446, 23370, 23705 } }, -- feet: cirque_scarpe > cirque_scarpe_+1 > cirque_scarpe_+2 > karagoz_scarpe > karagoz_scarpe_+1 > karagoz_scarpe_+2 > karagoz_scarpe_+3
        },
        DNC =
        {
            { base = { 12026, 11182, 11082 }, reforged = { 26776, 26777, 23103, 23438 } }, -- head: charis_tiara > charis_tiara_+1 > charis_tiara_+2 > maculele_tiara > maculele_tiara_+1 > maculele_tiara_+2 > maculele_tiara_+3
            { base = { 12046, 11202, 11102 }, reforged = { 26934, 26935, 23170, 23505 } }, -- body: charis_casaque > charis_casaque_+1 > charis_casaque_+2 > maculele_casaque > maculele_casaque_+1 > maculele_casaque_+2 > maculele_casaque_+3
            { base = { 12066, 11222, 11122 }, reforged = { 27088, 27089, 23237, 23572 } }, -- hands: charis_bangles > charis_bangles_+1 > charis_bangles_+2 > maculele_bangles > maculele_bangles_+1 > maculele_bangles_+2 > maculele_bangles_+3
            { base = { 12086, 11242, 11142 }, reforged = { 27273, 27274, 23304, 23639 } }, -- legs: charis_tights > charis_tights_+1 > charis_tights_+2 > maculele_tights > maculele_tights_+1 > maculele_tights_+2 > maculele_tights_+3
            { base = { 12106, 11262, 11162 }, reforged = { 27447, 27448, 23371, 23706 } }, -- feet: charis_toe_shoes > charis_toe_shoes_+1 > charis_toe_shoes_+2 > maculele_toe_shoes > maculele_toe_shoes_+1 > maculele_toe_shoes_+2 > maculele_toe_shoes_+3
        },
        SCH =
        {
            { base = { 12027, 11183, 11083 }, reforged = { 26778, 26779, 23104, 23439 } }, -- head: savants_bonnet > savants_bonnet_+1 > savants_bonnet_+2 > arbatel_bonnet > arbatel_bonnet_+1 > arbatel_bonnet_+2 > arbatel_bonnet_+3
            { base = { 12047, 11203, 11103 }, reforged = { 26936, 26937, 23171, 23506 } }, -- body: savants_gown > savants_gown_+1 > savants_gown_+2 > arbatel_gown > arbatel_gown_+1 > arbatel_gown_+2 > arbatel_gown_+3
            { base = { 12067, 11223, 11123 }, reforged = { 27090, 27091, 23238, 23573 } }, -- hands: savants_bracers > savants_bracers_+1 > savants_bracers_+2 > arbatel_bracers > arbatel_bracers_+1 > arbatel_bracers_+2 > arbatel_bracers_+3
            { base = { 12087, 11243, 11143 }, reforged = { 27275, 27276, 23305, 23640 } }, -- legs: savants_pants > savants_pants_+1 > savants_pants_+2 > arbatel_pants > arbatel_pants_+1 > arbatel_pants_+2 > arbatel_pants_+3
            { base = { 12107, 11263, 11163 }, reforged = { 27449, 27450, 23372, 23707 } }, -- feet: savants_loafers > savants_loafers_+1 > savants_loafers_+2 > arbatel_loafers > arbatel_loafers_+1 > arbatel_loafers_+2 > arbatel_loafers_+3
        },
        GEO =
        {
            { base = {  }, reforged = { 26780, 26781, 23105, 23440 } }, -- head: azimuth_hood > azimuth_hood_+1 > azimuth_hood_+2 > azimuth_hood_+3
            { base = {  }, reforged = { 26938, 26939, 23172, 23507 } }, -- body: azimuth_coat > azimuth_coat_+1 > azimuth_coat_+2 > azimuth_coat_+3
            { base = {  }, reforged = { 27092, 27093, 23239, 23574 } }, -- hands: azimuth_gloves > azimuth_gloves_+1 > azimuth_gloves_+2 > azimuth_gloves_+3
            { base = {  }, reforged = { 27277, 27278, 23306, 23641 } }, -- legs: azimuth_tights > azimuth_tights_+1 > azimuth_tights_+2 > azimuth_tights_+3
            { base = {  }, reforged = { 27451, 27452, 23373, 23708 } }, -- feet: azimuth_gaiters > azimuth_gaiters_+1 > azimuth_gaiters_+2 > azimuth_gaiters_+3
        },
        RUN =
        {
            { base = {  }, reforged = { 26782, 26783, 23106, 23441 } }, -- head: erilaz_galea > erilaz_galea_+1 > erilaz_galea_+2 > erilaz_galea_+3
            { base = {  }, reforged = { 26940, 26941, 23173, 23508 } }, -- body: erilaz_surcoat > erilaz_surcoat_+1 > erilaz_surcoat_+2 > erilaz_surcoat_+3
            { base = {  }, reforged = { 27094, 27095, 23240, 23575 } }, -- hands: erilaz_gauntlets > erilaz_gauntlets_+1 > erilaz_gauntlets_+2 > erilaz_gauntlets_+3
            { base = {  }, reforged = { 27279, 27280, 23307, 23642 } }, -- legs: erilaz_leg_guards > erilaz_leg_guards_+1 > erilaz_leg_guards_+2 > erilaz_leg_guards_+3
            { base = {  }, reforged = { 27453, 27454, 23374, 23709 } }, -- feet: erilaz_greaves > erilaz_greaves_+1 > erilaz_greaves_+2 > erilaz_greaves_+3
        },
    },
}

return config
