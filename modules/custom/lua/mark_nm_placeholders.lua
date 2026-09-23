-----------------------------------
-- Marks NM placeholders: every monster listed in an NM's phList is renamed "PH <name>" so players can spot it.
-- The first time a player enters a zone, all placeholders in that zone are renamed once (the name stays through
-- respawns). The data is LSB's own: each NM script's entity.phList (keys = placeholder mob ids).
-- Names are limited to 15 characters by the client packet, so long names lose their last letters.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local prefix  = 'PH '
local maxName = 15 -- PacketNameLength 16 = 15 + terminator (src/common/utils.h)
local doneVar = '[PHMarks]Done'

local function markZone(zone)
    if zone == nil or zone:getLocalVar(doneVar) == 1 then
        return
    end

    zone:setLocalVar(doneVar, 1)

    local zoneScripts = xi.zones[zone:getName()]
    if zoneScripts == nil or zoneScripts.mobs == nil then
        return
    end

    for _, mobScript in pairs(zoneScripts.mobs) do
        if type(mobScript) == 'table' and type(mobScript.phList) == 'table' then
            for phId in pairs(mobScript.phList) do
                local ph = type(phId) == 'number' and GetMobByID(phId) or nil

                if ph then
                    local name = prefix .. ph:getName():gsub('_', ' ')
                    ph:renameEntity(name:sub(1, maxName), true)
                end
            end
        end
    end
end

local m = Module:new('mark_nm_placeholders')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    markZone(player:getZone())
end)
