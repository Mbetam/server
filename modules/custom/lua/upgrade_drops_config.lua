-----------------------------------
-- Upgrade material drops: where the Armor Upgrader's materials drop when their retail content is not in LSB (Omen, Escha,
-- Sortie, Geas Fete, Voidwatch). Not a module (loaded by require); upgrade_drops.lua adds them to the kill's loot.
-- Eric's choice (2026-09-26): Paragon cards, Omen items and scales from Limbus, Sky, Sea, ZNMs and Dynamis Lord; Escha
-- items from Abyssea NMs; Ra'Kazarch Sapphire / Starstone from HNMs and the big bosses. Voidwatch shards and void pieces
-- (Relic +2 / +3) and Geas Fete items (Relic +1 / +2) go to Dynamis, the home of Relic armor, and the HNMs.
-- Job items (cards, shards, void pieces) are for the killer's main job, so a solo player farms their own job.
-- Rates are xi.drop_rate values: RARE 5%, UNCOMMON 10%, COMMON 15%, VERY_COMMON 24%, GUARANTEED 100% (before the
-- server's drop multiplier). Everything here is tunable.
-----------------------------------
local config = {}

-- Item ids that depend on the job: id = base + job id (xi.job.WAR = 1 ... RUN = 22)
config.jobBase =
{
    card  = 9280, -- paragon_warrior_card (9281) ... paragon_rune_fencer_card (9302)
    shard = { 9543, 9587, 9631, 9675, 9719 }, -- headshard_war (9544), torsoshard, handshard, legshard, footshard
    void  = { 9565, 9609, 9653, 9697, 9741 }, -- piece_of_void_headwear_war (9566), torso, pair of handwear, legwear, pair of footwear
}

-- Groups of items that drop as "one of these"
config.groups =
{
    -- Reforged Artifact +2 slot items (Omen bosses in retail)
    omenItems =
    {
        8983, -- emperor_arthros_shell (head)
        8986, -- clump_of_joyous_greens_moss (body)
        8979, -- valkurm_imperators_wing (hands)
        8988, -- warblade_beaks_hide (legs)
        8981, -- abyssdivers_feather (feet)
    },
    -- Reforged Artifact +3 job ingredients (Omen in retail)
    omenScales =
    {
        9303, -- kins_scale
        9304, -- gins_scale
        9305, -- keis_scale
        9306, -- kyous_scale
        9307, -- fus_scale
    },
    -- Reforged Empyrean +1 and Reforged Relic +3 slot items (Escha in retail)
    eschaItems =
    {
        9007, -- vial_of_defiant_sweat
        9062, -- chunk_of_dark_matter
        9005, -- macuil_horn
        9064, -- tartarian_chain
        9002, -- vial_of_plovid_effluvium
        9006, -- defiant_scarf
        9061, -- hades_claw
        9004, -- macuil_plating
        9063, -- tartarian_soul
        9003, -- chunk_of_plovid_flesh
    },
    -- Reforged Relic +1 / +2 slot items and Reforged Relic +1 job ingredients (Geas Fete in retail)
    geasItems =
    {
        3977, -- gabbrath_horn
        4014, -- yggdreant_bole
        3980, -- bztavian_stinger
        4012, -- waktza_rostrum
        3979, -- rockfin_tooth
        3447, -- voidwrought_plate
        3492, -- kaggens_cuticle
        3491, -- akvans_pennon
        3490, -- pils_tuille
        3445, -- suit_of_hahavas_mail
        3449, -- celaenos_cloth
    },
}

config.item =
{
    sapphire  = 9927, -- rakaznar_sapphire (Reforged Empyrean +2)
    starstone = 9928, -- rakaznar_starstone (Reforged Empyrean +3)
}

-- What each kind of source drops. { what, rate, quantity }: 'card' / 'shard' / 'void' are the killer's job item (shard and
-- void of a random slot), a group name drops one item of that group, an item key drops that item.
config.tiers =
{
    omenBoss =
    {
        { 'card', xi.drop_rate.GUARANTEED, 3 },
        { 'omenItems', xi.drop_rate.VERY_COMMON },
        { 'omenScales', xi.drop_rate.VERY_COMMON },
    },
    omenNM =
    {
        { 'card', xi.drop_rate.VERY_COMMON },
        { 'omenItems', xi.drop_rate.UNCOMMON },
        { 'omenScales', xi.drop_rate.UNCOMMON },
    },
    abysseaNM =
    {
        { 'eschaItems', xi.drop_rate.COMMON },
    },
    bigBoss = -- HNMs, Sky and Sea gods, Abyssea's hero NMs, Shinryu
    {
        { 'sapphire', xi.drop_rate.VERY_COMMON },
        { 'starstone', xi.drop_rate.COMMON },
        { 'eschaItems', xi.drop_rate.VERY_COMMON },
        { 'geasItems', xi.drop_rate.VERY_COMMON },
    },
    dynamisNM =
    {
        { 'shard', xi.drop_rate.COMMON },
        { 'void', xi.drop_rate.RARE },
        { 'geasItems', xi.drop_rate.UNCOMMON },
    },
    dynamisLord = -- Dynamis Lord and the zone megabosses
    {
        { 'shard', xi.drop_rate.GUARANTEED, 2 },
        { 'void', xi.drop_rate.VERY_COMMON },
        { 'geasItems', xi.drop_rate.VERY_COMMON },
    },
}

