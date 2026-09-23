-----------------------------------
-- Beastmaster jug pets in the real engine: every jug pet is summoned, and every Ready move that
-- tools/custom/bst_jug_audit.py reports as wired up is used against a monster and must complete.
-- The pet list below is generated from that audit (regenerate it after changing jug pet data):
--   ~/lsb-venv/bin/python3 tools/custom/bst_jug_audit.py --json /tmp/jug.json
-- Pets whose Ready moves are all missing are listed with an empty move list: they must still spawn.
-----------------------------------

local jugPets =
{
    { petId =  21, pet = 'SheepFamiliar', jug = 'jug_of_herbal_broth', moves = { { 689, 'lamb_chop' }, { 690, 'rage' }, { 691, 'sheep_charge' }, { 692, 'sheep_song' } } },
    { petId =  22, pet = 'HareFamiliar', jug = 'jug_of_carrot_broth', moves = { { 672, 'foot_kick' }, { 673, 'dust_cloud' }, { 674, 'whirl_claws' }, { 735, 'wild_carrot' } } },
    { petId =  23, pet = 'CrabFamiliar', jug = 'jug_of_fish_broth', moves = { { 693, 'bubble_shower' }, { 694, 'bubble_curtain' }, { 695, 'big_scissors' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' } } },
    { petId =  24, pet = 'CourierCarrie', jug = 'jug_of_fish_oil_broth', moves = { { 693, 'bubble_shower' }, { 694, 'bubble_curtain' }, { 695, 'big_scissors' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' } } },
    { petId =  25, pet = 'Homunculus', jug = 'jug_of_alchemists_water', moves = { { 675, 'head_butt' }, { 676, 'dream_flower' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId =  26, pet = 'FlytrapFamiliar', jug = 'jug_of_grasshopper_broth', moves = { { 718, 'soporific' }, { 719, 'gloeosuccus' }, { 720, 'palsy_pollen' } } },
    { petId =  27, pet = 'TigerFamiliar', jug = 'jug_of_meat_broth', moves = { { 680, 'roar' }, { 681, 'razor_fang' }, { 682, 'claw_cyclone' }, { 795, 'crossthrash' }, { 796, 'predatory_glare' } } },
    { petId =  28, pet = 'FlowerpotBill', jug = 'jug_of_humus', moves = { { 675, 'head_butt' }, { 676, 'dream_flower' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId =  29, pet = 'EftFamiliar', jug = 'jug_of_mole_broth', moves = { { 721, 'geist_wall' }, { 722, 'numbing_noise' }, { 723, 'nimble_snap' }, { 724, 'cyclotail' }, { 725, 'toxic_spit' } } },
    { petId =  30, pet = 'LizardFamiliar', jug = 'jug_of_carrion_broth', moves = { { 683, 'tail_blow' }, { 684, 'fireball' }, { 685, 'blockhead' }, { 686, 'brain_crush' }, { 687, 'infrasonics' }, { 688, 'secretion' } } },
    { petId =  31, pet = 'MayflyFamiliar', jug = 'jug_of_bug_broth', moves = { { 712, 'cursed_sphere' }, { 713, 'venom' }, { 772, 'somersault' } } },
    { petId =  32, pet = 'FunguarFamiliar', jug = 'jug_of_seedbed_soil', moves = { { 700, 'frogkick' }, { 701, 'spore' }, { 702, 'queasyshroom' }, { 703, 'numbshroom' }, { 704, 'shakeshroom' }, { 705, 'silence_gas' }, { 706, 'dark_spore' } } },
    { petId =  33, pet = 'BeetleFamiliar', jug = 'jug_of_tree_sap', moves = { { 707, 'power_attack' }, { 708, 'hi-freq_field' }, { 709, 'rhino_attack' }, { 710, 'rhino_guard' }, { 711, 'spoil' } } },
    { petId =  34, pet = 'AntlionFamiliar', jug = 'jug_of_antica_broth', moves = { { 714, 'sandblast' }, { 715, 'sandpit' }, { 716, 'venom_spray' }, { 717, 'mandibular_bite' } } },
    { petId =  35, pet = 'MiteFamiliar', jug = 'jug_of_blood_broth', moves = { { 726, 'double_claw' }, { 727, 'grapple' }, { 728, 'spinning_top' }, { 729, 'filamented_hold' } } },
    { petId =  36, pet = 'LullabyMelodia', jug = 'jug_of_singing_herbal_broth', moves = { { 689, 'lamb_chop' }, { 690, 'rage' }, { 691, 'sheep_charge' }, { 692, 'sheep_song' } } },
    { petId =  37, pet = 'KeenearedSteffi', jug = 'jug_of_famous_carrot_broth', moves = { { 672, 'foot_kick' }, { 673, 'dust_cloud' }, { 674, 'whirl_claws' }, { 735, 'wild_carrot' } } },
    { petId =  38, pet = 'FlowerpotBen', jug = 'jug_of_rich_humus', moves = { { 675, 'head_butt' }, { 676, 'dream_flower' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId =  39, pet = 'SaberSiravarde', jug = 'jug_of_warm_meat_broth', moves = { { 680, 'roar' }, { 681, 'razor_fang' }, { 682, 'claw_cyclone' }, { 795, 'crossthrash' }, { 796, 'predatory_glare' } } },
    { petId =  40, pet = 'ColdbloodComo', jug = 'jug_of_cold_carrion_broth', moves = { { 683, 'tail_blow' }, { 684, 'fireball' }, { 685, 'blockhead' }, { 686, 'brain_crush' }, { 687, 'infrasonics' }, { 688, 'secretion' } } },
    { petId =  41, pet = 'ShellbusterOrob', jug = 'jug_of_quadav_bug_broth', moves = { { 712, 'cursed_sphere' }, { 713, 'venom' }, { 772, 'somersault' } } },
    { petId =  42, pet = 'VoraciousAudrey', jug = 'jug_of_noisy_grasshopper_broth', moves = { { 718, 'soporific' }, { 719, 'gloeosuccus' }, { 720, 'palsy_pollen' } } },
    { petId =  43, pet = 'AmbusherAllie', jug = 'jug_of_lively_mole_broth', moves = { { 721, 'geist_wall' }, { 722, 'numbing_noise' }, { 723, 'nimble_snap' }, { 724, 'cyclotail' }, { 725, 'toxic_spit' } } },
    { petId =  44, pet = 'LifedrinkerLars', jug = 'jug_of_clear_blood_broth', moves = { { 726, 'double_claw' }, { 727, 'grapple' }, { 728, 'spinning_top' }, { 729, 'filamented_hold' } } },
    { petId =  45, pet = 'PanzerGalahad', jug = 'jug_of_scarlet_sap', moves = { { 707, 'power_attack' }, { 708, 'hi-freq_field' }, { 709, 'rhino_attack' }, { 710, 'rhino_guard' }, { 711, 'spoil' } } },
    { petId =  46, pet = 'ChopsueyChucky', jug = 'jug_of_fragrant_antica_broth', moves = { { 714, 'sandblast' }, { 715, 'sandpit' }, { 716, 'venom_spray' }, { 717, 'mandibular_bite' } } },
    { petId =  47, pet = 'AmigoSabotender', jug = 'jug_of_sun_water', moves = { { 698, 'needleshot' }, { 699, 'random_needles' } } },
    { petId =  49, pet = 'CraftyClyvonne', jug = 'jug_of_cunning_brain_broth', moves = { { 730, 'chaotic_eye' }, { 731, 'blaster' } } },
    { petId =  50, pet = 'BloodclawShasr', jug = 'jug_of_razor_brain_broth', moves = { { 730, 'chaotic_eye' }, { 731, 'blaster' }, { 746, 'charged_whisker' }, { 790, 'frenzied_rage' } } },
    { petId =  51, pet = 'LuckyLulush', jug = 'jug_of_lucky_carrot_broth', moves = { { 672, 'foot_kick' }, { 674, 'whirl_claws' }, { 734, 'snow_cloud' }, { 735, 'wild_carrot' } } },
    { petId =  52, pet = 'FatsoFargann', jug = 'jug_of_curdled_plasma_broth', moves = { { 732, 'suction' }, { 733, 'drainkiss' }, { 740, 'acid_mist' }, { 741, 'tp_drainkiss' } } },
    { petId =  53, pet = 'DiscreetLouise', jug = 'jug_of_deepbed_soil', moves = { { 700, 'frogkick' }, { 701, 'spore' }, { 702, 'queasyshroom' }, { 703, 'numbshroom' }, { 704, 'shakeshroom' }, { 705, 'silence_gas' }, { 706, 'dark_spore' } } },
    { petId =  54, pet = 'SwiftSieghard', jug = 'jug_of_mellow_bird_broth', moves = { { 743, 'scythe_tail' }, { 744, 'ripper_fang' }, { 745, 'chomp_rush' } } },
    { petId =  55, pet = 'DipperYuly', jug = 'jug_of_wool_grease', moves = { { 736, 'sudden_lunge' }, { 737, 'spiral_spin' }, { 738, 'noisome_powder' } } },
    { petId =  56, pet = 'FlowerpotMerle', jug = 'jug_of_vermihumus', moves = { { 675, 'head_butt' }, { 676, 'dream_flower' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId =  57, pet = 'NurseryNazuna', jug = 'jug_of_dancing_herbal_broth', moves = { { 689, 'lamb_chop' }, { 690, 'rage' }, { 691, 'sheep_charge' }, { 692, 'sheep_song' } } },
    { petId =  58, pet = 'MailbusterCeta', jug = 'jug_of_goblin_bug_broth', moves = { { 712, 'cursed_sphere' }, { 713, 'venom' }, { 772, 'somersault' } } },
    { petId =  59, pet = 'AudaciousAnna', jug = 'jug_of_bubbling_carrion_broth', moves = { { 683, 'tail_blow' }, { 684, 'fireball' }, { 685, 'blockhead' }, { 686, 'brain_crush' }, { 687, 'infrasonics' }, { 688, 'secretion' } } },
    { petId =  60, pet = 'PrestoJulio', jug = 'jug_of_chirping_grasshopper_broth', moves = { { 718, 'soporific' }, { 719, 'gloeosuccus' }, { 720, 'palsy_pollen' } } },
    { petId =  61, pet = 'BugeyedBroncha', jug = 'jug_of_savage_mole_broth', moves = { { 721, 'geist_wall' }, { 722, 'numbing_noise' }, { 723, 'nimble_snap' }, { 724, 'cyclotail' }, { 725, 'toxic_spit' } } },
    { petId =  62, pet = 'GooeyGerard', jug = 'jug_of_cloudy_wheat_broth', moves = { { 747, 'purulent_ooze' }, { 748, 'corrosive_ooze' } } },
    { petId =  63, pet = 'GorefangHobs', jug = 'jug_of_burning_carrion_broth', moves = { { 680, 'roar' }, { 681, 'razor_fang' }, { 682, 'claw_cyclone' }, { 795, 'crossthrash' }, { 796, 'predatory_glare' } } },
    { petId =  64, pet = 'FaithfulFalcor', jug = 'jug_of_lucky_broth', moves = { { 749, 'back_heel' }, { 750, 'jettatura' }, { 751, 'choke_breath' }, { 752, 'fantod' }, { 797, 'hoof_volley' }, { 798, 'nihility_song' } } },
    { petId =  65, pet = 'CrudeRaphie', jug = 'jug_of_shadowy_broth', moves = { { 753, 'tortoise_stomp' }, { 754, 'harden_shell' }, { 755, 'aqua_breath' } } },
    { petId =  66, pet = 'DapperMac', jug = 'jug_of_briny_broth', moves = { { 756, 'wing_slap' }, { 757, 'beak_lunge' } } },
    { petId =  67, pet = 'SlipperySilas', jug = 'jug_of_wormy_broth', moves = {  } },
    { petId =  68, pet = 'TurbidToloi', jug = 'jug_of_auroral_broth', moves = { { 758, 'intimidate' }, { 759, 'recoil_dive' }, { 760, 'water_wall' } } },
    { petId =  77, pet = 'SweetCaroline', jug = 'jug_of_aged_humus', moves = { { 675, 'head_butt' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId =  78, pet = 'AmiableRoche', jug = 'jug_of_airy_broth', moves = { { 758, 'intimidate' }, { 759, 'recoil_dive' }, { 760, 'water_wall' } } },
    { petId =  79, pet = 'HeadbreakerKen', jug = 'jug_of_blackwater_broth', moves = { { 712, 'cursed_sphere' }, { 713, 'venom' }, { 772, 'somersault' } } },
    { petId =  80, pet = 'AnklebiterJedd', jug = 'jug_of_crackling_broth', moves = { { 726, 'double_claw' }, { 727, 'grapple' }, { 728, 'spinning_top' }, { 729, 'filamented_hold' } } },
    { petId =  81, pet = 'CursedAnnabelle', jug = 'jug_of_creepy_broth', moves = { { 714, 'sandblast' }, { 715, 'sandpit' }, { 716, 'venom_spray' }, { 717, 'mandibular_bite' } } },
    { petId =  82, pet = 'BrainyWaluis', jug = 'handful_of_crumbly_soil', moves = { { 700, 'frogkick' }, { 701, 'spore' }, { 702, 'queasyshroom' }, { 703, 'numbshroom' }, { 704, 'shakeshroom' }, { 705, 'silence_gas' }, { 706, 'dark_spore' } } },
    { petId =  83, pet = 'SlimeFamiliar', jug = 'jug_of_decaying_broth', moves = { { 792, 'fluid_toss' }, { 793, 'fluid_spread' }, { 794, 'digest' } } },
    { petId =  84, pet = 'SultryPatrice', jug = 'jug_of_putrescent_broth', moves = { { 792, 'fluid_toss' }, { 793, 'fluid_spread' }, { 794, 'digest' } } },
    { petId =  85, pet = 'GenerousArthur', jug = 'jug_of_dire_broth', moves = { { 747, 'purulent_ooze' }, { 748, 'corrosive_ooze' } } },
    { petId =  86, pet = 'RedolentCandi', jug = 'jug_of_electrified_broth', moves = { { 768, 'tickling_tendrils' }, { 769, 'stink_bomb' }, { 770, 'nectarous_deluge' }, { 771, 'nepenthic_plunge' } } },
    { petId =  87, pet = 'AlluringHoney', jug = 'jug_of_bug-ridden_broth', moves = { { 768, 'tickling_tendrils' }, { 769, 'stink_bomb' }, { 770, 'nectarous_deluge' }, { 771, 'nepenthic_plunge' } } },
    { petId =  88, pet = 'LynxFamiliar', jug = 'jug_of_frizzante_broth', moves = { { 730, 'chaotic_eye' }, { 731, 'blaster' }, { 746, 'charged_whisker' }, { 790, 'frenzied_rage' } } },
    { petId =  89, pet = 'VivaciousGaston', jug = 'jug_of_spumante_broth', moves = { { 730, 'chaotic_eye' }, { 731, 'blaster' }, { 746, 'charged_whisker' }, { 790, 'frenzied_rage' } } },
    { petId =  90, pet = 'CaringKiyomaro', jug = 'jug_of_fizzy_broth', moves = { { 765, 'sweeping_gouge' }, { 766, 'zealous_snort' } } },
    { petId =  91, pet = 'VivaciousVickie', jug = 'jug_of_tantalizing_broth', moves = { { 765, 'sweeping_gouge' }, { 766, 'zealous_snort' } } },
    { petId =  92, pet = 'SuspiciousAlice', jug = 'jug_of_furious_broth', moves = { { 721, 'geist_wall' }, { 722, 'numbing_noise' }, { 723, 'nimble_snap' }, { 724, 'cyclotail' }, { 725, 'toxic_spit' } } },
    { petId =  93, pet = 'SurgingStorm', jug = 'jug_of_insipid_broth', moves = { { 756, 'wing_slap' }, { 757, 'beak_lunge' } } },
    { petId =  94, pet = 'SubmergedIyo', jug = 'jug_of_deepwater_broth', moves = { { 756, 'wing_slap' }, { 757, 'beak_lunge' } } },
    { petId =  95, pet = 'WarlikePatrick', jug = 'jug_of_livid_broth', moves = { { 683, 'tail_blow' }, { 684, 'fireball' }, { 685, 'blockhead' }, { 686, 'brain_crush' }, { 687, 'infrasonics' }, { 688, 'secretion' } } },
    { petId =  96, pet = 'RhymingShizuna', jug = 'jug_of_lyrical_broth', moves = { { 689, 'lamb_chop' }, { 690, 'rage' }, { 691, 'sheep_charge' }, { 692, 'sheep_song' } } },
    { petId =  97, pet = 'BlackbeardRandy', jug = 'jug_of_meaty_broth', moves = { { 680, 'roar' }, { 681, 'razor_fang' }, { 682, 'claw_cyclone' }, { 795, 'crossthrash' }, { 796, 'predatory_glare' } } },
    { petId =  98, pet = 'ThreestarLynn', jug = 'jug_of_muddy_broth', moves = { { 736, 'sudden_lunge' }, { 737, 'spiral_spin' }, { 738, 'noisome_powder' } } },
    { petId =  99, pet = 'HurlerPercival', jug = 'jug_of_pale_sap', moves = { { 707, 'power_attack' }, { 708, 'hi-freq_field' }, { 709, 'rhino_attack' }, { 710, 'rhino_guard' }, { 711, 'spoil' } } },
    { petId = 100, pet = 'AcuexFamiliar', jug = 'jug_of_poisonous_broth', moves = { { 774, 'foul_waters' }, { 775, 'pestilent_plume' } } },
    { petId = 101, pet = 'FluffyBredo', jug = 'jug_of_venomous_broth', moves = { { 774, 'foul_waters' }, { 775, 'pestilent_plume' } } },
    { petId = 102, pet = 'WeevilFamiliar', jug = 'jug_of_pristine_sap', moves = { { 786, 'disembowel' }, { 787, 'extirpating_salvo' } } },
    { petId = 103, pet = 'StalwartAngelin', jug = 'jug_of_truly_pristine_sap', moves = { { 786, 'disembowel' }, { 787, 'extirpating_salvo' } } },
    { petId = 104, pet = 'FleetReinhard', jug = 'jug_of_rapid_broth', moves = { { 743, 'scythe_tail' }, { 744, 'ripper_fang' }, { 745, 'chomp_rush' } } },
    { petId = 105, pet = 'SharpwitHermes', jug = 'jug_of_saline_broth', moves = { { 675, 'head_butt' }, { 676, 'dream_flower' }, { 677, 'wild_oats' }, { 678, 'leaf_dagger' }, { 679, 'scream' } } },
    { petId = 106, pet = 'P.CrabFamiliar', jug = 'jug_of_rancid_broth', moves = { { 694, 'bubble_curtain' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' }, { 788, 'venom_shower' }, { 789, 'mega_scissors' } } },
    { petId = 107, pet = 'JovialEdwin', jug = 'jug_of_pungent_broth', moves = { { 694, 'bubble_curtain' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' }, { 788, 'venom_shower' }, { 789, 'mega_scissors' } } },
    { petId = 108, pet = 'AttentiveIbuki', jug = 'jug_of_salubrious_broth', moves = { { 763, 'molting_plumage' }, { 764, 'swooping_frenzy' }, { 767, 'pentapeck' } } },
    { petId = 109, pet = 'SwoopingZhivago', jug = 'handful_of_windy_greens', moves = { { 763, 'molting_plumage' }, { 764, 'swooping_frenzy' }, { 767, 'pentapeck' } } },
    { petId = 110, pet = 'SunburstMalfik', jug = 'jug_of_shimmering_broth', moves = { { 693, 'bubble_shower' }, { 694, 'bubble_curtain' }, { 695, 'big_scissors' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' } } },
    { petId = 111, pet = 'AgedAngus', jug = 'jug_of_fermented_broth', moves = { { 693, 'bubble_shower' }, { 694, 'bubble_curtain' }, { 695, 'big_scissors' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' } } },
    { petId = 112, pet = 'ScissorlegXerin', jug = 'jug_of_spicy_broth', moves = { { 761, 'sensilla_blades' }, { 762, 'tegmina_buffet' } } },
    { petId = 113, pet = 'BouncingBertha', jug = 'jug_of_bubbly_broth', moves = { { 761, 'sensilla_blades' }, { 762, 'tegmina_buffet' } } },
    { petId = 114, pet = 'SpiderFamiliar', jug = 'sticky_webbing', moves = { { 777, 'sickle_slash' }, { 778, 'acid_spray' }, { 779, 'spider_web' } } },
    { petId = 115, pet = 'GussyHachirobe', jug = 'slimy_webbing', moves = { { 777, 'sickle_slash' }, { 778, 'acid_spray' }, { 779, 'spider_web' } } },
    { petId = 116, pet = 'ColibriFamiliar', jug = 'jug_of_sugary_broth', moves = { { 776, 'pecking_flurry' } } },
    { petId = 117, pet = 'ChoralLeera', jug = 'jug_of_glazed_broth', moves = { { 776, 'pecking_flurry' } } },
    { petId = 118, pet = 'DroopyDortwin', jug = 'jug_of_swirling_broth', moves = { { 672, 'foot_kick' }, { 673, 'dust_cloud' }, { 674, 'whirl_claws' }, { 735, 'wild_carrot' } } },
    { petId = 119, pet = 'PonderingPeter', jug = 'jug_of_viscous_broth', moves = { { 672, 'foot_kick' }, { 673, 'dust_cloud' }, { 674, 'whirl_claws' }, { 735, 'wild_carrot' } } },
    { petId = 120, pet = 'HeraldHenry', jug = 'jug_of_translucent_broth', moves = { { 693, 'bubble_shower' }, { 694, 'bubble_curtain' }, { 695, 'big_scissors' }, { 696, 'scissor_guard' }, { 697, 'metallic_body' } } },
    { petId = 121, pet = 'Hip.Familiar', jug = 'jug_of_turpid_broth', moves = { { 749, 'back_heel' }, { 750, 'jettatura' }, { 751, 'choke_breath' }, { 752, 'fantod' }, { 797, 'hoof_volley' }, { 798, 'nihility_song' } } },
    { petId = 122, pet = 'DaringRoland', jug = 'jug_of_feculent_broth', moves = { { 749, 'back_heel' }, { 750, 'jettatura' }, { 751, 'choke_breath' }, { 752, 'fantod' }, { 797, 'hoof_volley' }, { 798, 'nihility_song' } } },
    { petId = 123, pet = 'MosquitoFamilia', jug = 'jug_of_wetlands_broth', moves = { { 781, 'infected_leech' }, { 782, 'gloom_spray' } } },
    { petId = 124, pet = 'Left-HandedYoko', jug = 'jug_of_heavenly_broth', moves = { { 781, 'infected_leech' }, { 782, 'gloom_spray' } } },
    { petId = 125, pet = 'BraveHeroGlenn', jug = 'jug_of_wispy_broth', moves = {  } },
    { petId = 126, pet = 'Y.BeetleFamilia', jug = 'jug_of_zestful_sap', moves = { { 707, 'power_attack' }, { 708, 'hi-freq_field' }, { 709, 'rhino_attack' }, { 710, 'rhino_guard' }, { 711, 'spoil' }, { 791, 'rhinowrecker' } } },
    { petId = 127, pet = 'EnergizedSefina', jug = 'jug_of_gassy_sap', moves = { { 707, 'power_attack' }, { 708, 'hi-freq_field' }, { 709, 'rhino_attack' }, { 710, 'rhino_guard' }, { 711, 'spoil' }, { 791, 'rhinowrecker' } } },
}

describe('BST jug pets', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BST, level = 99 })
        player:setUnkillable(true)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        -- respawn() puts the rabbit back at its spawn point, which can be far away: stand next to it again
        player:setPos(mob:getXPos() + 1, mob:getYPos(), mob:getZPos())
    end)

    it('Call Beast with a jug in the ammo slot summons its pet and uses up one jug', function()
        player:addItem(xi.item.JUG_OF_HERBAL_BROTH, 2)
        player:equipItem(xi.item.JUG_OF_HERBAL_BROTH, nil, xi.slot.AMMO)

        player.actions:useAbility(player, xi.jobAbility.CALL_BEAST)
        xi.test.world:skipTime(3)

        local pet = player:getPet()
        assert(pet, 'Call Beast did not summon a pet')
        assert(pet:getPetID() == xi.petId.SHEEP_FAMILIAR, 'wrong pet: ' .. tostring(pet:getPetID()))
        assert(player:getItemCount(xi.item.JUG_OF_HERBAL_BROTH) == 1, 'the jug was not used up')
    end)

    for _, entry in ipairs(jugPets) do
        it(string.format('%s (%s): spawns and every wired Ready move completes', entry.pet, entry.jug), function()
            player:spawnPet(entry.petId)
            local pet = player:getPet()
            assert(pet, 'the pet did not spawn')

            -- Only Ready moves are wanted here; auto-attacks could kill or disturb the target
            pet:setAutoAttackEnabled(false)

            local completed = {}
            pet:addListener('WEAPONSKILL_STATE_EXIT', 'TEST_READY', function(entity, skillId, wasCompleted)
                if wasCompleted then
                    table.insert(completed, skillId)
                end
            end)

            pet:engage(mob:getTargID())
            xi.test.world:tickEntity(pet)
            xi.test.world:skipTime(5)

            local failed = {}

            for _, move in ipairs(entry.moves) do
                xi.test.world:skipTime(100) -- refill all Ready charges (30 s each, up to 3)
                -- Ready has a short range from the Beastmaster: stand by the pet, as a player would
                player:setPos(pet:getXPos() + 1, pet:getYPos(), pet:getZPos())
                local before = #completed
                player.actions:useAbility(player, move[1])

                for _ = 1, 6 do
                    xi.test.world:skipTime(2)
                    xi.test.world:tickEntity(pet)
                end

                if #completed == before then
                    table.insert(failed, move[2])
                end
            end

            assert(#failed == 0, entry.pet .. ': Ready moves that did not complete: ' .. table.concat(failed, ', '))
        end)
    end
end)
