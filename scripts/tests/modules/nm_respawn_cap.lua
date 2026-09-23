-----------------------------------
-- Shorter respawn timers for timed NMs (custom core edit: src/map/utils/respawn_cap.h, applied in
-- CLuaBaseEntity::setRespawnTime). Settings (map.lua): NM_RESPAWN_CAP, HNM_RESPAWN_CAP, HNM_RESPAWN_THRESHOLD.
-- Server choice: timed NMs 2 minutes, HNMs (a retail timer of 18 h or more) 1 hour. Timers are only shortened.
-- Uses Simurgh (Rolanberry Fields, a timed NM: 1-2 h in its script), Serket (Garlaige Citadel, 21-24 h) and
-- King Arthro's Knight Crabs (Jugner Forest: its 21-24 h timer is set on the crabs, which are not NMs).
-- Never run this on prod: xi_test deletes accounts/characters with ids >= 20,000,000.
-----------------------------------

describe('NM respawn caps', function()
    ---@type CClientEntityPair
    local player

    local function serverChoice()
        xi.test.world:setSetting('map.NM_RESPAWN_CAP', 120)
        xi.test.world:setSetting('map.HNM_RESPAWN_CAP', 3600)
        xi.test.world:setSetting('map.HNM_RESPAWN_THRESHOLD', 64800)
    end

    local function gameDefaults()
        xi.test.world:setSetting('map.NM_RESPAWN_CAP', 0)
        xi.test.world:setSetting('map.HNM_RESPAWN_CAP', 0)
        xi.test.world:setSetting('map.HNM_RESPAWN_THRESHOLD', 64800)
    end

    -- getRespawnTime() is the time REMAINING, in whole seconds rounded down, so it can read one second under what was set
    local function near(actual, expected)
        return actual == expected or actual == expected - 1
    end

    local function simurgh()
        return GetMobByID(zones[xi.zone.ROLANBERRY_FIELDS].mob.SIMURGH)
    end

    local function serket()
        return GetMobByID(zones[xi.zone.GARLAIGE_CITADEL].mob.SERKET)
    end

    local function knightCrab()
        return GetMobByID(zones[xi.zone.JUGNER_FOREST].mob.KING_ARTHRO - 1)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.ROLANBERRY_FIELDS, job = xi.job.WAR, level = 99 })

        -- xi_test loads zones lazily (only when a player enters): put someone in the other two zones so they exist
        xi.test.world:spawnPlayer({ zone = xi.zone.GARLAIGE_CITADEL })
        xi.test.world:spawnPlayer({ zone = xi.zone.JUGNER_FOREST })

        assert(simurgh() and simurgh():isNM(), 'precondition: Simurgh should exist and be an NM')
        assert(serket() and serket():isNM(), 'precondition: Serket should exist and be an NM')
        assert(knightCrab() and not knightCrab():isNM(), 'precondition: the Knight Crab should exist and NOT be an NM')
    end)

    after_each(function()
        serverChoice() -- the server's own values, so later tests in the run see what prod runs
    end)

    it('caps a timed NM at 2 minutes', function()
        serverChoice()
        simurgh():setRespawnTime(5400)

        assert(near(simurgh():getRespawnTime(), 120), 'Simurgh 90 min should become 120 s, got ' .. simurgh():getRespawnTime())
    end)

    it('caps an HNM (18 h or more) at 1 hour, not 2 minutes', function()
        serverChoice()
        serket():setRespawnTime(86400)

        assert(near(serket():getRespawnTime(), 3600), 'Serket 24 h should become 3600 s, got ' .. serket():getRespawnTime())
    end)

    it('caps King Arthro\'s 21 h crab timer at 1 hour although the crabs are not NMs', function()
        serverChoice()
        knightCrab():setRespawnTime(75900)

        assert(near(knightCrab():getRespawnTime(), 3600), 'the crab should become 3600 s, got ' .. knightCrab():getRespawnTime())
    end)

    it('leaves an ordinary mob\'s timer and short NM timers alone', function()
        serverChoice()
        knightCrab():setRespawnTime(3600)
        assert(near(knightCrab():getRespawnTime(), 3600), 'an ordinary mob under the HNM threshold must keep its timer')

        simurgh():setRespawnTime(60)
        assert(near(simurgh():getRespawnTime(), 60), 'a timer below the cap must not be lengthened')
    end)

    it('changes nothing with the game\'s defaults (caps 0)', function()
        gameDefaults()
        simurgh():setRespawnTime(5400)
        serket():setRespawnTime(86400)

        assert(near(simurgh():getRespawnTime(), 5400) and near(serket():getRespawnTime(), 86400), 'with the caps off, timers must be the game\'s own')
    end)

    it('brings Simurgh back 2 minutes after it despawns, through its own script', function()
        serverChoice()

        local mob = player.entities:get(zones[xi.zone.ROLANBERRY_FIELDS].mob.SIMURGH)
        if not mob:isSpawned() then
            mob:setRespawnTime(1)
            xi.test.world:skipTime(5)
            xi.test.world:tick(xi.tick.SPAWN)
        end

        assert(mob:isSpawned(), 'precondition: Simurgh should be up')

        player:claimAndKillMob(mob) -- its onMobDespawn asks for 1-2 hours
        assert(near(mob:getRespawnTime(), 120), 'after its own despawn script, the timer should be 120 s, got ' .. mob:getRespawnTime())

        xi.test.world:skipTime(125)
        xi.test.world:tick(xi.tick.SPAWN)
        assert(mob:isSpawned(), 'Simurgh should be back 2 minutes after despawning')
    end)
end)