-- Whole zones: every notorious monster (mob:isNM()) in them is a source
config.zones =
{
    [xi.zone.TEMENOS]                  = { 'omenNM' },
    [xi.zone.APOLLYON]                 = { 'omenNM' },
    [xi.zone.ABYSSEA_KONSCHTAT]        = { 'abysseaNM' },
    [xi.zone.ABYSSEA_TAHRONGI]         = { 'abysseaNM' },
    [xi.zone.ABYSSEA_LA_THEINE]        = { 'abysseaNM' },
    [xi.zone.ABYSSEA_ATTOHWA]          = { 'abysseaNM' },
    [xi.zone.ABYSSEA_MISAREAUX]        = { 'abysseaNM' },
    [xi.zone.ABYSSEA_VUNKERL]          = { 'abysseaNM' },
    [xi.zone.ABYSSEA_ALTEPA]           = { 'abysseaNM' },
    [xi.zone.ABYSSEA_ULEGUERAND]       = { 'abysseaNM' },
    [xi.zone.ABYSSEA_GRAUBERG]         = { 'abysseaNM' },
    [xi.zone.ABYSSEA_EMPYREAL_PARADOX] = { 'abysseaNM' },
    [xi.zone.DYNAMIS_SAN_DORIA]        = { 'dynamisNM' },
    [xi.zone.DYNAMIS_BASTOK]           = { 'dynamisNM' },
    [xi.zone.DYNAMIS_WINDURST]         = { 'dynamisNM' },
    [xi.zone.DYNAMIS_JEUNO]            = { 'dynamisNM' },
    [xi.zone.DYNAMIS_BEAUCEDINE]       = { 'dynamisNM' },
    [xi.zone.DYNAMIS_XARCABARD]        = { 'dynamisNM' },
    [xi.zone.DYNAMIS_VALKURM]          = { 'dynamisNM' },
    [xi.zone.DYNAMIS_BUBURIMU]         = { 'dynamisNM' },
    [xi.zone.DYNAMIS_QUFIM]            = { 'dynamisNM' },
    [xi.zone.DYNAMIS_TAVNAZIA]         = { 'dynamisNM' },
}

