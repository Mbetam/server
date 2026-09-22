-----------------------------------
-- !signet in the real engine: the right regional status for the zone the player is in.
-----------------------------------

describe('!signet', function()
    local influence = { xi.effect.SIGNET, xi.effect.SANCTION, xi.effect.SIGIL, xi.effect.IONIS }

    local function said(player)
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

    -- Spawns a player in `zone`, runs !signet, and returns the player and what the command said.
    local function signetIn(zone, setup)
        local player = xi.test.world:spawnPlayer({ zone = zone, job = xi.job.WAR, level = 99 })

        if setup then
            setup(player)
        end

        player.packets:clear()
        xi.commands.signet.onTrigger(player)

        return player, said(player)
    end

    -- Asserts the player has exactly `expected` among the four regional effects.
    local function assertOnly(player, expected, text)
        for _, effect in ipairs(influence) do
            local has = player:hasStatusEffect(effect)

            if effect == expected then
                assert(has, 'expected effect ' .. expected .. ' after !signet; it said:\n' .. text)
            else
                assert(not has, 'did not expect effect ' .. effect .. ' alongside ' .. tostring(expected))
            end
        end
    end

    it('gives Signet in an original-area field zone', function()
        local player, text = signetIn(xi.zone.WEST_RONFAURE)

        assertOnly(player, xi.effect.SIGNET, text)
        assert(string.find(text, 'You received Signet for', 1, true), text)
    end)

    it('gives Signet in a nation city', function()
        local player, text = signetIn(xi.zone.SOUTHERN_SAN_DORIA)

        assertOnly(player, xi.effect.SIGNET, text)
    end)

    it('gives Sanction in Aht Urhgan', function()
        local player, text = signetIn(xi.zone.WAJAOM_WOODLANDS)

        assertOnly(player, xi.effect.SANCTION, text)
        assert(string.find(text, 'You received Sanction for 3 hours', 1, true), text)
    end)

    it('gives Sigil in the [S] areas of the past', function()
        local player, text = signetIn(xi.zone.EAST_RONFAURE_S)

        assertOnly(player, xi.effect.SIGIL, text)
        assert(string.find(text, 'You received Sigil for', 1, true), text)
    end)

    it('gives Ionis in Adoulin', function()
        local player, text = signetIn(xi.zone.CEIZAK_BATTLEGROUNDS)

        assertOnly(player, xi.effect.IONIS, text)
        assert(string.find(text, 'You received Ionis for 2 hours 30 minutes', 1, true), text)
    end)

    it('replaces a regional status from another area instead of stacking', function()
        local player, text = signetIn(xi.zone.WAJAOM_WOODLANDS, function(p)
            p:addStatusEffect(xi.effect.SIGNET, { duration = 3600, origin = p })
        end)

        assertOnly(player, xi.effect.SANCTION, text)
    end)

    it('gives nothing, and says so, where none of the four applies', function()
        local player, text = signetIn(xi.zone.TAVNAZIAN_SAFEHOLD)

        assertOnly(player, nil, text)
        assert(string.find(text, 'No Signet, Sanction, Sigil or Ionis applies', 1, true), text)
    end)
end)
