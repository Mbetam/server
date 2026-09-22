-----------------------------------
-- !ahprice in the real engine: real item lookups by name, through the actual game bindings the command
-- uses (GetItemIDByName, GetItemByID, item:getBasePrice/getReqLvl/isType/getAHCat).
-----------------------------------

describe('!ahprice in the engine', function()
    ---@type CClientEntityPair
    local player

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

    local function run(...)
        player.packets:clear()
        xi.commands.ahprice.onTrigger(player, ...)

        return said()
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
    end)

    it('prices a material by its BaseSell, matching a single-word name', function()
        local text = run('fire_crystal')

        -- Fire Crystal: BaseSell 15 x the 2 multiplier
        assert(string.find(text, 'Fire Crystal', 1, true), 'expected the pretty name in:\n' .. text)
        assert(string.find(text, 'about 30 gil', 1, true), 'expected the BaseSell-based price in:\n' .. text)
    end)

    it('matches a multi-word search typed with spaces, not underscores', function()
        local text = run('fire', 'crystal')

        assert(string.find(text, 'about 30 gil', 1, true), 'a two-word search should still find it:\n' .. text)
    end)

    it('prices equipment by its level when it has no BaseSell', function()
        local text = run('jinxed_hakama')

        -- level 99, no BaseSell: 99 * 10 * 2
        assert(string.find(text, 'about 1980 gil', 1, true), 'expected the level-based price in:\n' .. text)
    end)

    it('says so for an item with no name match', function()
        local text = run('zzznotarealitemzzz')

        assert(string.find(text, 'No item matches', 1, true), 'expected a not-found message:\n' .. text)
    end)

    it('asks for a more specific name when several items match', function()
        local text = run('ore')

        assert(string.find(text, 'matches 246 items', 1, true), 'expected an ambiguous-match message with the count:\n' .. text)
    end)

    it('prefers an exact name over partial matches (Cesti, not the 27 other items containing "cesti")', function()
        local text = run('Cesti')

        -- Cesti (16385): BaseSell 24 x the 2 multiplier
        assert(string.find(text, 'Cesti: about 48 gil', 1, true), 'expected the exact item Cesti:\n' .. text)
    end)

    it('finds an exact multi-word name with a +1 typed with spaces', function()
        local text = run('cesti', '+1')

        -- Cesti +1 (16690): BaseSell 32 x 2
        assert(string.find(text, 'about 64 gil', 1, true), 'expected Cesti +1:\n' .. text)
    end)

    it('still finds an item by part of its name when no item has exactly that name', function()
        local text = run('grotesque')

        assert(string.find(text, 'Grotesque Cesti', 1, true), 'expected the partial match:\n' .. text)
    end)

    it('says an item cannot be sold on the AH when its category is none', function()
        local text = run('pile_of_chocobo_bedding')

        assert(string.find(text, 'cannot be sold on the Auction House', 1, true), 'expected the not-sellable message:\n' .. text)
    end)

    it('shows the usage when no name is given', function()
        local text = run()

        assert(string.find(text, '!ahprice', 1, true), 'expected the usage message:\n' .. text)
    end)

    it('changes nothing about the player or the world', function()
        local before = player:getGil()

        run('fire_crystal')

        assert(player:getGil() == before, 'looking up a price must not change the player\'s gil')
    end)
end)
