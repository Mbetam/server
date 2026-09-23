-----------------------------------
-- !allmissions / !allkeyitems (modules/custom/lua/gm_unlocks.lua). Pure logic against the real mission and
-- key item tables, with a stand-in player that follows the core's own mission rules
-- (CLuaBaseEntity::addMission / completeMission / hasCompletedMission in lua_base_entity.cpp).
-----------------------------------
local unlocks = require('modules/custom/lua/gm_unlocks')
-----------------------------------

-- The core's mission log, reduced to what decides "completed".
local function fakeMissionPlayer()
    local p = { logs = {} }

    local function log(logId)
        if not p.logs[logId] then
            p.logs[logId] = { current = logId > 2 and 0 or 65535, complete = {} }
        end

        return p.logs[logId]
    end

    function p:addMission(logId, id)
        assert(id < unlocks.MAX_MISSION_ID, 'the core rejects mission id ' .. id)
        log(logId).current = id
    end

    function p:completeMission(logId, id)
        local l = log(logId)
        assert(l.current == id, string.format('the core refuses to complete %d/%d: it is not the current mission', logId, id))
        l.current = logId > 2 and 0 or 65535
        if logId ~= xi.mission.log_id.COP and id < 64 then
            l.complete[id] = true
        end
    end

    function p:hasCompletedMission(logId, id)
        local l = log(logId)
        if logId == xi.mission.log_id.COP or id >= 64 then
            return id < l.current
        end

        return l.complete[id] == true
    end

    return p
end

local function allMissions()
    local list = {}
    for _, logId in pairs(xi.mission.log_id) do
        for name, id in pairs(xi.mission.id[xi.mission.area[logId]] or {}) do
            if id ~= unlocks.NO_MISSION then
                table.insert(list, { log = logId, id = id, name = name })
            end
        end
    end

    return list
end

local function steps()
    return unlocks.missionSteps(xi.mission.log_id, xi.mission.area, xi.mission.id)
end

describe('!allmissions steps', function()
    it('completes every real mission exactly once', function()
        local count = {}
        for _, step in ipairs(steps()) do
            if step.action == 'complete' then
                local key = step.log .. '/' .. step.id
                count[key] = (count[key] or 0) + 1
            end
        end

        local total = 0
        for _, m in ipairs(allMissions()) do
            total = total + 1
            assert(count[m.log .. '/' .. m.id] == 1, string.format('%s (%d/%d) should be completed once, got %s', m.name, m.log, m.id, tostring(count[m.log .. '/' .. m.id])))
        end

        assert(total > 400, 'expected the real mission tables, found only ' .. total .. ' missions')
    end)

    it('never uses the NONE id or an id the core rejects', function()
        for _, step in ipairs(steps()) do
            assert(step.id ~= unlocks.NO_MISSION and step.id >= 0 and step.id < unlocks.MAX_MISSION_ID, 'bad id ' .. step.id)
        end
    end)

    it('goes log by log, in mission id order', function()
        local lastLog, lastId = -1, -1
        for _, step in ipairs(steps()) do
            if step.log ~= lastLog then
                assert(step.log > lastLog, 'logs out of order')
                lastLog, lastId = step.log, -1
            end

            if step.action == 'complete' then
                assert(step.id > lastId, string.format('log %d: %d came after %d', step.log, step.id, lastId))
                lastId = step.id
            end
        end
    end)

    it('leaves each non-nation log on its last mission, and nation logs on none', function()
        local finalCurrent = {}
        for _, step in ipairs(steps()) do
            if step.action == 'current' then
                assert(finalCurrent[step.log] == nil, 'log ' .. step.log .. ' is given a current mission twice')
                finalCurrent[step.log] = step.id
            end
        end

        for logId = 0, 2 do
            assert(finalCurrent[logId] == nil, 'nation log ' .. logId .. ' should end with no current mission')
        end

        assert(finalCurrent[xi.mission.log_id.COP] == xi.mission.id.cop.THE_LAST_VERSE, 'CoP should end on The Last Verse')
        assert(finalCurrent[xi.mission.log_id.ZILART] == xi.mission.id.zilart.THE_LAST_VERSE, 'Zilart should end on The Last Verse')
    end)

    it('really counts every mission (except each log\'s final one) as completed under the core\'s rules', function()
        local player = fakeMissionPlayer()
        for _, step in ipairs(steps()) do
            player:addMission(step.log, step.id)
            if step.action == 'complete' then
                player:completeMission(step.log, step.id)
            end
        end

        local finalCurrent = {}
        for _, step in ipairs(steps()) do
            if step.action == 'current' then
                finalCurrent[step.log] = step.id
            end
        end

        for _, m in ipairs(allMissions()) do
            if finalCurrent[m.log] ~= m.id then
                assert(player:hasCompletedMission(m.log, m.id), string.format('%s (%d/%d) does not count as completed', m.name, m.log, m.id))
            end
        end

        -- The spots scripts actually check, e.g. Sea access and the Pso'Xja gates.
        assert(player:hasCompletedMission(xi.mission.log_id.COP, xi.mission.id.cop.DAWN))
        assert(player:hasCompletedMission(xi.mission.log_id.ZILART, xi.mission.id.zilart.AWAKENING))
        assert(player:hasCompletedMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.THE_HEIR_TO_THE_LIGHT))
    end)
