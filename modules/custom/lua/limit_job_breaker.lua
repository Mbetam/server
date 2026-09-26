-----------------------------------
-- Gives the Limit Breaker and Job Breaker key items without the limit-break quests (Eric's choice, 2026-09-26).
-- Players start with a level 99 cap and skip Maat's quests, so they never got these two key items, and:
--   Limit Breaker (quest "New Worlds Await"): needed to switch to Limit Point (merit) mode from level 75.
--   Job Breaker (Nomad Moogle after "Beyond Infinity"): needed to earn capacity points, so without it no job points.
-- Granted once any job reaches 75 / 99, checked at every login / zone change and on every level up.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/npc_util')
-----------------------------------

local m = Module:new('limit_job_breaker')

local grants =
{
    { level = 75, keyItem = xi.keyItem.LIMIT_BREAKER },
    { level = 99, keyItem = xi.keyItem.JOB_BREAKER   },
}

local function highestJobLevel(player)
    local highest = player:getMainLvl()

    for job = 1, 22 do -- WAR .. RUN
        highest = math.max(highest, player:getJobLevel(job))
    end

    return highest
end

local function grant(player)
    local level = highestJobLevel(player)

    for _, entry in ipairs(grants) do
        if level >= entry.level and not player:hasKeyItem(entry.keyItem) then
            npcUtil.giveKeyItem(player, entry.keyItem)
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    -- After the zone has finished loading the player, so the key item message is shown
    player:timer(3000, function(playerArg)
        grant(playerArg)
    end)
end)

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    grant(player)
end)

return m
