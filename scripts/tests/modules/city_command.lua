-----------------------------------
-- The !city command (modules/custom/commands/city.lua).
-- Uses a stand-in player, so it checks the rules and the coordinates without needing a zone. The real teleport is in
-- city_engine.lua.
-----------------------------------

describe('!city command', function()
    -- What the command must do for each name. Coordinates are checked against data/zones below.
    local expected =
    {
        { names = { 'sandoria', 'sandy', 'san', 'sd' }, zone = xi.zone.SOUTHERN_SAN_DORIA, x = -85.468, y = 1.0,   z = -66.454,  rot = 0,   folder = 'southern_san_doria' },
        { names = { 'bastok', 'bas' },                  zone = xi.zone.BASTOK_MARKETS,      x = -344.0,  y = -10.0, z = -155.0,   rot = 160, folder = 'bastok_markets' },
        { names = { 'windurst', 'windy', 'win' },       zone = xi.zone.WINDURST_WOODS,      x = 9.088,   y = -2.5,  z = -0.383,   rot = 244, folder = 'windurst_woods' },
        { names = { 'jeuno', 'jue' },                   zone = xi.zone.LOWER_JEUNO,         x = -98.588, y = 0.0,   z = -183.416, rot = 167, folder = 'lower_jeuno' },
    }

    -- A stand-in for the player: records what was said and where it was sent
    local function makePlayer(overrides)
        local player =
        {
            zone        = xi.zone.WEST_RONFAURE,
            dead        = false,
            inEvent     = false,
            engaged     = false,
            battlefield = nil,
            instance    = nil,
            said        = {},
            moved       = nil,
        }

        for name, value in pairs(overrides or {}) do
            player[name] = value
        end

        player.isDead        = function(self) return self.dead end
        player.isInEvent     = function(self) return self.inEvent end
        player.isEngaged     = function(self) return self.engaged end
        player.getBattlefield = function(self) return self.battlefield end
        player.getInstance   = function(self) return self.instance end
        player.getZoneID     = function(self) return self.zone end
        player.printToPlayer = function(self, message) table.insert(self.said, message) end
        player.setPos        = function(self, x, y, z, rot, zoneId) self.moved = { x = x, y = y, z = z, rot = rot, zone = zoneId } end

        return player
    end

    local function run(player, destination)
        xi.commands.city.onTrigger(player, destination)
    end

    local function said(player)
        return table.concat(player.said, '\n')
    end

    it('is registered as a command any player can use', function()
        assert(xi.commands.city ~= nil, 'the module did not register !city (is custom/commands/ listed in modules/init.txt?)')
        assert(xi.commands.city.cmdprops.permission == 0, 'permission 0 is what makes a command available to every player')
    end)

    it('sends the player to each city, by every name it answers to', function()
        for _, city in ipairs(expected) do
            for _, name in ipairs(city.names) do
                local player = makePlayer()

                run(player, name)

                assert(player.moved ~= nil, '!city ' .. name .. ' did not move the player')
                assert(player.moved.zone == city.zone, string.format('!city %s went to zone %s, not %d', name, tostring(player.moved.zone), city.zone))
                assert(player.moved.x == city.x and player.moved.y == city.y and player.moved.z == city.z and player.moved.rot == city.rot,
                    string.format('!city %s arrived at the wrong spot', name))
            end
        end
    end)

    it('ignores capital letters', function()
        local player = makePlayer()

        run(player, 'BASTOK')

        assert(player.moved ~= nil and player.moved.zone == xi.zone.BASTOK_MARKETS, 'names should not be case sensitive')
    end)

    it('moves within the zone when the player is already in that city', function()
        local player = makePlayer({ zone = xi.zone.LOWER_JEUNO })

        run(player, 'jeuno')

        assert(player.moved ~= nil and player.moved.zone == nil, 'already in Lower Jeuno, so no zone change should be requested')
        assert(player.moved.x == -98.588, 'the player should still be moved to the crystal')
    end)

    it('says how to use it when the place is unknown or missing', function()
        for _, destination in ipairs({ 'atlantis', '', 'jeuno!' }) do
            local player = makePlayer()

            run(player, destination)

            assert(player.moved == nil and said(player):find('!city sandoria', 1, true), string.format('"%s" should show the usage: %s', destination, said(player)))
        end

        local player = makePlayer()
        run(player, nil)
        assert(player.moved == nil and said(player):find('!city sandoria', 1, true), 'no argument should show the usage')
    end)

    it('is refused when KO\'d, in an event, engaged, or in a battlefield or instance', function()
        local cases =
        {
            { dead = true },
            { inEvent = true },
            { engaged = true },
            { battlefield = {} },
            { instance = {} },
        }

        for index, overrides in ipairs(cases) do
            local player = makePlayer(overrides)

            run(player, 'jeuno')

            assert(player.moved == nil, 'case ' .. index .. ' should not have moved the player')
            assert(#player.said == 1, 'case ' .. index .. ' should have been told why')
        end
    end)

    it('uses the same coordinates as the Home Point #1 crystals in the game data', function()
        -- data/zones/<zone>/npcs.yaml lists each crystal as `script: HomePoint#1` followed by `at: [x, y, z(, rotation)]`
        for _, city in ipairs(expected) do
            local file = io.open('data/zones/' .. city.folder .. '/npcs.yaml', 'r')
            assert(file, 'could not open the NPC data for ' .. city.folder .. ' (tests must run from the repository root)')

            local wantAt = false
            local found  = nil

            for line in file:lines() do
                if line:match('script:%s+HomePoint#1%s*$') then
                    wantAt = true
                elseif wantAt and line:match('^%s+at:') then
                    local x, y, z, rot = line:match('%[%s*(%-?[%d%.]+),%s*(%-?[%d%.]+),%s*(%-?[%d%.]+),?%s*(%d*)%s*%]')
                    found = { x = tonumber(x), y = tonumber(y), z = tonumber(z), rot = tonumber(rot) or 0 }

                    break
                end
            end

            file:close()

            assert(found ~= nil, 'Home Point #1 was not found for ' .. city.folder)
            assert(found.x == city.x and found.y == city.y and found.z == city.z and found.rot == city.rot,
                string.format('%s: the crystal is at %s, %s, %s (rotation %s) but the command says %s, %s, %s (rotation %s)',
                    city.folder, found.x, found.y, found.z, found.rot, city.x, city.y, city.z, city.rot))
        end
    end)
end)
