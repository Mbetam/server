-----------------------------------
-- Boss arenas for Rem's Tales, the way in (htbf_config.lua):
-- 1. The Battle Archivist in Western Adoulin (Eric's spot): pick Tier 1-5 and you, with every party / alliance member
--    near you, go straight into a private arena for that tier (htbf_arena.lua). Free, no requirements.
-- 2. Anyone who logs back in inside an arena that has closed lands back at the Archivist (retail sends them to Mhaura).
-- (Until 2026-09-30 there was a hub with four section markers on Abdhaljs Isle-Purgonorgo; Eric replaced it with this
-- menu.)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Western_Adoulin/Zone')
require('scripts/zones/Maquette_Abdhaljs-Legion_A/Zone')
local config = require('modules/custom/htbf/htbf_config')
local arena  = require('modules/custom/htbf/htbf_arena')
-----------------------------------

local m = Module:new('htbf_hub')

local hub = {}

-----------------------------------
-- 1: the Archivist
-----------------------------------
local function bossNames(tier)
    local names = {}

    for _, boss in ipairs(config.bosses[tier]) do
        table.insert(names, boss.name)
    end

    return table.concat(names, ', ')
end

hub.onArchivistTrigger = function(player, npc)
    arena.say(player, 'I open private boss arenas for you and your party. No fee. The Moogle inside calls the bosses one at a time.')
    arena.say(player, 'Tier 1: chapters 1-5. Tier 2: chapters 6-10. Tier 3: job cards. Tiers 4-5: boxes. Every boss has loot to roll too.')

    local options = {}

    for tier = 1, #config.tiers do
        local t = config.tiers[tier]

        arena.say(player, string.format('%s (level %d): %s', t.name, t.level, bossNames(tier)))
        table.insert(options, { string.format('%s (Lv%d)', t.name, t.level), function(playerArg) arena.open(playerArg, tier) end })
    end

    table.insert(options, { 'Not now', function() end })

    arena.sendMenu(player, { title = 'Which arena? Your party comes too.', options = options })
end

m:addOverride('xi.zones.Western_Adoulin.Zone.onInitialize', function(zone)
    super(zone)

    local a = config.archivist

    zone:insertDynamicEntity(
    {
        objtype    = xi.objType.NPC,
        name       = 'Battle_Archivist',
        packetName = 'Battle Archivist',
        look       = a.look,
        x          = a.x,
        y          = a.y,
        z          = a.z,
        rotation   = a.rotation,
        widescan   = 1,
        onTrigger  = hub.onArchivistTrigger,
    })
end)

-----------------------------------
-- 2: logging back in after the arena closed
-----------------------------------
m:addOverride('xi.zones.Maquette_Abdhaljs-Legion_A.Zone.onInstanceZoneIn', function(player, instance)
    if player:getInstance() == nil then
        arena.toArchivist(player)

        return
    end

    return super(player, instance)
end)

m:addOverride('xi.zones.Maquette_Abdhaljs-Legion_A.Zone.onInstanceLoadFailed', function()
    return config.archivist.zoneId
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.htbfHub = hub -- for tests

return m
