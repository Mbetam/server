-----------------------------------
-- Trust Vendor: which trusts it sells, the price, and where it stands. Not a module (loaded by require).
-- It sells the trusts players cannot get in normal play here (Eric's choice, 2026-09-23; details in
-- docs/custom/NOTES.md, "Trust acquisition"):
--   event:  retail hands them out only through login campaigns, Mog Pells or seasonal events (switched off here)
--   story:  retail gives them for a quest or mission that LSB has not built yet
--   unity:  retail gives them for Unity accolades (a weekly evaluation LSB does not have)
-- If one of these becomes obtainable in game, it can simply be removed from the list.
-----------------------------------
local config = {}

config.price = 100000

-- Like retail cipher trades, buying a trust needs a Trust permit (any nation's Trust quest)
config.needsPermit = true

-- The NPC's look: the same Moogle model the Augmenter uses
config.npcModel = 82

-- Where the vendor stands. Stand where you want it in game, use !pos to read your coordinates, then edit here.
-- Rotation is 0-255 (0 = east). New spots need a server restart.
config.placements =
{
    -- Lower Jeuno, beside the Augmenter (7.03, 6.05). Eric's !pos was 6.14, 6.55, only 1 yalm from it, so the vendor
    -- stands 3 yalms from the Augmenter along that same line, facing the same way.
    { zone = 'Lower_Jeuno', x = 4.40, y = 0.0, z = 7.50, rotation = 84 },

    -- GM Home, for testing
    { zone = 'GM_Home', x = 10.0, y = 0.0, z = 3.0, rotation = 128 },
}

config.groups =
{
    {
        title = 'Event and campaign trusts',
        trusts =
        {
            { spell = xi.magic.spell.ABENZIO,          name = 'Abenzio' },
            { spell = xi.magic.spell.ALDO,             name = 'Aldo' },
            { spell = xi.magic.spell.AREUHAT,          name = 'Areuhat' },
            { spell = xi.magic.spell.AAEV,             name = 'Ark Angel EV' },
            { spell = xi.magic.spell.AAGK,             name = 'Ark Angel GK' },
            { spell = xi.magic.spell.AAHM,             name = 'Ark Angel HM' },
            { spell = xi.magic.spell.AAMR,             name = 'Ark Angel MR' },
            { spell = xi.magic.spell.AATT,             name = 'Ark Angel TT' },
            { spell = xi.magic.spell.BABBAN,           name = 'Babban' },
            { spell = xi.magic.spell.BRYGID,           name = 'Brygid' },
            { spell = xi.magic.spell.DOMINA_SHANTOTTO, name = 'Domina Shantotto' },
            { spell = xi.magic.spell.DARRCUILN,        name = 'Darrcuiln' },
            { spell = xi.magic.spell.ELIVIRA,          name = 'Elivira' },
            { spell = xi.magic.spell.FABLINIX,         name = 'Fablinix' },
            { spell = xi.magic.spell.KARAHA_BARUHA,    name = 'Karaha-Baruha' },
            { spell = xi.magic.spell.KAYEEL_PAYEEL,    name = 'Kayeel-Payeel' },
            { spell = xi.magic.spell.KING_OF_HEARTS,   name = 'King of Hearts' },
            { spell = xi.magic.spell.KUPOFRIED,        name = 'Kupofried' },
            { spell = xi.magic.spell.KUYIN_HATHDENNA,  name = 'Kuyin Hathdenna' },
            { spell = xi.magic.spell.LEHKO_HABHOKA,    name = 'Lehko Habhoka' },
            { spell = xi.magic.spell.LEONOYNE,         name = 'Leonoyne' },
            { spell = xi.magic.spell.LHE_LHANGAVO,     name = 'Lhe Lhangavo' },
            { spell = xi.magic.spell.LHU_MHAKARACCA,   name = 'Lhu Mhakaracca' },
            { spell = xi.magic.spell.LION,             name = 'Lion' },
            { spell = xi.magic.spell.LUZAF,            name = 'Luzaf' },
            { spell = xi.magic.spell.MAXIMILIAN,       name = 'Maximilian' },
            { spell = xi.magic.spell.MAYAKOV,          name = 'Mayakov' },
            { spell = xi.magic.spell.MILDAURION,       name = 'Mildaurion' },
            { spell = xi.magic.spell.MNEJING,          name = 'Mnejing' },
            { spell = xi.magic.spell.MOOGLE,           name = 'Moogle' },
            { spell = xi.magic.spell.MUMOR,            name = 'Mumor' },
            { spell = xi.magic.spell.MUMOR_II,         name = 'Mumor II' },
            { spell = xi.magic.spell.NAJA_SALAHEEM,    name = 'Naja Salaheem' },
            { spell = xi.magic.spell.NAJELITH,         name = 'Najelith' },
            { spell = xi.magic.spell.NOILLURIE,        name = 'Noillurie' },
            { spell = xi.magic.spell.OVJANG,           name = 'Ovjang' },
            { spell = xi.magic.spell.ROBEL_AKBEL,      name = 'Robel-Akbel' },
            { spell = xi.magic.spell.RONGELOUTS,       name = 'Rongelouts' },
            { spell = xi.magic.spell.RUGHADJEEN,       name = 'Rughadjeen' },
            { spell = xi.magic.spell.SAKURA,           name = 'Sakura' },
            { spell = xi.magic.spell.SHANTOTTO_II,     name = 'Shantotto II' },
            { spell = xi.magic.spell.STAR_SIBYL,       name = 'Star Sibyl' },
            { spell = xi.magic.spell.TEODOR,           name = 'Teodor' },
            { spell = xi.magic.spell.UKA_TOTLIHN,      name = 'Uka Totlihn' },
            { spell = xi.magic.spell.ULLEGORE,         name = 'Ullegore' },
            { spell = xi.magic.spell.ZEID,             name = 'Zeid' },
        },
    },
    {
        title = 'Story trusts (quest not in game yet)',
        trusts =
        {
            { spell = xi.magic.spell.ARCIELA_II,       name = 'Arciela II' },
            { spell = xi.magic.spell.AUGUST,           name = 'August' },
            { spell = xi.magic.spell.BALAMOR,          name = 'Balamor' },
            { spell = xi.magic.spell.CHACHAROON,       name = 'Chacharoon' },
            { spell = xi.magic.spell.INGRID_II,        name = 'Ingrid II' },
            { spell = xi.magic.spell.IROHA,            name = 'Iroha' },
            { spell = xi.magic.spell.IROHA_II,         name = 'Iroha II' },
            { spell = xi.magic.spell.LILISETTE,        name = 'Lilisette' },
            { spell = xi.magic.spell.ROMAA_MIHGO,      name = 'Romaa Mihgo' },
            { spell = xi.magic.spell.ROSULATIA,        name = 'Rosulatia' },
            { spell = xi.magic.spell.SELHTEUS,         name = "Selh'teus" },
            { spell = xi.magic.spell.YGNAS,            name = 'Ygnas' },
        },
    },
    {
        title = 'Unity trusts',
        trusts =
        {
            { spell = xi.magic.spell.ALDO_UC,              name = 'Aldo (UC)' },
            { spell = xi.magic.spell.APURURU_UC,           name = 'Apururu (UC)' },
            { spell = xi.magic.spell.AYAME_UC,             name = 'Ayame (UC)' },
            { spell = xi.magic.spell.FLAVIRIA_UC,          name = 'Flaviria (UC)' },
            { spell = xi.magic.spell.INVINCIBLE_SHIELD_UC, name = 'Invincible Shield (UC)' },
            { spell = xi.magic.spell.JAKOH_UC,             name = 'Jakoh Wahcondalo (UC)' },
            { spell = xi.magic.spell.MAAT_UC,              name = 'Maat (UC)' },
            { spell = xi.magic.spell.NAJA_UC,              name = 'Naja (UC)' },
            { spell = xi.magic.spell.PIEUJE_UC,            name = 'Pieuje (UC)' },
            { spell = xi.magic.spell.SYLVIE_UC,            name = 'Sylvie (UC)' },
            { spell = xi.magic.spell.YORAN_ORAN_UC,        name = 'Yoran-Oran (UC)' },
        },
    },
}

return config
