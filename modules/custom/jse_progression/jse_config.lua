-----------------------------------
-- JSE weapon progression (Relic / Mythic / Empyrean through Abyssea): every number in one place. Not a module.
-- Design: jse-weapon-progression-prompt.md (Eric, 2026-09-29) and the decisions in docs/custom/NOTES.md.
-- Stages: base (Splintery Chest, 500,000 gil) -> 85 -> 95 -> 99 at the family's Magian Moogle, then Oboro 99 -> 119 ->
-- 119 III. Item ids checked against item_basic. Empyreans have no level 75 version: their base is the level 80 one
-- (Daurdabla and Ochain: 85, so their first moogle step is 85 -> 95). Weapons marked done99 have no 119 version:
-- reaching 99 completes them.
-----------------------------------
local config = {}

config.price     = 500000
config.baseLevel = 99 -- main job level needed to buy

-- Character variables
config.var =
{
    active = 'JSE_ACTIVE_WEAPON', -- base item id of the weapon in progress, 0 = none
    done   =
    {
        relic    = 'JSE_RELIC_DONE',
        mythic   = 'JSE_MYTHIC_DONE',
        empyrean = 'JSE_EMPY_DONE',
    },
}

-- Materials per stage: { item id, quantity }. Stage 1 = base -> 85, 2 = 85 -> 95, 3 = 95 -> 99.
config.families =
{
    relic =
    {
        name     = 'Relic',
        moogle   = 17772784, -- Magian Moogle, green pom (Ru'Lude Gardens)
        requires = nil,
        stages   =
        {
            { { 3226, 5 }, { 3222, 5 }, { 3212, 5 } }, -- Stone of Voyage (Ovni), Stone of Balance (Myrmecoleon), Jewel of Vision (Turul)
            { { 2930, 5 }, { 2931, 5 }, { 2933, 5 } }, -- Carabosse's Gem, Vial of Fistule Discharge, Chukwa's Egg
            { { 2927, 5 }, { 2929, 5 }, { 2932, 5 } }, -- Glavoid Shell, Helm of Briareus, Kukulkan's Fang
        },
        weapons =
        {
        { name = 'Spharai', base = 18264, baseLevel = 75, s85 = 18637, s95 = 18665, s99 = 19746 },
        { name = 'Mandau', base = 18270, baseLevel = 75, s85 = 18638, s95 = 18666, s99 = 19747 },
        { name = 'Excalibur', base = 18276, baseLevel = 75, s85 = 18639, s95 = 18667, s99 = 19748 },
        { name = 'Ragnarok', base = 18282, baseLevel = 75, s85 = 18640, s95 = 18668, s99 = 19749 },
        { name = 'Guttler', base = 18288, baseLevel = 75, s85 = 18641, s95 = 18669, s99 = 19750 },
        { name = 'Bravura', base = 18294, baseLevel = 75, s85 = 18642, s95 = 18670, s99 = 19751 },
        { name = 'Apocalypse', base = 18306, baseLevel = 75, s85 = 18644, s95 = 18672, s99 = 19753 },
        { name = 'Gungnir', base = 18300, baseLevel = 75, s85 = 18643, s95 = 18671, s99 = 19752 },
        { name = 'Kikoku', base = 18312, baseLevel = 75, s85 = 18645, s95 = 18673, s99 = 19754 },
        { name = 'Amanomurakumo', base = 18318, baseLevel = 75, s85 = 18646, s95 = 18674, s99 = 19755 },
        { name = 'Mjollnir', base = 18324, baseLevel = 75, s85 = 18647, s95 = 18675, s99 = 19756 },
        { name = 'Claustrum', base = 18330, baseLevel = 75, s85 = 18648, s95 = 18676, s99 = 19757 },
        { name = 'Annihilator', base = 18336, baseLevel = 75, s85 = 18649, s95 = 18677, s99 = 19758 },
        { name = 'Yoichinoyumi', base = 18348, baseLevel = 75, s85 = 18650, s95 = 18678, s99 = 19759 },
        { name = 'Gjallarhorn', base = 18342, baseLevel = 75, s85 = 18578, s95 = 18580, s99 = 18572, done99 = true },
        { name = 'Aegis', base = 15070, baseLevel = 75, s85 = 16196, s95 = 16198, s99 = 11927, done99 = true },
        },
    },
    mythic =
    {
        name     = 'Mythic',
        moogle   = 17772778, -- Magian Moogle, orange pom
        requires = 'relic',
        stages   =
        {
            { { 3221, 5 }, { 3219, 5 }, { 3218, 5 } }, -- Card of Wieldance (Karkadann), Coin of Wieldance (Ironclad Pulverizer), Stone of Wieldance (Smok)
            { { 2966, 5 }, { 2964, 5 }, { 2963, 5 } }, -- Bukhis's Wing, Sobek's Skin, Ulhuadshi's Fang
            { { 2967, 5 }, { 2965, 5 }, { 2962, 5 } }, -- Sedna's Tusk, Cirein-croin's Lantern, Itzpapalotl's Scale
        },
        weapons =
        {
        { name = 'Conqueror', base = 18991, baseLevel = 75, s85 = 19080, s95 = 19710, s99 = 19819 },
        { name = 'Glanzfaust', base = 18992, baseLevel = 75, s85 = 19081, s95 = 19711, s99 = 19820 },
        { name = 'Yagrush', base = 18993, baseLevel = 75, s85 = 19082, s95 = 19712, s99 = 19821 },
        { name = 'Laevateinn', base = 18994, baseLevel = 75, s85 = 19083, s95 = 19713, s99 = 19822 },
        { name = 'Murgleis', base = 18995, baseLevel = 75, s85 = 19084, s95 = 19714, s99 = 19823 },
        { name = 'Vajra', base = 18996, baseLevel = 75, s85 = 19085, s95 = 19715, s99 = 19824 },
        { name = 'Burtgang', base = 18997, baseLevel = 75, s85 = 19086, s95 = 19716, s99 = 19825 },
        { name = 'Liberator', base = 18998, baseLevel = 75, s85 = 19087, s95 = 19717, s99 = 19826 },
        { name = 'Aymur', base = 18999, baseLevel = 75, s85 = 19088, s95 = 19718, s99 = 19827 },
        { name = 'Carnwenhan', base = 19000, baseLevel = 75, s85 = 19089, s95 = 19719, s99 = 19828 },
        { name = 'Gastraphetes', base = 19001, baseLevel = 75, s85 = 19090, s95 = 19720, s99 = 19829 },
        { name = 'Kogarasumaru', base = 19002, baseLevel = 75, s85 = 19091, s95 = 19721, s99 = 19830 },
        { name = 'Nagi', base = 19003, baseLevel = 75, s85 = 19092, s95 = 19722, s99 = 19831 },
        { name = 'Ryunohige', base = 19004, baseLevel = 75, s85 = 19093, s95 = 19723, s99 = 19832 },
        { name = 'Nirvana', base = 19005, baseLevel = 75, s85 = 19094, s95 = 19724, s99 = 19833 },
        { name = 'Tizona', base = 19006, baseLevel = 75, s85 = 19095, s95 = 19725, s99 = 19834 },
        { name = 'Death Penalty', base = 19007, baseLevel = 75, s85 = 19096, s95 = 19726, s99 = 19835 },
        { name = 'Kenkonken', base = 19008, baseLevel = 75, s85 = 19097, s95 = 19727, s99 = 19836 },
        { name = 'Terpsichore', base = 18989, baseLevel = 75, s85 = 19098, s95 = 19728, s99 = 19837 },
        { name = 'Tupsimati', base = 18990, baseLevel = 75, s85 = 19099, s95 = 19729, s99 = 19838 },
        },
    },
    empyrean =
    {
        name     = 'Empyrean',
        moogle   = 17772782, -- Magian Moogle, blue pom
        requires = 'mythic',
        stages   =
        {
            { { 3216, 5 }, { 3214, 5 }, { 3215, 5 } }, -- Jewel of Ardor (Hedjedjet), Stone of Ardor (Empousa), Coin of Ardor (Fuath)
            { { 3287, 5 }, { 3289, 5 }, { 3291, 5 } }, -- Orthrus's Claw, Apademak's Horn, Alfard's Fang
            { { 3288, 5 }, { 3290, 5 }, { 3292, 5 } }, -- Dragua's Scale, Isgebind's Heart, Azdaja's Horn
        },
        weapons =
        {
        { name = 'Verethragna', base = 19397, baseLevel = 80, s85 = 19456, s95 = 19632, s99 = 19805 },
        { name = 'Twashtar', base = 19398, baseLevel = 80, s85 = 19457, s95 = 19633, s99 = 19806 },
        { name = 'Almace', base = 19399, baseLevel = 80, s85 = 19458, s95 = 19634, s99 = 19807 },
        { name = 'Caladbolg', base = 19400, baseLevel = 80, s85 = 19459, s95 = 19635, s99 = 19808 },
        { name = 'Farsha', base = 19401, baseLevel = 80, s85 = 19460, s95 = 19636, s99 = 19809 },
        { name = 'Ukonvasara', base = 19402, baseLevel = 80, s85 = 19461, s95 = 19637, s99 = 19810 },
        { name = 'Redemption', base = 19403, baseLevel = 80, s85 = 19462, s95 = 19638, s99 = 19811 },
        { name = 'Rhongomiant', base = 19404, baseLevel = 80, s85 = 19463, s95 = 19639, s99 = 19812 },
        { name = 'Kannagi', base = 19405, baseLevel = 80, s85 = 19464, s95 = 19640, s99 = 19813 },
        { name = 'Masamune', base = 19406, baseLevel = 80, s85 = 19465, s95 = 19641, s99 = 19814 },
        { name = 'Gambanteinn', base = 19407, baseLevel = 80, s85 = 19466, s95 = 19642, s99 = 19815 },
        { name = 'Hvergelmir', base = 19408, baseLevel = 80, s85 = 19467, s95 = 19643, s99 = 19816 },
        { name = 'Gandiva', base = 19409, baseLevel = 80, s85 = 19468, s95 = 19644, s99 = 19817 },
        { name = 'Armageddon', base = 19410, baseLevel = 80, s85 = 19469, s95 = 19645, s99 = 19818 },
        { name = 'Daurdabla', base = 18574, baseLevel = 85, s85 = 18574, s95 = 18576, s99 = 18571, done99 = true },
        { name = 'Ochain', base = 16192, baseLevel = 85, s85 = 16192, s95 = 16194, s99 = 11926, done99 = true },
        },
    },
}

config.familyOrder = { 'relic', 'mythic', 'empyrean' }

-- Material drops: [zone] = { [NM name] = { item, twoChance } }. One at 100% per kill; twoChance = a second one at that
-- percent (the "1-2 per kill" NMs). The server drop multiplier is divided out so 50 really means 50.
config.drops =
{
    [xi.zone.ABYSSEA_LA_THEINE]  = { Ovni = { 3226 }, Carabosse = { 2930, 50 }, Briareus = { 2929, 50 } },
    [xi.zone.ABYSSEA_TAHRONGI]   = { Myrmecoleon = { 3222 }, Chukwa = { 2933, 50 }, Glavoid = { 2927, 50 } },
    [xi.zone.ABYSSEA_KONSCHTAT]  = { Turul = { 3212 }, Fistule = { 2931, 50 }, Kukulkan = { 2932, 50 } },
    [xi.zone.ABYSSEA_VUNKERL]    = { Karkadann = { 3221 }, Bukhis = { 2966, 50 }, Sedna = { 2967, 50 } },
    [xi.zone.ABYSSEA_MISAREAUX]  = { Ironclad_Pulverizer = { 3219 }, Sobek = { 2964, 50 }, ['Cirein-croin'] = { 2965, 50 } },
    [xi.zone.ABYSSEA_ATTOHWA]    = { Smok = { 3218 }, Ulhuadshi = { 2963, 50 }, Itzpapalotl = { 2962, 50 } },
    [xi.zone.ABYSSEA_ALTEPA]     = { Hedjedjet = { 3216 }, Orthrus = { 3287, 50 }, Dragua = { 3288, 50 } },
    [xi.zone.ABYSSEA_ULEGUERAND] = { Empousa = { 3214 }, Apademak = { 3289, 50 }, Isgebind = { 3290, 50 } },
    [xi.zone.ABYSSEA_GRAUBERG]   = { Fuath = { 3215 }, Alfard = { 3291, 50 }, Azdaja = { 3292, 50 } },
}

-- Difficulty: HP and damage (attack and magic attack) multipliers on spawn, by family zone set, with megabosses
-- tougher on top. 1.0 = LSB as shipped.
config.difficulty =
{
    tiers =
    {
        [xi.zone.ABYSSEA_LA_THEINE]  = 1.00, [xi.zone.ABYSSEA_TAHRONGI]   = 1.00, [xi.zone.ABYSSEA_KONSCHTAT] = 1.00, -- Relic
        [xi.zone.ABYSSEA_VUNKERL]    = 1.15, [xi.zone.ABYSSEA_MISAREAUX]  = 1.15, [xi.zone.ABYSSEA_ATTOHWA]   = 1.15, -- Mythic
        [xi.zone.ABYSSEA_ALTEPA]     = 1.30, [xi.zone.ABYSSEA_ULEGUERAND] = 1.30, [xi.zone.ABYSSEA_GRAUBERG]  = 1.30, -- Empyrean
    },
    megabossExtra = 1.25,
    megabosses    =
    {
        Glavoid = true, Briareus = true, Kukulkan = true,
        Sedna = true, ['Cirein-croin'] = true, Itzpapalotl = true,
        Dragua = true, Isgebind = true, Azdaja = true,
    },
}

return config
