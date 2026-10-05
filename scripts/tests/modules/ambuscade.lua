-----------------------------------
-- Ambuscade (custom, modules/custom/ambuscade/): Gorpa-Masorpa's exchange (Hallmarks / Gallantry for the retail
-- rewards, no limits; trade a piece to upgrade it), and the wave run from the Ambuscade Tome (3 / 5 / 7 / 10 waves of
-- Legion beasts, then a level 128 boss, in a private Maquette Abdhaljs-Legion B).
-----------------------------------

describe('Ambuscade (custom)', function()
    ---@type CClientEntityPair
    local player
    local config = require('modules/custom/ambuscade/amb_config')
    local arena  = xi.custom.htbfArena
    local waves  = xi.custom.ambuscadeWaves
    local shop   = require('modules/custom/ambuscade/amb_shop')
    local menu   = nil
    local menus  = {}
    local lines  = {}
    local say

    local function pick(label)
        assert(menu ~= nil, 'no menu is open (wanted "' .. label .. '")')

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                local who = menu.player
                menu = nil
                option[2](who)

                return
            end
        end

        local labels = {}
        for _, option in ipairs(menu.options) do
            table.insert(labels, option[1])
        end

        error('no option "' .. label .. '" in the menu "' .. tostring(menu.title) .. '": ' .. table.concat(labels, ' | '))
    end

    local function lastLine()
        return lines[#lines] or ''
    end

    local function toMhaura()
        if player:getZoneID() ~= xi.zone.MHAURA then
            player:gotoZone(xi.zone.MHAURA)
        end
    end

    -- Opens a run of `runIndex` at the Mhaura tome; returns the instance
    local function enterRun(runIndex)
        toMhaura()
        player.entities:gotoAndTrigger('Ambuscade_Tome')
        pick(string.format('%d waves', config.runs[runIndex].waves))
        xi.test.world:tick(xi.tick.TIME)
        xi.test.world:skipTime(2)

        assert(player:getZoneID() == config.instance.zoneId, string.format('not in Maquette Abdhaljs-Legion B (zone %d)', player:getZoneID()))
        local instance = player:getInstance()
        assert(instance and instance:getID() == config.instance.instanceId, 'not in the Ambuscade instance')
        assert(instance:getLocalVar('run') == runIndex, 'the run has the wrong length')

        return instance
    end

    -- No AI tick inside an instance in tests (see htbf.lua): a kill is the damage only
    local function killAll(instance)
        for _, mob in ipairs(waves.monsters(instance)) do
            mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)
            assert(not mob:isAlive(), mob:getName() .. ' survived')
        end
    end

    -- One instance tick, with the wave timer already run out (wall clock: skipTime does not move it)
    local function tickNow(instance)
        if instance:getLocalVar('nextWaveAt') > 0 then
            instance:setLocalVar('nextWaveAt', GetSystemTime())
        end

        waves.instanceObject.onInstanceTimeUpdate(instance, 0)
    end

    before_each(function()
        menu  = nil
        menus = {}
        lines = {}
        arena.setMenuSender(function(who, sent)
            sent.player = who
            menu        = sent
            table.insert(menus, sent)
        end)
        say       = arena.say
        arena.say = function(who, message, speaker)
            table.insert(lines, message)
        end
        player = xi.test.world:spawnPlayer({ zone = xi.zone.MHAURA, job = xi.job.WAR, level = 99 })
    end)

    after_each(function()
        arena.setMenuSender(nil)
        arena.say = say
    end)

    -----------------------------------
    -- The exchange
    -----------------------------------
    it('every menu and chat line of the exchange and the tome fits the 150-byte chat packet', function()
        player:setCurrency('current_hallmarks', 9999999)
        player:setCurrency('gallantry', 9999999)
        player.entities:gotoAndTrigger('Gorpa-Masorpa')

        -- Walk every page
        pick('Armor')
        for slot = 1, 5 do
            shop.showSets(player, slot, 1)
            shop.showSets(player, slot, 2)
        end

        shop.showRings(player, 1)
        shop.showRings(player, 2)
        shop.showCape(player)

        for groupIndex, group in ipairs(config.goods) do
            for page = 1, math.ceil(#group.items / 5) do
                shop.showGoods(player, groupIndex, page)
            end

            for itemIndex = 1, #group.items do
                shop.showQuantity(player, groupIndex, itemIndex, 1)
            end
        end

        -- The upgrade question for the longest names
        for setIndex = 1, #config.sets do
            for slot = 1, 5 do
                for grade = 1, 2 do
                    local _, price = shop.upgradeCost(slot, grade - 1)
                    local title    = string.format('Make it %s for %s Gallantry?', shop.pieceName(setIndex, slot, grade), shop.number(price))
                    assert(#title + 9 <= arena.menuLimit, title)
                end
            end
        end

        toMhaura()
        player.entities:gotoAndTrigger('Ambuscade_Tome')

        assert(#menus > 20, 'only ' .. #menus .. ' menus were shown')

        for _, sent in ipairs(menus) do
            assert(arena.menuLength(sent) <= arena.menuLimit, string.format('menu "%s" is %d bytes', sent.title, arena.menuLength(sent)))
        end

        for _, line in ipairs(lines) do
            assert(#line <= arena.menuLimit, string.format('chat line is %d bytes: %s', #line, line))
        end
    end)

    it('every item the exchange sells exists, and the gear is the right slot', function()
        for _, set in ipairs(config.sets) do
            assert(GetReadOnlyItem(set.ring) ~= nil, set.name .. ' ring missing')

            for slot, piece in ipairs(set.pieces) do
                for grade = 2, 4 do
                    assert(GetReadOnlyItem(piece[grade]) ~= nil, string.format('%s %s grade %d (%d) missing', set.name, piece[1], grade - 2, piece[grade]))
                end
            end
        end

        for job = xi.job.WAR, xi.job.RUN do
            assert(GetReadOnlyItem(config.cape(job)) ~= nil, 'no cape for job ' .. job)
        end

        for _, group in ipairs(config.goods) do
            for _, entry in ipairs(group.items) do
                assert(GetReadOnlyItem(entry[2]) ~= nil, entry[1] .. ' missing')
            end
        end
    end)

    it('materials: any quantity, no limit, Hallmarks taken only when the items are given', function()
        player:setCurrency('current_hallmarks', 10000)
        player.entities:gotoAndTrigger('Gorpa-Masorpa')
        pick('Materials')
        pick('Pluton 50')
        pick('x99 (4,950)')
        assert(player:getItemCount(4059) == 99, 'got ' .. player:getItemCount(4059) .. ' Pluton')
        assert(player:getCurrency('current_hallmarks') == 10000 - 4950, 'Hallmarks left: ' .. player:getCurrency('current_hallmarks'))

        -- Again: no monthly limit
        shop.showQuantity(player, 1, 1, 1)
        pick('x99 (4,950)')
        assert(player:getItemCount(4059) == 198, 'the second purchase did not go through')
        assert(player:getCurrency('current_hallmarks') == 100, 'Hallmarks left: ' .. player:getCurrency('current_hallmarks'))

        -- Not enough
        shop.showQuantity(player, 1, 1, 1)
        pick('x10 (500)')
        assert(player:getItemCount(4059) == 198, 'sold without the Hallmarks')
        assert(player:getCurrency('current_hallmarks') == 100, 'Hallmarks taken for nothing')
    end)

    it('armor, ring and cape: bought with Hallmarks; a Rare piece you have is not sold twice', function()
        player:setCurrency('current_hallmarks', 5000)
        player.entities:gotoAndTrigger('Gorpa-Masorpa')
        pick('Armor')
        pick('Head 250')
        pick('Sulevia\'s')
        pick('Yes')
        assert(player:hasItem(25659), 'no Sulevia\'s Mask')
        assert(player:getCurrency('current_hallmarks') == 4750, 'Hallmarks left: ' .. player:getCurrency('current_hallmarks'))

        shop.showSets(player, 1, 1)
        pick('Sulevia\'s')
        pick('Yes')
        assert(player:getCurrency('current_hallmarks') == 4750, 'charged for a Rare piece that could not be given')

        shop.showRings(player, 2)
        pick('Flamma')
        pick('Yes')
        assert(player:hasItem(26211), 'no Flamma Ring')

        shop.showCape(player)
        pick('Yes')
        assert(player:hasItem(26246), 'no Cichol\'s Mantle for a WAR')
        assert(player:getCurrency('current_hallmarks') == 4750 - 1000 - 500, 'Hallmarks left: ' .. player:getCurrency('current_hallmarks'))
    end)

    it('trading a piece upgrades it: +1 for Gallantry, +2 for Hallmarks', function()
        player:addItem(25745) -- Sulevia's Platemail
        player:setCurrency('gallantry', 2000)
        player:setCurrency('current_hallmarks', 6500)

        player.actions:tradeNpc('Gorpa-Masorpa', { 25745 })
        pick('Yes')
        assert(player:hasItem(25746) and not player:hasItem(25745), 'not upgraded to +1')
        assert(player:getCurrency('gallantry') == 200, 'Gallantry left: ' .. player:getCurrency('gallantry'))

        player.actions:tradeNpc('Gorpa-Masorpa', { 25746 })
        pick('Yes')
        assert(player:hasItem(25790) and not player:hasItem(25746), 'not upgraded to +2')
        assert(player:getCurrency('current_hallmarks') == 500, 'Hallmarks left: ' .. player:getCurrency('current_hallmarks'))

        -- Not enough: nothing changes
        player:addItem(25800) -- Sulevia's Gauntlets, +1 costs 450 Gallantry
        player.actions:tradeNpc('Gorpa-Masorpa', { 25800 })
        pick('Yes')
        assert(player:hasItem(25800) and not player:hasItem(25801), 'upgraded without the Gallantry')
        assert(player:getCurrency('gallantry') == 200, 'Gallantry taken for nothing')
    end)

    -----------------------------------
    -- The wave run
    -----------------------------------
    it('the stages and strength spread over every run length', function()
        -- 3 waves: Mired, Veiled; 10 waves: Lofty x2, Mired x2, Soaring x2, Veiled x3
        assert(waves.stageFor(1, 2) == 2 and waves.stageFor(2, 2) == 4, '3-wave stages')

        local ten = {}
        for wave = 1, 9 do
            table.insert(ten, waves.stageFor(wave, 9))
        end

        assert(table.concat(ten, ',') == '1,1,2,2,3,3,4,4,4', '10-wave stages: ' .. table.concat(ten, ','))

        for _, run in ipairs(config.runs) do
            local regular = run.waves - 1
            assert(waves.scaleFor(1, regular).level == config.waveScale.first.level or regular == 1, 'first wave level')
            assert(waves.scaleFor(regular, regular).level == config.waveScale.last.level, 'last regular wave level')

            for wave = 2, regular do
                assert(waves.scaleFor(wave, regular).hp >= waves.scaleFor(wave - 1, regular).hp, 'HP does not rise')
            end
        end
    end)

    it('the tome takes the party in; the wing is walkable where the run puts people and monsters', function()
        local member = xi.test.world:spawnPlayer({ zone = xi.zone.MHAURA, job = xi.job.WHM, level = 99 })
        player.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        toMhaura()
        player.entities:gotoAndTrigger('Ambuscade_Tome')
        member:setPos(player:getXPos() + 2, player:getYPos(), player:getZPos())
        pick('3 waves')
        xi.test.world:tick(xi.tick.TIME)
        xi.test.world:skipTime(2)

        local instance = player:getInstance()
        assert(instance and instance:getID() == config.instance.instanceId, 'not in the Ambuscade instance')
        assert(member:getInstance() and member:getInstance():getID() == instance:getID(), 'the party member was not taken in')

        local zone   = player:getZone()
        local spawn  = config.instance.spawn
        local points =
        {
            { config.instance.entry[1], config.instance.entry[2], config.instance.entry[3] },
            { config.instance.tome.pos[1], config.instance.tome.pos[2], config.instance.tome.pos[3] },
            { spawn[1], spawn[2], spawn[3] },
            { spawn[1] + config.instance.spread, spawn[2], spawn[3] },
            { spawn[1] - config.instance.spread, spawn[2], spawn[3] },
            { spawn[1], spawn[2], spawn[3] + config.instance.spread },
            { spawn[1], spawn[2], spawn[3] - config.instance.spread },
        }

        for _, p in ipairs(points) do
            assert(zone:isNavigablePoint({ x = p[1], y = p[2], z = p[3] }), string.format('(%.0f, %.0f, %.0f) is off the navmesh', p[1], p[2], p[3]))
        end

        local names = {}
        for _, npc in pairs(instance:getNpcs()) do
            names[npc:getName()] = true
        end

        assert(names['DE_' .. config.instance.tome.name], 'no tome inside')
    end)

    it('a 3-wave run: two packs, then the level 128 boss; a clear pays everyone inside', function()
        player:setCurrency('current_hallmarks', 0)
        player:setCurrency('gallantry', 0)
        player:setCurrency('total_hallmarks', 0)

        local instance = enterRun(1)
        assert(#waves.monsters(instance) == 0, 'monsters before the first wave')

        tickNow(instance)
        local first = waves.monsters(instance)
        assert(#first == 3, 'wave 1 has ' .. #first .. ' monsters')
        assert(first[1]:getMainLvl() == config.waveScale.first.level, 'wave 1 level ' .. first[1]:getMainLvl())
        assert(first[1]:getMaxHP() >= config.waveScale.first.hp, 'wave 1 HP ' .. first[1]:getMaxHP())
        assert(first[1]:getStat(xi.mod.ATT) >= config.waveScale.first.att, 'wave 1 below its attack floor')
        assert(string.find(first[1]:getName(), 'Mired'), 'wave 1 is not Mired: ' .. first[1]:getName())

        -- Nothing new while the wave is alive
        tickNow(instance)
        assert(#waves.monsters(instance) == 3, 'a new wave came while one was alive')

        killAll(instance)
        tickNow(instance) -- the wave fell: the timer starts
        assert(instance:getLocalVar('cleared') == 1, 'wave 1 not counted')
        assert(#waves.monsters(instance) == 0, 'the next wave came without the wait')
        tickNow(instance)

        local second = waves.monsters(instance)
        assert(#second == 4, 'wave 2 has ' .. #second .. ' monsters')
        assert(second[1]:getMainLvl() == config.waveScale.last.level, 'wave 2 level ' .. second[1]:getMainLvl())
        assert(string.find(second[1]:getName(), 'Veiled'), 'wave 2 is not Veiled: ' .. second[1]:getName())

        killAll(instance)
        tickNow(instance)
        tickNow(instance)

        local boss = waves.monsters(instance)
        assert(#boss == 1, 'the boss wave has ' .. #boss .. ' monsters')
        assert(boss[1]:getMainLvl() == 128, 'the boss is level ' .. boss[1]:getMainLvl())
        assert(math.abs(boss[1]:getMaxHP() - config.boss.hp) <= config.boss.hp / 100, 'the boss has ' .. boss[1]:getMaxHP() .. ' HP')
        assert(string.find(boss[1]:getName(), 'Paramount'), 'the boss is not a Paramount: ' .. boss[1]:getName())
        assert(boss[1]:hasImmunity(xi.immunity.DARK_SLEEP), 'the boss can be slept')

        killAll(instance)
        tickNow(instance)

        assert(instance:getLocalVar('state') == 1, 'the run is not marked cleared')
        assert(player:getCurrency('current_hallmarks') == config.runs[1].hallmarks, 'Hallmarks: ' .. player:getCurrency('current_hallmarks'))
        assert(player:getCurrency('total_hallmarks') == config.runs[1].hallmarks, 'total Hallmarks: ' .. player:getCurrency('total_hallmarks'))
        assert(player:getCurrency('gallantry') == config.runs[1].gallantry, 'Gallantry: ' .. player:getCurrency('gallantry'))

        -- Nothing more after the end
        tickNow(instance)
        assert(#waves.monsters(instance) == 0, 'monsters after the end')
        assert(player:getCurrency('current_hallmarks') == config.runs[1].hallmarks, 'paid twice')
    end)

    it('running out of time pays half the Hallmarks for the waves cleared, and sends the monsters away', function()
        player:setCurrency('current_hallmarks', 0)
        player:setCurrency('gallantry', 0)

        local instance = enterRun(2) -- 5 waves, 3,000 Hallmarks
        tickNow(instance)
        killAll(instance)
        tickNow(instance)
        tickNow(instance)
        assert(#waves.monsters(instance) > 0, 'no second wave')

        local sent    = 0
        local despawn = waves.despawn
        waves.despawn = function()
            sent = sent + 1
        end

        instance:setLocalVar('endAt', GetSystemTime() - 1)
        tickNow(instance)
        waves.despawn = despawn

        assert(instance:getLocalVar('state') == 2, 'the run did not fail')
        assert(sent > 0, 'the monsters were not sent away')
        assert(player:getCurrency('current_hallmarks') == math.floor(3000 * 1 / 5 / 2), 'Hallmarks: ' .. player:getCurrency('current_hallmarks'))
        assert(player:getCurrency('gallantry') == 0, 'Gallantry for a failed run')
    end)

    it('a wipe for two minutes fails the run', function()
        local instance = enterRun(1)
        tickNow(instance)
        player:setHP(0)
        xi.test.world:skipTime(1)
        assert(not player:isAlive(), 'the player is still alive')

        tickNow(instance)
        assert(instance:getLocalVar('state') == 0, 'failed at once')
        instance:setLocalVar('wipeAt', GetSystemTime() - config.instance.wipeSeconds)
        tickNow(instance)
        assert(instance:getLocalVar('state') == 2, 'the wipe did not fail the run')
    end)

    -- Every monster the run can send: its group builds, takes the scaling and has TP moves
    for stageIndex, stage in ipairs(config.stages) do
        it(string.format('every %s beast spawns, scaled', stage.name), function()
            local instance = enterRun(4)

            local groups   = stage.groups

            for _, entry in ipairs(groups) do
                local before = #waves.monsters(instance)
                stage.groups = { entry }
                local ok, err = pcall(waves.spawnWave, instance, stageIndex * 2) -- 10 waves: waves 2 / 4 / 6 / 8 are stages 1-4
                stage.groups = groups
                assert(ok, err)
                assert(#waves.monsters(instance) > before, entry[2] .. ' did not spawn')
                killAll(instance)
            end
        end)
    end

    it('every boss spawns at level 128 with its HP', function()
        local instance = enterRun(1)
        local bosses   = config.bosses

        for _, entry in ipairs(bosses) do
            config.bosses = { entry }
            local ok, spawned = pcall(waves.spawnWave, instance, 3)
            config.bosses = bosses
            assert(ok, spawned)
            assert(#spawned == 1, entry[2] .. ' did not spawn')
            assert(spawned[1]:getMainLvl() == 128, entry[2] .. ' is level ' .. spawned[1]:getMainLvl())
            assert(spawned[1]:getMaxHP() >= config.boss.hp, entry[2] .. ' has ' .. spawned[1]:getMaxHP() .. ' HP')
            killAll(instance)
        end
    end)

    it('the tome inside sends you to Mhaura; logging back in after the run closed lands you there too', function()
        enterRun(1)

        local sent     = false
        local toMhaura = waves.toMhaura
        waves.toMhaura = function()
            sent = true
        end

        waves.onExitTrigger(player, nil)
        pick('Yes')
        waves.toMhaura = toMhaura
        assert(sent, 'the tome inside does not send you back')

        player:gotoZone(xi.zone.WEST_RONFAURE)
        xi.zones['Maquette_Abdhaljs-Legion_B'].Zone.onInstanceZoneIn(player, nil)
        xi.test.world:skipTime(2)
        assert(player:getZoneID() == xi.zone.MHAURA, 'not sent to Mhaura')
    end)
end)
