-----------------------------------
-- func: signet
-- desc: Gives the regional status for the area you are in, the same one the local NPCs would give:
--       Signet (original areas and the three nations + Jeuno), Sanction (Aht Urhgan), Sigil (the [S] areas of the past)
--       or Ionis (Adoulin). Any other of the four you had is replaced, as in retail (only one can be active).
--       Sanction and Sigil come without their optional paid extras (Regen, Refresh, ...), like the free version from the NPCs.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

-- Which effect each region uses. The same split the engine uses to decide which effect a region's crystal drops need
-- (src/map/entities/mob_entity.cpp), plus the four city regions, where retail guards hand out Signet too.
local signetRegions =
{
    xi.region.RONFAURE, xi.region.ZULKHEIM, xi.region.NORVALLEN, xi.region.GUSTABERG, xi.region.DERFLAND,
    xi.region.SARUTABARUTA, xi.region.KOLSHUSHU, xi.region.ARAGONEU, xi.region.FAUREGANDI, xi.region.VALDEAUNIA,
    xi.region.QUFIMISLAND, xi.region.LITELOR, xi.region.KUZOTZ, xi.region.VOLLBOW, xi.region.ELSHIMO_LOWLANDS,
    xi.region.ELSHIMO_UPLANDS, xi.region.TULIA, xi.region.MOVALPOLOS,
    xi.region.SANDORIA, xi.region.BASTOK, xi.region.WINDURST, xi.region.JEUNO,
}

local sanctionRegions =
{
    xi.region.WEST_AHT_URHGAN, xi.region.MAMOOL_JA_SAVAGE, xi.region.HALVUNG, xi.region.ARRAPAGO, xi.region.ALZADAAL,
}

local sigilRegions =
{
    xi.region.RONFAURE_FRONT, xi.region.NORVALLEN_FRONT, xi.region.GUSTABERG_FRONT, xi.region.DERFLAND_FRONT,
    xi.region.SARUTA_FRONT, xi.region.ARAGONEAU_FRONT, xi.region.FAUREGANDI_FRONT, xi.region.VALDEAUNIA_FRONT,
}

local ionisRegions =
{
    xi.region.ADOULIN_ISLANDS, xi.region.EAST_ULBUKA,
}

-- Durations follow what the NPCs give in scripts/globals (conquest.lua, besieged.lua, campaign.lua) and Ruth (Adoulin).
local statuses =
{
    signet =
    {
        label    = 'Signet',
        effect   = xi.effect.SIGNET,
        -- Conquest guards: (your rank + your nation's conquest rank + 3) hours
        duration = function(player)
            local nation = player:getNation()

            return (player:getRank(nation) + GetNationRank(nation) + 3) * 3600
        end,
    },
    sanction =
    {
        label    = 'Sanction',
        effect   = xi.effect.SANCTION,
        -- Besieged NPCs: 3 hours (the base; retail adds 20 minutes per mercenary rank)
        duration = function(player)
            return 10800
        end,
    },
    sigil =
    {
        label    = 'Sigil',
        effect   = xi.effect.SIGIL,
        -- Campaign NPCs: 3 hours + 15 minutes per Allied Notes medal rank
        duration = function(player)
            return 10800 + 15 * 60 * xi.campaign.getMedalRank(player)
        end,
        subPower = 35, -- the Regen/Refresh HP/MP trigger the NPCs set; unused without those extras
    },
    ionis =
    {
        label    = 'Ionis',
        effect   = xi.effect.IONIS,
        duration = function(player)
            return 9000 -- Ruth in Western Adoulin: 2.5 hours
        end,
    },
}

local statusByRegion = {}

for key, regions in pairs({ signet = signetRegions, sanction = sanctionRegions, sigil = sigilRegions, ionis = ionisRegions }) do
    for _, region in ipairs(regions) do
        statusByRegion[region] = statuses[key]
    end
end

-- 18000 -> '5 hours', 11700 -> '3 hours 15 minutes'
local function formatDuration(seconds)
    local hours   = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local text    = string.format('%d hour%s', hours, hours == 1 and '' or 's')

    if minutes > 0 then
        text = text .. string.format(' %d minutes', minutes)
    end

    return text
end

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

commandObj.onTrigger = function(player)
    if player:isDead() then
        qol.say(player, 'You cannot do that while KO\'d.')

        return
    end

    local status = statusByRegion[player:getCurrentRegion()]
    if status == nil then
        qol.say(player, 'No Signet, Sanction, Sigil or Ionis applies in this area.')

        return
    end

    local duration = status.duration(player)

    -- Only one of the four can be active at a time (they all carry the INFLUENCE flag): the NPCs clear the others first
    player:delStatusEffectsByFlag(xi.effectFlag.INFLUENCE, true)
    player:addStatusEffect(status.effect, { power = 0, duration = duration, origin = player, subPower = status.subPower or 0 })

    qol.say(player, string.format('You received %s for %s.', status.label, formatDuration(duration)))
end

xi.module.registerCommand('signet', commandObj)
