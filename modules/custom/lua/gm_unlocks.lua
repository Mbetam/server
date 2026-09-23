-----------------------------------
-- Shared logic for the !allmissions and !allkeyitems GM commands.
-- This is a helper file, not a module: it registers nothing and is only loaded when a command module requires it.
--
-- Every addMission/completeMission/addKeyItem call saves to the database straight away, so doing all of them
-- in one go (about 1,000 mission saves, about 3,000 key item saves) could hold up the main tick for more than
-- 2 seconds and trip the inactivity watchdog, which kills xi_map for everyone. The work is therefore done in
-- small batches, half a second apart, the same way the built-in !addallspells does it.
-----------------------------------

local unlocks = {}

unlocks.MAX_MISSION_ID = 851   -- MAX_MISSIONID in src/map/entities/char_entity.h: addMission rejects anything at or above it
unlocks.NO_MISSION     = 65535 -- the NONE entries in the mission id tables
unlocks.BATCH_DELAY_MS = 500

-- The steps that mark every mission in every log as completed, in order.
-- logIds:   xi.mission.log_id
-- areas:    xi.mission.area (log id -> name)
-- idTables: xi.mission.id (name -> { MISSION_NAME = id })
--
-- The core records "completed" in two ways (CLuaBaseEntity::hasCompletedMission):
--   * nation logs, and ids under 64 in the others: one completed flag per mission;
--   * CoP, and ids 64 and up in any log: completed means "below the current mission".
-- So each mission is added then completed, in id order, and each non-nation log then gets its LAST mission
-- back as the current one. That leaves everything before it counted as completed either way, which is the
-- same state a player who finished the story normally is in (their last mission stays current).
function unlocks.missionSteps(logIds, areas, idTables)
    local logs = {}
    for _, logId in pairs(logIds) do
        table.insert(logs, logId)
    end

    table.sort(logs)

    local steps = {}
    for _, logId in ipairs(logs) do
        local ids = {}
        local seen = {}
        for _, id in pairs(idTables[areas[logId]] or {}) do
            if
                type(id) == 'number' and
                id >= 0 and
                id < unlocks.MAX_MISSION_ID and
                not seen[id]
            then
                seen[id] = true
                table.insert(ids, id)
            end
        end

        table.sort(ids)

        for _, id in ipairs(ids) do
            table.insert(steps, { log = logId, id = id, action = 'complete' })
        end

        if logId > 2 and #ids > 0 then
            table.insert(steps, { log = logId, id = ids[#ids], action = 'current' })
        end
    end

    return steps
end

-- Every real key item id in xi.keyItem, once each, in order. 0 is NONE.
function unlocks.keyItemIds(keyItemEnum)
    local ids = {}
    local seen = {}
    for _, id in pairs(keyItemEnum) do
        if type(id) == 'number' and id > 0 and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end

    table.sort(ids)

    return ids
end

-- Calls apply(target, item) for every entry of items, batchSize at a time, BATCH_DELAY_MS apart.
-- The target is looked up by name before every batch; if they logged out or are mid-zone, it stops and says so.
-- Timers run on the caller, so the caller should also stay put until the done message.
function unlocks.runInBatches(caller, targetName, items, batchSize, label, apply, onDone)
    local function runFrom(callerArg, first)
        local target = GetPlayerByName(targetName)
        if target == nil then
            callerArg:printToPlayer(string.format('%s: stopped, %s is not online right now (logged out or mid-zone). Run it again, it is safe to repeat.', label, targetName), xi.msg.channel.SYSTEM_3)
            return
        end

        local last = math.min(first + batchSize - 1, #items)
        for i = first, last do
            apply(target, items[i])
        end

        if last >= #items then
            if onDone then
                onDone(target)
            end

            callerArg:printToPlayer(string.format('%s: done for %s (%d).', label, target:getName(), #items), xi.msg.channel.SYSTEM_3)
            return
        end

        callerArg:printToPlayer(string.format('%s: %d of %d...', label, last, #items), xi.msg.channel.SYSTEM_3)
        callerArg:timer(unlocks.BATCH_DELAY_MS, function(nextCaller)
            runFrom(nextCaller, last + 1)
        end)
    end

    runFrom(caller, 1)
end

-- The player the command should act on: the named one, or the caller. Nil (with a message) if not found.
function unlocks.findTarget(caller, targetName, usage)
    if targetName == nil or targetName == '' then
        return caller
    end

    local target = GetPlayerByName(targetName)
    if target == nil then
        caller:printToPlayer(string.format('Player named "%s" not found! (They must be online.)', targetName))
        caller:printToPlayer(usage)
    end

    return target
end

return unlocks
