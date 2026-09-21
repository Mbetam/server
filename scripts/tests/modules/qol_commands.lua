-----------------------------------
-- QoL commands (modules/custom/commands/): !home, !tele, !telelist, !shop
-----------------------------------

describe('QoL commands', function()
    ---@type CClientEntityPair
    local player

    local function settle()
        for _ = 1, 8 do
            xi.test.world:skipTime(1)
        end
    end

    -- Everything the server printed to the player since packets were last cleared, one line per message
    local function said()
        local lines = {}

        for _, pkt in pairs(player.packets:getIncoming()) do
            if pkt.type == 0x017 then
                local text = ''

                for i = 0, pkt.size - 23 - 1 do
                    local byte = pkt.data[23 + i]
                    if byte == nil or byte == 0 then
                        break
                    end

                    text = text .. string.char(byte)
                end

                table.insert(lines, text)
            end
        end

        return table.concat(lines, '\n')
    end

    local function run(command, ...)
        player.packets:clear()
        xi.commands[command].onTrigger(player, ...)
    end

    local function near(actual, expected)
        return math.abs(actual - expected) < 0.011
    end

    local function knockOut()
        player:die({ expLoss = false })
        xi.test.world:tickEntity(player)
        assert(player:isDead(), 'precondition: the player should be dead')
    end

    it('are all registered as commands any player can use', function()
        for _, name in ipairs({ 'home', 'tele', 'telelist', 'shop' }) do
            local command = xi.commands[name]

            assert(command ~= nil, string.format('!%s is not registered (is custom/commands/ listed in modules/init.txt?)', name))
            assert(command.cmdprops.permission == 0, string.format('!%s should be available to every player', name))
        end
    end)

    describe('!home', function()
        before_each(function()
            -- Home point in Port San d'Oria, standing in West Ronfaure
            player = xi.test.world:spawnPlayer({ zone = xi.zone.PORT_SAN_DORIA, job = xi.job.WHM, level = 30 })
            player:setHomePoint()
            player:setPos(0, 0, 0, 0, xi.zone.WEST_RONFAURE)
            settle()

            assert(player:getZoneID() == xi.zone.WEST_RONFAURE, 'precondition: the player should be in West Ronfaure')
        end)

        it('sends the player to their home point', function()
            run('home')
            local text = said()
            settle()

            assert(player:getZoneID() == xi.zone.PORT_SAN_DORIA, 'the player should be back at their home point')
            assert(text:find('home point', 1, true), 'the player should be told they are warping: ' .. text)
        end)

        it('does nothing for a KO\'d player', function()
            knockOut()

            run('home')
            local text = said()
            settle()

            assert(player:getZoneID() == xi.zone.WEST_RONFAURE, 'a KO\'d player should not be warped')
            assert(text:find('KO', 1, true), 'the player should be told why: ' .. text)
        end)
    end)

    describe('!tele', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        end)

        it('saves a point and returns to it', function()
            player:setPos(10.5, -3.25, 20.75, 64)
            run('tele', 'set', 'camp')
            assert(said():find('saved', 1, true), 'saving should be confirmed')

            player:setPos(100, 0, 100, 0)
            run('tele', 'camp')

            assert(near(player:getXPos(), 10.5), 'x was not restored: ' .. player:getXPos())
            assert(near(player:getYPos(), -3.25), 'y was not restored: ' .. player:getYPos())
            assert(near(player:getZPos(), 20.75), 'z was not restored: ' .. player:getZPos())
            assert(player:getRotPos() == 64, 'rotation was not restored: ' .. player:getRotPos())
        end)

        it('keeps a point where every coordinate is exactly 0', function()
            -- A stored char var of 0 is deleted, so zero coordinates and rotation are the case that would silently vanish
            player:setPos(0, 0, 0, 0)
            run('tele', 'set', 'origin')

            player:setPos(50, 0, 50, 128)
            run('tele', 'origin')

            assert(near(player:getXPos(), 0) and near(player:getZPos(), 0), 'a point at (0, 0) was lost')
            assert(player:getRotPos() == 0, 'a point with rotation 0 was lost')
        end)

        it('travels between zones', function()
            player:setPos(-12.5, 0, 33.5, 32)
            run('tele', 'set', 'ronfaure')

            player:setPos(0, 0, 0, 0, xi.zone.PORT_SAN_DORIA)
            settle()
            assert(player:getZoneID() == xi.zone.PORT_SAN_DORIA, 'precondition: the player should be in Port San d\'Oria')

            run('tele', 'ronfaure')
            settle()

            assert(player:getZoneID() == xi.zone.WEST_RONFAURE, 'the player should have travelled to the saved zone')
            assert(near(player:getXPos(), -12.5) and near(player:getZPos(), 33.5), 'the player arrived at the wrong spot')
        end)

        it('ignores capital letters in names', function()
            player:setPos(5, 0, 5, 0)
            run('tele', 'set', 'Camp')

            player:setPos(80, 0, 80, 0)
            run('tele', 'CAMP')

            assert(near(player:getXPos(), 5), 'the name should not be case sensitive')
        end)

        it('overwrites a point saved under the same name', function()
            player:setPos(5, 0, 5, 0)
            run('tele', 'set', 'spot')

            player:setPos(40, 0, 40, 0)
            run('tele', 'set', 'spot')

            player:setPos(90, 0, 90, 0)
            run('tele', 'spot')

            assert(near(player:getXPos(), 40), 'the second save should have replaced the first')
        end)

        it('forgets a deleted point', function()
            player:setPos(5, 0, 5, 0)
            run('tele', 'set', 'camp')
            run('tele', 'del', 'camp')
            assert(said():find('deleted', 1, true), 'deleting should be confirmed')

            player:setPos(70, 0, 70, 0)
            run('tele', 'camp')

            assert(said():find('no teleport point', 1, true), 'a deleted point should not be found')
            assert(near(player:getXPos(), 70), 'a deleted point should not move the player')
        end)

        it('says so when deleting a point that does not exist', function()
            run('tele', 'del', 'nothere')

            assert(said():find('no teleport point', 1, true), 'the player should be told there is no such point')
        end)

        it('stops at 10 points but still lets an existing one be replaced', function()
            for i = 1, 10 do
                run('tele', 'set', 'p' .. i)
            end

            run('tele', 'set', 'extra')
            assert(said():find('10 teleport points', 1, true), 'the limit should be explained')
            assert(player:getCharVar('tele_extra_zone') == 0, 'an eleventh point should not have been saved')

            run('tele', 'set', 'p1')
            assert(said():find('saved', 1, true), 'replacing an existing point should not count against the limit')
        end)

        it('rejects names it cannot store', function()
            for _, badName in ipairs({ 'no!', 'set', 'del', 'abcdefghijklm', 'a_b' }) do
                run('tele', 'set', badName)
            end

            assert(next(player:getCharVarsWithPrefix('tele_')) == nil, 'a bad name was saved')
        end)

        it('explains itself when used without arguments', function()
            run('tele')

            assert(said():find('!tele set', 1, true), 'the player should be shown how to use it')
        end)

        it('does not save or use points for a KO\'d player', function()
            player:setPos(5, 0, 5, 0)
            run('tele', 'set', 'camp')
            player:setPos(60, 0, 60, 0)

            knockOut()

            run('tele', 'camp')
            assert(near(player:getXPos(), 60), 'a KO\'d player should not be teleported')

            run('tele', 'set', 'other')
            assert(player:getCharVar('tele_other_zone') == 0, 'a KO\'d player should not save a point')
        end)
    end)

    describe('!telelist', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        end)

        it('says so when there are no points', function()
            run('telelist')

            assert(said():find('no teleport points', 1, true), 'an empty list should say so')
        end)

        it('lists every point with its zone', function()
            player:setPos(1, 0, 1, 0)
            run('tele', 'set', 'beta')
            run('tele', 'set', 'alpha')

            run('telelist')
            local text = said()

            assert(text:find('(2/10)', 1, true), 'the count should be shown: ' .. text)
            assert(text:find('alpha', 1, true) and text:find('beta', 1, true), 'both points should be listed: ' .. text)
            assert(text:find('West Ronfaure', 1, true), 'the zone should be named: ' .. text)
            assert(text:find('alpha', 1, true) < text:find('beta', 1, true), 'points should be listed alphabetically: ' .. text)
        end)

        it('does not list a deleted point', function()
            run('tele', 'set', 'gone')
            run('tele', 'del', 'gone')

            run('telelist')

            assert(said():find('no teleport points', 1, true), 'a deleted point should not be listed')
        end)
    end)

    describe('!shop', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        end)

        local function opened()
            local list, open = false, false

            for _, pkt in pairs(player.packets:getIncoming()) do
                list = list or pkt.type == 0x03C
                open = open or pkt.type == 0x03E
            end

            return list and open
        end

        it('opens the shop window', function()
            run('shop')

            assert(opened(), 'the shop list and shop open packets should have been sent')
        end)

        it('sells the first item on the list', function()
            player:setGil(100000)
            run('shop')
            local gilBefore = player:getGil()

            player.actions:shopBuy(0, 1) -- Potion, 910 gil

            assert(player:hasItem(xi.item.POTION), 'the potion was not delivered')
            assert(player:getGil() == gilBefore - 910, 'the potion should have cost 910 gil')
        end)

        it('refuses a purchase the player cannot afford', function()
            player:setGil(100)
            run('shop')

            player.actions:shopBuy(0, 1)

            assert(not player:hasItem(xi.item.POTION), 'a potion was sold to a player without the gil')
            assert(player:getGil() == 100, 'gil changed on a refused purchase')
        end)

        it('does not open for a KO\'d player', function()
            knockOut()

            run('shop')

            assert(not opened(), 'a KO\'d player should not get a shop')
            assert(said():find('KO', 1, true), 'the player should be told why')
        end)
    end)
end)
