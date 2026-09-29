-----------------------------------
-- Oboro (Ru'Lude Gardens): Relic, Mythic and Empyrean weapons 99 -> 119 -> 119 III. Not a module (loaded by require).
-- Eric's choices (2026-09-28): 99 -> 119 costs 300 and 119 -> 119 III (direct, skipping 119 II) costs 1,000 of the
-- family's material: Pluton for Relic, Riftborn Boulder for Mythic, Beitetsu for Empyrean. The materials stack to 99
-- and a trade has 8 slots, so they are traded in first and kept as a balance (char vars), like Sagheera's beastcoins.
-- Chains from item_basic (names + weapon damage), checked 2026-09-28. Both the 99 and the 99 II piece count as 99; a
-- 119 II (not given here) upgrades to 119 III for the same price. Idris and Epeolatry have no 99 version.
-- Shields and instruments (Aegis, Ochain, Daurdabla, ...) have no 119 versions and are not upgraded.
-----------------------------------
local config = {}

config.materials =
{
    relic    = { item = 4059, var = 'OBORO_PLUTON',   name = 'Pluton'           }, -- pluton
    mythic   = { item = 4061, var = 'OBORO_BOULDER',  name = 'Riftborn Boulder' }, -- riftborn_boulder
    empyrean = { item = 4060, var = 'OBORO_BEITETSU', name = 'Beitetsu'         }, -- chunk_of_beitetsu
}

config.cost =
{
    to119    = 300,
    to119iii = 1000,
}

config.maxBalance = 99999 -- per material

-- family > { base = { 99, 99 II }, s119, s119ii, s119iii }
config.chains =
{
    relic =
    {
        { base = { 19746, 19839 }, s119 = 20480, s119ii = 20481, s119iii = 20509 }, -- spharai
        { base = { 19747, 19840 }, s119 = 20555, s119ii = 20556, s119iii = 20583 }, -- mandau
        { base = { 19748, 19841 }, s119 = 20645, s119ii = 20646, s119iii = 20685 }, -- excalibur
        { base = { 19749, 19842 }, s119 = 20745, s119ii = 20746, s119iii = 21683 }, -- ragnarok
        { base = { 19750, 19843 }, s119 = 20790, s119ii = 20791, s119iii = 21750 }, -- guttler
        { base = { 19751, 19844 }, s119 = 20835, s119ii = 20836, s119iii = 21756 }, -- bravura
        { base = { 19753, 19846 }, s119 = 20880, s119ii = 20881, s119iii = 21808 }, -- apocalypse
        { base = { 19752, 19845 }, s119 = 20925, s119ii = 20926, s119iii = 21857 }, -- gungnir
        { base = { 19754, 19847 }, s119 = 20970, s119ii = 20971, s119iii = 21906 }, -- kikoku
        { base = { 19755, 19848 }, s119 = 21015, s119ii = 21016, s119iii = 21954 }, -- amanomurakumo
        { base = { 19756, 19849 }, s119 = 21060, s119ii = 21061, s119iii = 21077 }, -- mjollnir
        { base = { 19757, 19850 }, s119 = 21135, s119ii = 21136, s119iii = 22060 }, -- claustrum
        { base = { 19758, 19851 }, s119 = 21260, s119ii = 21261, s119iii = 21267 }, -- annihilator
        { base = { 19759, 19852 }, s119 = 21210, s119ii = 21211, s119iii = 22115 }, -- yoichinoyumi
    },
    mythic =
    {
        { base = { 19819, 19948 }, s119 = 20837, s119ii = 20838, s119iii = 21757 }, -- conqueror
        { base = { 19820, 19949 }, s119 = 20482, s119ii = 20483, s119iii = 20510 }, -- glanzfaust
        { base = { 19821, 19950 }, s119 = 21062, s119ii = 21063, s119iii = 21078 }, -- yagrush
        { base = { 19822, 19951 }, s119 = 21139, s119ii = 21140, s119iii = 22062 }, -- laevateinn
        { base = { 19823, 19952 }, s119 = 20647, s119ii = 20648, s119iii = 20686 }, -- murgleis
        { base = { 19824, 19953 }, s119 = 20559, s119ii = 20560, s119iii = 20585 }, -- vajra
        { base = { 19825, 19954 }, s119 = 20649, s119ii = 20650, s119iii = 20687 }, -- burtgang
        { base = { 19826, 19955 }, s119 = 20882, s119ii = 20883, s119iii = 21809 }, -- liberator
        { base = { 19827, 19956 }, s119 = 20792, s119ii = 20793, s119iii = 21751 }, -- aymur
        { base = { 19828, 19957 }, s119 = 20561, s119ii = 20562, s119iii = 20586 }, -- carnwenhan
        { base = { 19829, 19958 }, s119 = 21246, s119ii = 21247, s119iii = 21266 }, -- gastraphetes
        { base = { 19830, 19959 }, s119 = 21017, s119ii = 21018, s119iii = 21955 }, -- kogarasumaru
        { base = { 19831, 19960 }, s119 = 20972, s119ii = 20973, s119iii = 21907 }, -- nagi
        { base = { 19832, 19961 }, s119 = 20927, s119ii = 20928, s119iii = 21858 }, -- ryunohige
        { base = { 19833, 19962 }, s119 = 21141, s119ii = 21142, s119iii = 22063 }, -- nirvana
        { base = { 19834, 19963 }, s119 = 20651, s119ii = 20652, s119iii = 20688 }, -- tizona
        { base = { 19835, 19964 }, s119 = 21262, s119ii = 21263, s119iii = 21268 }, -- death_penalty
        { base = { 19836, 19965 }, s119 = 20484, s119ii = 20485, s119iii = 20511 }, -- kenkonken
        { base = { 19837, 19966 }, s119 = 20557, s119ii = 20558, s119iii = 20584 }, -- terpsichore
        { base = { 19838, 19967 }, s119 = 21137, s119ii = 21138, s119iii = 22061 }, -- tupsimati
        { base = {}, s119 = 21070, s119iii = 21080 }, -- idris (no 99 version: retail gives it at 119)
        { base = {}, s119 = 20753, s119iii = 21685 }, -- epeolatry (no 99 version: retail gives it at 119)
    },
    empyrean =
    {
        { base = { 19805, 19853 }, s119 = 20486, s119ii = 20487, s119iii = 20512 }, -- verethragna
        { base = { 19806, 19854 }, s119 = 20563, s119ii = 20564, s119iii = 20587 }, -- twashtar
        { base = { 19807, 19855 }, s119 = 20653, s119ii = 20654, s119iii = 20689 }, -- almace
        { base = { 19808, 19856 }, s119 = 20747, s119ii = 20748, s119iii = 21684 }, -- caladbolg
        { base = { 19809, 19857 }, s119 = 20794, s119ii = 20795, s119iii = 21752 }, -- farsha
        { base = { 19810, 19858 }, s119 = 20839, s119ii = 20840, s119iii = 21758 }, -- ukonvasara
        { base = { 19811, 19859 }, s119 = 20884, s119ii = 20885, s119iii = 21810 }, -- redemption
        { base = { 19812, 19860 }, s119 = 20929, s119ii = 20930, s119iii = 21859 }, -- rhongomiant
        { base = { 19813, 19861 }, s119 = 20974, s119ii = 20975, s119iii = 21908 }, -- kannagi
        { base = { 19814, 19862 }, s119 = 21019, s119ii = 21020, s119iii = 21956 }, -- masamune
        { base = { 19815, 19863 }, s119 = 21064, s119ii = 21065, s119iii = 21079 }, -- gambanteinn
        { base = { 19816, 19864 }, s119 = 21143, s119ii = 21144, s119iii = 22064 }, -- hvergelmir
        { base = { 19817, 19865 }, s119 = 21212, s119ii = 21213, s119iii = 22116 }, -- gandiva
        { base = { 19818, 19866 }, s119 = 21264, s119ii = 21265, s119iii = 21269 }, -- armageddon
    },
}

return config
