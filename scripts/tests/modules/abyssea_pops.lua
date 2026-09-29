-----------------------------------
-- Abyssea pops LSB left broken (modules/custom/lua/abyssea_pops.lua): the 70 ??? in Vunkerl, Misareaux and Uleguerand
-- now pop their NMs with the retail key items / trades; Myrmecoleon comes out when Lachrymater dies.
-----------------------------------

describe('Abyssea pops', function()
    local data = xi.custom.abysseaPops

    local function spawn(zone)
        local player = xi.test.world:spawnPlayer({ zone = zone, job = xi.job.WAR, level = 99 })
        xi.abyssea.afterZoneIn(player)

        return player
    end

    it('has all 70 broken ??? covered, each with a spawnable NM', function()
        local count = 0

        for zoneId in pairs(data) do
            spawn(zoneId) -- loads the zone, so its monsters exist
        end

        for _, qms in pairs(data) do
            for qm, pop in pairs(qms) do
                count = count + 1
                assert(GetMobByID(pop.mob) ~= nil, qm .. ': NM ' .. pop.mob .. ' does not exist')
                assert((pop.items and #pop.items > 0) or (pop.kis and #pop.kis > 0), qm .. ': no requirement')
            end
        end

        assert(count == 70, 'expected 70 ???, got ' .. count)
    end)

    it('Sedna (Vunkerl) pops at her ??? with the two key items, which are used up', function()
        local player = spawn(xi.zone.ABYSSEA_VUNKERL)
        local pop    = data[xi.zone.ABYSSEA_VUNKERL].qm14

        for _, ki in ipairs(pop.kis) do
            player:addKeyItem(ki)
        end

        player.entities:gotoAndTrigger('qm14')
        player.events:finish(nil, 1)
        xi.test.world:skipTime(2)

        assert(GetMobByID(pop.mob):isSpawned(), 'Sedna did not pop')
        for _, ki in ipairs(pop.kis) do
            assert(not player:hasKeyItem(ki), 'key item ' .. ki .. ' was not used up')
        end
    end)

    it('Nonno (Misareaux) pops by trading its item', function()
        local player = spawn(xi.zone.ABYSSEA_MISAREAUX)
        local pop    = data[xi.zone.ABYSSEA_MISAREAUX].qm10

        player:addItem(pop.items[1])
        player.entities:moveTo('qm10')
        player.actions:tradeNpc('qm10', { pop.items[1] })
        xi.test.world:skipTime(2)

        assert(GetMobByID(pop.mob):isSpawned(), 'Nonno did not pop')
        assert(player:getItemCount(pop.items[1]) == 0, 'the pop item was not taken')
    end)

    it('without the key items, Isgebind (Uleguerand) does not pop', function()
        local player = spawn(xi.zone.ABYSSEA_ULEGUERAND)
        local pop    = data[xi.zone.ABYSSEA_ULEGUERAND].qm13

        player.entities:gotoAndTrigger('qm13')
        player.events:finish(nil, 1)
        xi.test.world:skipTime(2)

        assert(not GetMobByID(pop.mob):isSpawned(), 'Isgebind popped without key items')
    end)

    it('killing Lachrymater (Tahrongi) brings out Myrmecoleon, claimed by the killer', function()
        local player = spawn(xi.zone.ABYSSEA_TAHRONGI)
        local lachry = player.entities:moveTo('Lachrymater')
        lachry:respawn()
        lachry:updateClaim(player)
        lachry:takeDamage(lachry:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(GetMobByID(16961939):isSpawned(), 'Myrmecoleon did not come out')
    end)
end)
