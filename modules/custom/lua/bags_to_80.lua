-----------------------------------
-- Bags and wardrobes at 80 slots for everyone (design baseline: "bags/wardrobes unlocked to 80 including wardrobes 5-8").
-- At every login, each container below is raised to 80 if it is smaller. It never shrinks anything, so it is safe to run
-- again and again, and it covers characters made before this existed (settings START_INVENTORY only applies at creation).
-- The Mog Safe, Storage and Mog Locker are left alone.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local targetSize = 80

local containers =
{
    xi.inv.INVENTORY,
    xi.inv.MOGSATCHEL,
    xi.inv.MOGSACK,
    xi.inv.MOGCASE,
    xi.inv.WARDROBE,
    xi.inv.WARDROBE2,
    xi.inv.WARDROBE3,
    xi.inv.WARDROBE4,
    xi.inv.WARDROBE5,
    xi.inv.WARDROBE6,
    xi.inv.WARDROBE7,
    xi.inv.WARDROBE8,
}

local m = Module:new('bags_to_80')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if zoning then
        return
    end

    for _, container in ipairs(containers) do
        local size = player:getContainerSize(container)

        -- changeContainerSize adds to the current size
        if size < targetSize then
            player:changeContainerSize(container, targetSize - size)
        end
    end
end)
