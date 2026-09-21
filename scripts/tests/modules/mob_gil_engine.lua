-----------------------------------
-- The mob gil floor in the real engine: a real player kills a real mob and receives real gil.
-----------------------------------

describe('Mob gil floor in the engine', function()
    ---@type CClientEntityPair
    local player
    local mob

    -- Respawns the mob with exactly these gil mods (the respawn resets whatever it had), then kills it
    local function kill(mods)
        mob:respawn()
        mob:setMobMod(xi.mobMod.GIL_MIN, mods.min or 0)
        mob:setMobMod(xi.mobMod.GIL_MAX, mods.max or 0)

        player.entities:moveTo(mob)
        player:claimAndKillMob(mob)
    end

    before_each(function()
        -- Pin what the numbers depend on, so an operator's own settings cannot change the answer
        xi.test.world:setSetting('map.MOB_GIL_MULTIPLIER', 2)
        xi.test.world:setSetting('map.ALL_MOBS_GIL_BONUS', 0)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.IFRITS_CAULDRON, job = xi.job.WAR, level = 99 })
        player:setGil(0)

        mob = player.entities:get('Volcanic_Bomb')
    end)

    it('makes a mob with no gil of its own drop 500', function()
        kill({})

        assert(player:getGil() == 500, 'an ordinary mob should drop exactly 500 gil but dropped ' .. player:getGil())
    end)

    it('raises a small natural drop to 500', function()
        kill({ min = 10, max = 20 })

        assert(player:getGil() == 500, 'a 10-20 gil mob (x2) should be raised to 500 but dropped ' .. player:getGil())
    end)

    it('does not lower a bigger natural drop', function()
        kill({ min = 3000, max = 3000 })

        assert(player:getGil() == 6000, 'a 3,000 gil mob (x2) should still drop 6,000 but dropped ' .. player:getGil())
    end)

    it('drops nothing for a mob the game marks as never dropping gil', function()
        kill({ max = -1 })

        assert(player:getGil() == 0, 'a mob with a negative gil maximum must not drop gil but dropped ' .. player:getGil())
    end)

    it('still delivers 500 if the gil multiplier changes', function()
        xi.test.world:setSetting('map.MOB_GIL_MULTIPLIER', 1)

        kill({})

        assert(player:getGil() == 500, 'with a x1 multiplier the drop should still be 500 but was ' .. player:getGil())
    end)

    it('keeps paying on every kill', function()
        kill({})
        kill({})
        kill({})

        assert(player:getGil() == 1500, 'three kills should pay 1,500 gil in total but paid ' .. player:getGil())
    end)
end)
