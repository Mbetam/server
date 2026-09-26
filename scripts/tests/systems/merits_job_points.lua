-----------------------------------
-- Merit points and job points, end to end through the client's own packets (docs/custom/NOTES.md, 2026-09-26):
-- earning them, spending them (0x0BE merit menu in a Mog House, 0x0BF job point menu) and the spent points taking
-- effect in game.
-----------------------------------
local ffi = require('ffi')

describe('Merits and job points', function()
    local function meritPacket(player, kind, param1, param2)
        local packet = ffi.new('uint8_t[12]')
        packet[4]    = kind
        packet[5]    = param1
        packet[6]    = bit.band(param2, 0xFF)
        packet[7]    = bit.rshift(param2, 8)
        player.packets:send(0x0BE, packet, ffi.sizeof(packet) or 0)
    end

    local function raiseMerit(player, merit)
        meritPacket(player, 3, 1, bit.rshift(merit, 1)) -- EditMode, Raise, merit id >> 1
    end

    local function spendJobPoint(player, jpType)
        local packet = ffi.new('uint8_t[8]')
        packet[4]    = bit.band(jpType, 0xFF)
        packet[5]    = bit.rshift(jpType, 8)
        player.packets:send(0x0BF, packet, ffi.sizeof(packet) or 0)
    end

    it('Limit Point mode turns EXP into merit points at 99', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        meritPacket(player, 2, 1, 0) -- ChangeMode -> Limit Points
        xi.test.world:skipTime(1)

        local before = player:getMeritCount()
        player:addExp(30000, true)
        assert(player:getMeritCount() > before, string.format('merit points %d -> %d after 30000 limit points', before, player:getMeritCount()))
    end)

    it('raising the HP merit in the Mog House raises max HP', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WINDURST_WOODS, job = xi.job.WAR, level = 99 })
        if player:isInEvent() then
            player.events:finish() -- new characters arrive with a cutscene
        end

        player:gotoMogHouse(xi.zone.WINDURST_WOODS)
        if player:isInEvent() then
            player.events:finish() -- entering the Mog House plays an event; the merit menu is refused during it
        end

        player:setMerits(10)

        local maxHP = player:getMaxHP()
        raiseMerit(player, xi.merit.MAX_HP)
        xi.test.world:skipTime(1)

        assert(player:getMerit(xi.merit.MAX_HP) > 0, 'HP merit not raised')
        assert(player:getMaxHP() > maxHP, string.format('max HP %d -> %d', maxHP, player:getMaxHP()))
        assert(player:getMeritCount() < 10, 'the merit point was not spent')
    end)

    it('a merit ability works once merited (PLD Fealty)', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WINDURST_WOODS, job = xi.job.PLD, level = 99 })
        if player:isInEvent() then
            player.events:finish()
        end

        player:gotoMogHouse(xi.zone.WINDURST_WOODS)
        if player:isInEvent() then
            player.events:finish() -- entering the Mog House plays an event; the merit menu is refused during it
        end

        player:setMerits(10)
        raiseMerit(player, xi.merit.FEALTY)
        xi.test.world:skipTime(1)
        assert(player:getMerit(xi.merit.FEALTY) > 0, 'Fealty merit not raised')

        player:gotoZone(xi.zone.WEST_RONFAURE)
        xi.test.world:skipTime(2)
        player.actions:useAbility(player, xi.jobAbility.FEALTY)
        xi.test.world:skipTime(3)
        assert(player:hasStatusEffect(xi.effect.FEALTY), 'Fealty did not work after meriting it')
    end)

    it('capacity points turn into job points at 99', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        local before = player:getJobPoints(xi.job.WAR)
        player:addCapacityPoints(35000)
        assert(player:getJobPoints(xi.job.WAR) > before, string.format('job points %d -> %d after 35000 CP', before, player:getJobPoints(xi.job.WAR)))
    end)

    it('spending a job point raises its level and Berserk uses it', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setJobPoints(100)

        player.actions:useAbility(player, xi.jobAbility.BERSERK)
        xi.test.world:skipTime(2)
        local plain = player:getStat(xi.mod.ATT)
        player:delStatusEffect(xi.effect.BERSERK)

        -- Job points can only be spent in a Mog House (as on retail)
        player:gotoMogHouse(xi.zone.WINDURST_WOODS)
        if player:isInEvent() then
            player.events:finish()
        end

        for _ = 1, 5 do
            spendJobPoint(player, xi.jp.BERSERK_EFFECT)
        end

        xi.test.world:skipTime(1)
        assert(player:getJobPointLevel(xi.jp.BERSERK_EFFECT) == 5, 'Berserk effect JP level is ' .. player:getJobPointLevel(xi.jp.BERSERK_EFFECT))
        assert(player:getSpentJobPoints() > 0, 'no job points recorded as spent')

        player:gotoZone(xi.zone.WEST_RONFAURE)
        xi.test.world:skipTime(2)
        player:resetRecasts()
        player.actions:useAbility(player, xi.jobAbility.BERSERK)
        xi.test.world:skipTime(2)
        assert(player:getStat(xi.mod.ATT) > plain, string.format('Berserk attack %d with 5 JP vs %d without', player:getStat(xi.mod.ATT), plain))
    end)

    -- modules/custom/lua/limit_job_breaker.lua: players skip the limit-break quests, so the key items are given
    it('a level 99 gets Limit Breaker and Job Breaker at login; a level 80 only Limit Breaker', function()
        local p99 = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        local p80 = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 80 })

        -- Test spawns do not run the login hook; the module acts on login / zone change with a short delay
        xi.player.onGameIn(p99, false, true)
        xi.player.onGameIn(p80, false, true)
        xi.test.world:skipTime(5)

        assert(p99:hasKeyItem(xi.keyItem.LIMIT_BREAKER) and p99:hasKeyItem(xi.keyItem.JOB_BREAKER), 'level 99 should have both')
        assert(p80:hasKeyItem(xi.keyItem.LIMIT_BREAKER), 'level 80 should have Limit Breaker')
        assert(not p80:hasKeyItem(xi.keyItem.JOB_BREAKER), 'level 80 must not have Job Breaker')
    end)

    it('reaching 99 grants Job Breaker', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 98 })
        xi.player.onGameIn(player, false, true)
        xi.test.world:skipTime(5)
        assert(not player:hasKeyItem(xi.keyItem.JOB_BREAKER), 'level 98 must not have Job Breaker yet')

        -- Test characters cannot level past their spawn level with EXP, so level up directly and run the level-up hook
        player:setLevel(99)
        xi.player.onPlayerLevelUp(player)
        assert(player:hasKeyItem(xi.keyItem.JOB_BREAKER), 'Job Breaker not given on reaching 99')
    end)
end)
