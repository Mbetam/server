-----------------------------------
-- The !city command in the real engine: a real player really changes zone and arrives at the Home Point crystal.
-----------------------------------

describe('!city in the engine', function()
    ---@type CClientEntityPair
    local player

    local function settle()
        for _ = 1, 8 do
            xi.test.world:skipTime(1)
        end
    end

    local function near(actual, expected)
        return math.abs(actual - expected) < 0.5
    end

    local cities =
    {
        { name = 'sandoria', zone = xi.zone.SOUTHERN_SAN_DORIA, x = -85.468, z = -66.454 },
        { name = 'bastok',   zone = xi.zone.BASTOK_MARKETS,     x = -344.0,  z = -155.0 },
        { name = 'windurst', zone = xi.zone.WINDURST_WOODS,     x = 9.088,   z = -0.383 },
        { name = 'jeuno',    zone = xi.zone.LOWER_JEUNO,        x = -98.588, z = -183.416 },
    }

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
    end)

    for _, city in ipairs(cities) do
        it('takes the player to ' .. city.name, function()
            xi.commands.city.onTrigger(player, city.name)
            settle()

            assert(player:getZoneID() == city.zone, string.format('!city %s should end in zone %d but the player is in zone %d', city.name, city.zone, player:getZoneID()))
            assert(near(player:getXPos(), city.x) and near(player:getZPos(), city.z),
                string.format('the player arrived at %.1f, %.1f instead of the crystal at %.1f, %.1f', player:getXPos(), player:getZPos(), city.x, city.z))
        end)
    end

    it('lets the player go on from one city to another', function()
        xi.commands.city.onTrigger(player, 'bastok')
        settle()

        -- A new character zoning into a city is put in an arrival event, and !city correctly refuses during an event
        player:release()
        xi.commands.city.onTrigger(player, 'windurst')
        settle()

        assert(player:getZoneID() == xi.zone.WINDURST_WOODS, 'the second trip should have worked too')
    end)

    it('does nothing for a KO\'d player', function()
        player:die({ expLoss = false })
        xi.test.world:tickEntity(player)
        assert(player:isDead(), 'precondition: the player should be dead')

        xi.commands.city.onTrigger(player, 'jeuno')
        settle()

        assert(player:getZoneID() == xi.zone.WEST_RONFAURE, 'a KO\'d player should not be teleported')
    end)

    it('works from inside a Mog House', function()
        player:gotoMogHouse(xi.zone.SOUTHERN_SAN_DORIA)
        settle()
        player:release() -- the Mog House entrance is an event too

        xi.commands.city.onTrigger(player, 'bastok')
        settle()

        assert(player:getZoneID() == xi.zone.BASTOK_MARKETS, 'leaving a Mog House by !city should work; the player is in zone ' .. player:getZoneID())
    end)
end)
