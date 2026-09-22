-----------------------------------
-- Lottery NMs: killing a placeholder (PH) always brings out the NM, and the NM can come out again straight away.
-- The game does this with two settings: NM_LOTTERY_CHANCE = -1 (always 100%) and NM_LOTTERY_COOLDOWN = 0 (no timer).
-- Each test pins them, and the controls use the game's own defaults so a pass shows the settings are what make the difference.
-- Uses Carrion Crow (PH) and Nunyenunc (NM) in West Sarutabaruta, the same pair as the spawn handler tests. Their script asks
-- for a 10% chance and a 1 hour cooldown, and it is the standard placeholder system (xi.mob.phOnDespawn) that all of the
-- ~375 placeholder scripts use. NMs with their own custom spawn code (weather NMs, the Leshys, Argus / Leech King...) are not
-- part of it.
-----------------------------------

describe('Lottery NMs', function()
    ---@type CClientEntityPair
    local player
    local ph
    local nm

    local function alwaysAndNoTimer()
        xi.test.world:setSetting('main.NM_LOTTERY_CHANCE', -1)
        xi.test.world:setSetting('main.NM_LOTTERY_COOLDOWN', 0)
    end

    -- One Vana'diel day is 57.6 real minutes: just under the NM's one hour cooldown. This moves the wall clock the cooldown is
    -- measured with (skipTime only moves the game's internal clock, which the cooldown does not use).
    local function almostAnHour()
        xi.test.world:skipVanaDays(1)
    end

    -- Kills the placeholder, waits for it to repop (5 minutes and a bit) and says whether the NM came out instead
    local function killPlaceholder()
        player:claimAndKillMob(ph)
        xi.test.world:skipTime(305)
        xi.test.world:tick(xi.tick.SPAWN)

        return nm:isSpawned()
    end

    local function killNm()
        player:claimAndKillMob(nm)
        xi.test.world:skipTime(305)
        xi.test.world:tick(xi.tick.SPAWN)
    end

    -- The zone keeps its state from one test to the next, so put the pair back to "placeholder up, NM down, no cooldown"
    local function reset()
        if nm:isSpawned() then
            killNm()
        end

        nm:setLocalVar('pop', 0)

        if not ph:isSpawned() then
            xi.test.world:skipTime(305)
            xi.test.world:tick(xi.tick.SPAWN)
        end
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_SARUTABARUTA, job = xi.job.WAR, level = 99 })

        local ID = zones[xi.zone.WEST_SARUTABARUTA]

        nm = player.entities:get(ID.mob.NUNYENUNC)
        ph = player.entities:get(ID.mob.NUNYENUNC - 1)

        assert(nm ~= nil and ph ~= nil, 'precondition: the placeholder and the NM should exist')

        reset()

        assert(ph:isSpawned() and not nm:isSpawned(), 'precondition: the placeholder should be up and the NM down')
    end)

    after_each(function()
        reset()
    end)

    it('brings the NM out the first time the placeholder is killed', function()
        alwaysAndNoTimer()

        assert(killPlaceholder(), 'the NM should have come out on the first placeholder kill')
    end)

    it('brings the NM out every single time, straight after it was killed, with no timer', function()
        alwaysAndNoTimer()

        for round = 1, 8 do
            assert(killPlaceholder(), string.format('round %d: the NM did not come out after the placeholder was killed', round))

            killNm()

            assert(not nm:isSpawned(), string.format('round %d: the NM should be dead', round))
            ph.assert:isSpawned()

            -- Less than an hour later: the game's own cooldown would still be running
            almostAnHour()
        end
    end)

    it('does not come out every time with the game\'s own 10% chance', function()
        xi.test.world:setSetting('main.NM_LOTTERY_CHANCE', 1.0)
        xi.test.world:setSetting('main.NM_LOTTERY_COOLDOWN', 0)

        local pops = 0

        for _ = 1, 6 do
            if killPlaceholder() then
                pops = pops + 1

                killNm()
                almostAnHour()
            end
        end

        -- At 10% the chance of six in a row is one in a million
        assert(pops < 6, 'with a 10% chance the NM should not come out every time, but it did ' .. pops .. ' of 6')
    end)

    it('still makes the NM wait out its cooldown when only the chance is set to always', function()
        xi.test.world:setSetting('main.NM_LOTTERY_CHANCE', -1)
        xi.test.world:setSetting('main.NM_LOTTERY_COOLDOWN', 1.0)

        assert(killPlaceholder(), 'precondition: the first kill should bring the NM out')

        killNm()
        almostAnHour()

        assert(not killPlaceholder(), 'inside the one hour cooldown the NM must not come out again')

        almostAnHour()

        assert(killPlaceholder(), 'after the cooldown the NM should come out again')
    end)
end)
