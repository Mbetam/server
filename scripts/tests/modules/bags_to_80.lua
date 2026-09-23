-----------------------------------
-- Bags and wardrobes raised to 80 at login (modules/custom/lua/bags_to_80.lua)
-----------------------------------

describe('Bags at 80', function()
    local containers =
    {
        xi.inv.INVENTORY, xi.inv.MOGSATCHEL, xi.inv.MOGSACK, xi.inv.MOGCASE,
        xi.inv.WARDROBE, xi.inv.WARDROBE2, xi.inv.WARDROBE3, xi.inv.WARDROBE4,
        xi.inv.WARDROBE5, xi.inv.WARDROBE6, xi.inv.WARDROBE7, xi.inv.WARDROBE8,
    }

    it('raises every bag and wardrobe to 80 at login, and never past 80', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME })

        -- Shrink the inventory back to the game default first, as for a character made before the module existed
        player:changeContainerSize(xi.inv.INVENTORY, 30 - player:getContainerSize(xi.inv.INVENTORY))
        assert(player:getContainerSize(xi.inv.INVENTORY) == 30, 'precondition: inventory at 30')

        xi.player.onGameIn(player, false, false)
        xi.player.onGameIn(player, false, false) -- a second login must not add more

        for _, container in ipairs(containers) do
            local size = player:getContainerSize(container)
            assert(size == 80, string.format('container %d is %d, expected 80', container, size))
        end
    end)
end)