-- Named monsters by zone (so their copies in Nyzul Isle or Salvage do not count), on top of their zone's tier.
-- Abyssea's hero NMs (the ones whose items make Reforged Empyrean armor) and Shinryu are big bosses.
config.named =
{
    [xi.zone.APOLLYON] =
    {
        Omega_Forerunner = { 'omenBoss' }, -- Limbus boss
    },
    [xi.zone.TEMENOS] =
    {
        Ultima_Forerunner = { 'omenBoss' }, -- Limbus boss
    },
    [xi.zone.RUAUN_GARDENS] =
    {
        Byakko                   = { 'omenBoss', 'bigBoss' }, -- Sky god
        Genbu                    = { 'omenBoss', 'bigBoss' }, -- Sky god
        Seiryu                   = { 'omenBoss', 'bigBoss' }, -- Sky god
        Suzaku                   = { 'omenBoss', 'bigBoss' }, -- Sky god
        Kirin_Strange_Happenings = { 'omenBoss', 'bigBoss' }, -- Sky god
    },
    [xi.zone.ALTAIEU] =
    {
        Jailer_of_Hope     = { 'omenBoss', 'bigBoss' }, -- Sea
        Jailer_of_Justice  = { 'omenBoss', 'bigBoss' }, -- Sea
        Jailer_of_Love     = { 'omenBoss', 'bigBoss' }, -- Sea
        Jailer_of_Prudence = { 'omenBoss', 'bigBoss' }, -- Sea
        Absolute_Virtue    = { 'omenBoss', 'bigBoss' }, -- Sea
    },
    [xi.zone.GRAND_PALACE_OF_HUXZOI] =
    {
        Jailer_of_Temperance = { 'omenBoss', 'bigBoss' }, -- Sea
    },
    [xi.zone.THE_GARDEN_OF_RUHMET] =
    {
        Jailer_of_Faith     = { 'omenBoss', 'bigBoss' }, -- Sea
        Jailer_of_Fortitude = { 'omenBoss', 'bigBoss' }, -- Sea
    },
    [xi.zone.WAJAOM_WOODLANDS] =
    {
        Tinnin                 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Vulpangue              = { 'omenNM'              }, -- ZNM
        Gotoh_Zha_the_Redolent = { 'omenNM'              }, -- ZNM
        Iriz_Ima               = { 'omenNM'              }, -- ZNM
        Hydra                  = { 'bigBoss'             }, -- HNM
    },
    [xi.zone.MOUNT_ZHAYOLM] =
    {
        Sarameya              = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Anantaboga            = { 'omenNM'              }, -- ZNM
        Brass_Borer           = { 'omenNM'              }, -- ZNM
        Claret                = { 'omenNM'              }, -- ZNM
        Khromasoul_Bhurborlor = { 'omenNM'              }, -- ZNM
        Cerberus              = { 'bigBoss'             }, -- HNM
    },
    [xi.zone.CAEDARVA_MIRE] =
    {
        Tyger                 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Mahjlaef_the_Paintorn = { 'omenNM'              }, -- ZNM
        Experimental_Lamia    = { 'omenNM'              }, -- ZNM
        Khimaira              = { 'bigBoss'             }, -- HNM
    },
    [xi.zone.AYDEEWA_SUBTERRANE] =
    {
        Pandemonium_Warden   = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_2 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_3 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_4 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_5 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_6 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Pandemonium_Warden_7 = { 'omenBoss', 'bigBoss' }, -- ZNM T4
        Nosferatu            = { 'omenNM'              }, -- ZNM
        Chigre               = { 'omenNM'              }, -- ZNM
    },
    [xi.zone.MAMOOK] =
    {
        Chamrosh               = { 'omenNM' }, -- ZNM
        Iriri_Samariri         = { 'omenNM' }, -- ZNM
        Hundredfaced_Hapool_Ja = { 'omenNM' }, -- ZNM
    },
    [xi.zone.HALVUNG] =
    {
        Dextrose = { 'omenNM' }, -- ZNM
        Achamoth = { 'omenNM' }, -- ZNM
    },
    [xi.zone.ARRAPAGO_REEF] =
    {
        Lil_Apkallu           = { 'omenNM' }, -- ZNM
        Velionis              = { 'omenNM' }, -- ZNM
        Zareehkl_the_Jubilant = { 'omenNM' }, -- ZNM
        Bloody_Bones          = { 'omenNM' }, -- ZNM
    },
    [xi.zone.ALZADAAL_UNDERSEA_RUINS] =
    {
        Wulgaru                 = { 'omenNM' }, -- ZNM
        Armed_Gears             = { 'omenNM' }, -- ZNM
        Cheese_Hoarder_Gigiroon = { 'omenNM' }, -- ZNM
    },
    [xi.zone.BHAFLAU_THICKETS] =
    {
        Dea                = { 'omenNM' }, -- ZNM
        Lividroot_Amooshah = { 'omenNM' }, -- ZNM
    },
    [xi.zone.ATTOHWA_CHASM] =
    {
        Tiamat = { 'bigBoss' }, -- HNM
    },
    [xi.zone.ULEGUERAND_RANGE] =
    {
        Jormungand = { 'bigBoss' }, -- HNM
    },
    [xi.zone.KING_RANPERRES_TOMB] =
    {
        Vrtra = { 'bigBoss' }, -- HNM
    },
    [xi.zone.DRAGONS_AERY] =
    {
        Fafnir  = { 'bigBoss' }, -- HNM
        Nidhogg = { 'bigBoss' }, -- HNM
    },
    [xi.zone.BEHEMOTHS_DOMINION] =
    {
        Behemoth      = { 'bigBoss' }, -- HNM
        King_Behemoth = { 'bigBoss' }, -- HNM
    },
    [xi.zone.VALLEY_OF_SORROWS] =
    {
        Adamantoise   = { 'bigBoss' }, -- HNM
        Aspidochelone = { 'bigBoss' }, -- HNM
    },
    [xi.zone.ABYSSEA_LA_THEINE] =
    {
        Briareus  = { 'bigBoss' }, -- Abyssea
        Carabosse = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_KONSCHTAT] =
    {
        Kukulkan = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_TAHRONGI] =
    {
        Glavoid = { 'bigBoss' }, -- Abyssea
        Chloris = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_ATTOHWA] =
    {
        Itzpapalotl = { 'bigBoss' }, -- Abyssea
        Ulhuadshi   = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_MISAREAUX] =
    {
        ['Cirein-croin'] = { 'bigBoss' }, -- Abyssea
        Sobek            = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_VUNKERL] =
    {
        Bukhis = { 'bigBoss' }, -- Abyssea
        Sedna  = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_ALTEPA] =
    {
        Orthrus = { 'bigBoss' }, -- Abyssea
        Dragua  = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_ULEGUERAND] =
    {
        Isgebind = { 'bigBoss' }, -- Abyssea
        Apademak = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_GRAUBERG] =
    {
        Alfard = { 'bigBoss' }, -- Abyssea
        Azdaja = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.ABYSSEA_EMPYREAL_PARADOX] =
    {
        Shinryu = { 'bigBoss' }, -- Abyssea
    },
    [xi.zone.DYNAMIS_XARCABARD] =
    {
        Dynamis_Lord      = { 'dynamisLord', 'omenBoss' }, -- Dynamis megaboss
        Arch_Dynamis_Lord = { 'dynamisLord', 'omenBoss' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_SAN_DORIA] =
    {
        Arch_Overlord_Tombstone = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_BASTOK] =
    {
        Arch_GuDha_Effigy = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_WINDURST] =
    {
        Arch_Tzee_Xicu_Idol = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_JEUNO] =
    {
        Arch_Goblin_Golem = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_BEAUCEDINE] =
    {
        Arch_Angra_Mainyu = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_VALKURM] =
    {
        Arch_Christelle = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_BUBURIMU] =
    {
        Arch_Apocalyptic_Beast = { 'dynamisLord' }, -- Dynamis megaboss
    },
    [xi.zone.DYNAMIS_QUFIM] =
    {
        Arch_Antaeus = { 'dynamisLord' }, -- Dynamis megaboss
    },
}

return config