end)

describe('!allkeyitems list', function()
    it('has every real key item once, in order, and never NONE', function()
        local ids = unlocks.keyItemIds(xi.keyItem)
        local distinct = {}
        local expected = 0
        for _, id in pairs(xi.keyItem) do
            if id > 0 and not distinct[id] then
                distinct[id] = true
                expected = expected + 1
            end
        end

        assert(#ids == expected, string.format('expected %d key items, got %d', expected, #ids))
        for i, id in ipairs(ids) do
            assert(id > 0, 'NONE must not be given')
            assert(i == 1 or id > ids[i - 1], 'not sorted or not unique at ' .. i)
            assert(id < 8 * 512, 'key item ' .. id .. ' does not fit the 8 key item tables')
        end
    end)
end)

describe('batch runner', function()
    local function fakeCaller()
        local caller = { said = {}, queue = {} }
        function caller:printToPlayer(msg)
            table.insert(self.said, msg)
        end

        function caller:timer(ms, fn)
            table.insert(self.queue, { ms = ms, fn = fn })
        end

        -- Runs queued timers until none are left.
        function caller:drain()
            while #self.queue > 0 do
                local t = table.remove(self.queue, 1)
                t.fn(self)
            end
        end

        return caller
    end

    it('applies every item once, in order, a batch per timer, then calls onDone once', function()
        local target = { getName = function() return 'Someone' end }
        -- stub() reaches the global the module reads (a plain assignment here does not) and is undone after the test
        stub('GetPlayerByName', function(name) return name == 'Someone' and target or nil end)

        local items = {}
        for i = 1, 45 do
            items[i] = i
        end

        local applied, batches, done = {}, 0, 0
        local caller = fakeCaller()
        local realTimer = caller.timer
        function caller:timer(ms, fn)
            batches = batches + 1
            assert(ms == unlocks.BATCH_DELAY_MS)
            realTimer(self, ms, fn)
        end

        unlocks.runInBatches(caller, 'Someone', items, 20, 'test', function(t, item)
            assert(t == target)
            table.insert(applied, item)
        end, function()
            done = done + 1
        end)

        assert(#applied == 20, 'only the first batch should run straight away, ran ' .. #applied)
        caller:drain()
        assert(#applied == 45 and done == 1 and batches == 2, string.format('applied %d, done %d, timers %d', #applied, done, batches))
        for i = 1, 45 do
            assert(applied[i] == i, 'out of order at ' .. i)
        end
    end)

    it('stops and says so when the target is gone between batches', function()
        local target = { getName = function() return 'Someone' end }
        local online = true
        stub('GetPlayerByName', function() return online and target or nil end)

        local applied, done = 0, false
        local caller = fakeCaller()
        unlocks.runInBatches(caller, 'Someone', { 1, 2, 3, 4, 5 }, 2, 'test', function()
            applied = applied + 1
        end, function()
            done = true
        end)

        online = false
        caller:drain()
        assert(applied == 2 and not done, string.format('applied %d, done %s', applied, tostring(done)))
        assert(caller.said[#caller.said]:find('not online', 1, true), caller.said[#caller.said])
    end)
end)
