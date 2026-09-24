-----------------------------------
-- Jug pets deal +50% damage (modules/custom/lua/jug_pet_damage.lua): Ready moves x1.5, auto-attack weapon damage x1.5.
-----------------------------------

describe('Jug pet damage', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BST, level = 99 })
        mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        player:setPos(mob:getXPos() + 1, mob:getYPos(), mob:getZPos())

        player:addItem(xi.item.JUG_OF_BURNING_CARRION_BROTH, 1) -- Gorefang Hobs, grows to 99
        player:equipItem(xi.item.JUG_OF_BURNING_CARRION_BROTH, nil, xi.slot.AMMO)
        player.actions:useAbility(player, xi.jobAbility.CALL_BEAST)
        xi.test.world:skipTime(3)
    end)

    it('raises the jug pet\'s auto-attack weapon damage by 50%', function()
        local pet = player:getPet()
        assert(pet, 'Call Beast did not summon a pet')
        assert(pet:getMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER) == 150, 'weapon damage multiplier is ' .. pet:getMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER))
    end)

    it('multiplies a jug pet\'s Ready move damage by 1.5, and leaves monsters alone', function()
        local pet = player:getPet()

        local petInfo = { damage = 400, hitsLanded = 1 }
        xi.mobskills.processDamage(pet, mob, nil, nil, petInfo)
        assert(petInfo.damage == 600, 'a jug pet\'s 400 damage became ' .. petInfo.damage)

        local mobInfo = { damage = 400, hitsLanded = 1 }
        xi.mobskills.processDamage(mob, player, nil, nil, mobInfo)
        assert(mobInfo.damage == 400, 'a wild monster\'s damage changed to ' .. mobInfo.damage)
    end)
end)
