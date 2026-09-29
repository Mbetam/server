-----------------------------------
-- Voidwalker NMs (scripts/globals/voidwalker.lua): buy a Clear Abyssite from Assai Nybaem, /heal near a hidden
-- Voidwalker NM to pop it, kill it, and the abyssite can upgrade. Checked 2026-09-28 (Eric: "is voidwalker working?").
-- Plus the custom personal drops (modules/custom/lua/voidwalker_drops.lua).
-----------------------------------

describe('Voidwalker', function()
    local SUNDERCLAW = 17191334 -- East Ronfaure, a Clear Abyssite target
    local YILBEGAN   = 17191323 -- East Ronfaure, the Black Abyssite boss

    local PLUTON, RIFTBORN_BOULDER, BEITETSU = 4059, 4061, 4060

    local function kill(player, mob)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), 'the Voidwalker did not die')
    end

    local function between(player, itemId, low, high)
        local n = player:getItemCount(itemId)

        return n >= low and n <= high, n
    end

    it('Assai Nybaem sells a Clear Abyssite for 1,000 gil', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.RULUDE_GARDENS, job = xi.job.WAR, level = 99 })
        player:setGil(5000)

        xi.voidwalker.npcOnEventFinish(player, 10120, 1, nil) -- menu option 1: buy

        assert(player:hasKeyItem(xi.keyItem.CLEAR_ABYSSITE), 'no Clear Abyssite')
        assert(player:getGil() == 4000, 'expected 1,000 gil taken, have ' .. player:getGil())
    end)

    it('resting next to a hidden Voidwalker pops it for you; killing it can upgrade the abyssite', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.EAST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:addKeyItem(xi.keyItem.CLEAR_ABYSSITE)

        local mob = GetMobByID(SUNDERCLAW)
        assert(mob and mob:isAlive(), 'the Voidwalker NM is not spawned in the zone')
        assert(mob:getLocalVar('[VoidWalker]PopedBy') == 0, 'already popped')

        player:setPos(mob:getXPos() + 1, mob:getYPos(), mob:getZPos())
        xi.voidwalker.onHealing(player) -- what /heal calls every tick

        assert(mob:getLocalVar('[VoidWalker]PopedBy') == player:getID(), 'resting next to it did not pop it')
        assert(mob:getLocalVar('[VoidWalker]PopedWith') == xi.keyItem.CLEAR_ABYSSITE, 'wrong abyssite recorded')

        -- The upgrade is a 1 in 10 roll (math.randomInt(1, 10) == 5): make it land
        stub('math.randomInt', function(low, high)
            return (low == 1 and high == 10) and 5 or low
        end)

        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), 'the Voidwalker did not die')
        assert(player:hasKeyItem(xi.keyItem.COLORFUL_ABYSSITE), 'the Clear Abyssite did not become a Colorful Abyssite')
        assert(not player:hasKeyItem(xi.keyItem.CLEAR_ABYSSITE), 'the Clear Abyssite was not taken')
    end)

    it('a T1 kill gives Pluton 20-50 to every party member in the zone, each their own', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.EAST_RONFAURE, job = xi.job.WAR, level = 99 })
        local member = xi.test.world:spawnPlayer({ zone = xi.zone.EAST_RONFAURE, job = xi.job.WHM, level = 99 })
        player.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        local mob = GetMobByID(SUNDERCLAW - 1) -- another Sunderclaw: the earlier test killed the first one
        assert(mob and mob:isAlive(), 'the second Sunderclaw is not spawned')

        -- Popped with a Clear Abyssite (what /heal records, as in the test above)
        mob:setLocalVar('[VoidWalker]PopedBy', player:getID())
        mob:setLocalVar('[VoidWalker]PopedWith', xi.keyItem.CLEAR_ABYSSITE)
        mob:updateClaim(player)
        kill(player, mob)

        for _, who in ipairs({ player, member }) do
            local ok, n = between(who, PLUTON, 20, 50)
            assert(ok, 'expected 20-50 Pluton, got ' .. n)
            assert(who:getItemCount(RIFTBORN_BOULDER) == 0 and who:getItemCount(BEITETSU) == 0, 'T1 should only drop Pluton')
        end
    end)

    it('the boss (Black Abyssite) gives all three, 20-50 each', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.EAST_RONFAURE, job = xi.job.WAR, level = 99 })
        local mob    = GetMobByID(YILBEGAN)
        assert(mob, 'no Yilbegan')

        if not mob:isAlive() then
            SpawnMob(YILBEGAN)
        end

        mob:setLocalVar('[VoidWalker]PopedBy', player:getID())
        mob:setLocalVar('[VoidWalker]PopedWith', xi.keyItem.BLACK_ABYSSITE)
        mob:updateClaim(player)
        kill(player, mob)

        for _, itemId in ipairs({ PLUTON, RIFTBORN_BOULDER, BEITETSU }) do
            local ok, n = between(player, itemId, 20, 50)
            assert(ok, 'item ' .. itemId .. ': expected 20-50, got ' .. n)
        end
    end)
end)
