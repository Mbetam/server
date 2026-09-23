-----------------------------------
-- !dummy in the real engine: spawns a training dummy that takes damage, never fights back, never dies, and can be removed.
-----------------------------------

describe('!dummy', function()
    ---@type CClientEntityPair
    local player

    local function dummyOf(p)
        local id = p:getLocalVar('[Dummy]Id')

        return id ~= 0 and GetMobByID(id) or nil
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
    end)

    it('spawns a dummy at the chosen level and HP, in front of the player', function()
        xi.commands.dummy.onTrigger(player, '75', '250000')
        xi.test.world:skipTime(2)

        local dummy = dummyOf(player)
        assert(dummy and dummy:isSpawned(), 'no dummy')
        assert(dummy:getMainLvl() == 75, 'level ' .. dummy:getMainLvl())
        -- the base monster's HP bonuses can add a little on top of the requested HP
        assert(dummy:getMaxHP() >= 250000 and dummy:getMaxHP() < 251000 and dummy:getHP() == dummy:getMaxHP(), 'HP ' .. dummy:getHP() .. '/' .. dummy:getMaxHP())
        assert(player:checkDistance(dummy) < 5, 'too far away: ' .. player:checkDistance(dummy))
    end)

    it('takes damage but never attacks or moves', function()
        xi.commands.dummy.onTrigger(player, nil, nil)
        xi.test.world:skipTime(2)

        local dummy = dummyOf(player)
        local x, z  = dummy:getXPos(), dummy:getZPos()
        player:setMod(xi.mod.ACC, 1000)
        player.actions:engage(dummy)

        for _ = 1, 15 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end

        assert(dummy:getHP() < dummy:getMaxHP(), 'the dummy took no damage')
        assert(player:getHP() == player:getMaxHP(), 'the dummy hit the player')
        assert(math.abs(dummy:getXPos() - x) < 0.5 and math.abs(dummy:getZPos() - z) < 0.5, 'the dummy moved')
    end)

    it('heals back to full instead of dying', function()
        xi.commands.dummy.onTrigger(player, '10', '1000')
        xi.test.world:skipTime(2)

        local dummy = dummyOf(player)
        player:setMod(xi.mod.ACC, 1000)
        player.actions:engage(dummy)
        dummy:setHP(50)

        for _ = 1, 10 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end

        assert(dummy:isSpawned() and dummy:isAlive(), 'the dummy died')
        assert(dummy:getHPP() > 10, 'the dummy did not heal: ' .. dummy:getHPP() .. '%')
    end)

    -- Gone = no longer found by ID, or found but not spawned. Look it up again each time: a despawned dynamic
    -- entity is deleted, so an old reference to it must not be used.
    local function gone(id)
        local mob = GetMobByID(id)

        return mob == nil or not mob:isSpawned()
    end

    local function waitForDespawn()
        for _ = 1, 10 do
            xi.test.world:skipTime(2)
        end
    end

    it('is removed by !dummy clear, and a new !dummy replaces the old one', function()
        xi.commands.dummy.onTrigger(player, nil, nil)
        xi.test.world:skipTime(2)
        local firstId = player:getLocalVar('[Dummy]Id')

        xi.commands.dummy.onTrigger(player, '50', nil)
        waitForDespawn()
        local secondId = player:getLocalVar('[Dummy]Id')

        assert(secondId ~= 0 and GetMobByID(secondId):getMainLvl() == 50, 'no second dummy')
        assert(gone(firstId), 'the old dummy was not removed')

        xi.commands.dummy.onTrigger(player, 'clear', nil)
        waitForDespawn()

        assert(gone(secondId), '!dummy clear did not remove it')
        assert(player:getLocalVar('[Dummy]Id') == 0)
    end)
end)
