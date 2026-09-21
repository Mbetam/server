-----------------------------------
-- What a new character starts with (modules/custom/lua/starter_survival_guides.lua and the START_GIL setting)
-----------------------------------

describe('Starter kit for new characters', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
    end)

    it('registers every Survival Guide', function()
        xi.player.charCreate(player)

        for groupIndex = 1, 32 do
            for group = 1, 3 do
                assert(player:hasTeleport(xi.teleport.type.SURVIVAL, groupIndex - 1, group - 1),
                    string.format('Survival Guide %d of group %d was not registered', groupIndex, group))
            end
        end
    end)

    it('starts with at least the configured gil', function()
        player:setGil(0)

        xi.player.charCreate(player)

        assert(player:getGil() >= xi.settings.main.START_GIL,
            string.format('expected at least %d gil but the character has %d', xi.settings.main.START_GIL, player:getGil()))
    end)

    it('never takes gil away from a character who has more', function()
        player:setGil(xi.settings.main.START_GIL + 500)

        xi.player.charCreate(player)

        assert(player:getGil() == xi.settings.main.START_GIL + 500, 'the start gil top-up should never lower gil')
    end)
end)
