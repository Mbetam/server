-----------------------------------
-- NM placeholders renamed "PH <name>" (modules/custom/lua/mark_nm_placeholders.lua)
-----------------------------------

describe('NM placeholder names', function()
    it('renames a placeholder when a player enters its zone, and leaves the NM and other monsters alone', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        local ID     = zones[xi.zone.WEST_RONFAURE]

        xi.player.onGameIn(player, false, true)

        local ph = GetMobByID(ID.mob.JAGGEDY_EARED_JACK - 1)
        assert(ph:getPacketName() == 'PH Forest Hare', 'placeholder is named "' .. ph:getPacketName() .. '"')

        local nm = GetMobByID(ID.mob.JAGGEDY_EARED_JACK)
        assert(nm:getPacketName() ~= nil and nm:getPacketName():sub(1, 3) ~= 'PH ', 'the NM itself was renamed')

        local other = GetMobByID(ID.mob.JAGGEDY_EARED_JACK - 2)
        assert(other:getPacketName():sub(1, 3) ~= 'PH ', 'a monster that is not a placeholder was renamed')
    end)
end)
