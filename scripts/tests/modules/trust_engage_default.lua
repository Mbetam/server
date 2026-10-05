-----------------------------------
-- modules/custom/lua/trust_engage_default.lua: trusts engage with you without waiting for a swing (engage type 1) for
-- everyone by default, set once at login; !trustengage 0 sticks.
-----------------------------------

describe('Trust engage default', function()
    it('sets engage type 1 at the first login, then leaves the player\'s choice alone', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })

        player:setCharVar('TrustEngageType', 0)
        player:setCharVar('TrustEngageDefaulted', 0)
        xi.player.onGameIn(player, false, false)
        assert(player:getCharVar('TrustEngageType') == 1, 'not defaulted to 1')

        player:setCharVar('TrustEngageType', 0) -- !trustengage 0
        xi.player.onGameIn(player, false, false)
        assert(player:getCharVar('TrustEngageType') == 0, 'the player\'s own choice was overwritten')
        assert(xi.settings.main.ENABLE_TRUST_CUSTOM_ENGAGEMENT == 1, 'ENABLE_TRUST_CUSTOM_ENGAGEMENT is off')
    end)

    it('a trust engages when its master engages from range, before any swing', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLM, level = 99 })
        xi.player.onGameIn(player, false, false) -- the module's default
        player:setCharVar('TrustEngageType', player:getCharVar('TrustEngageDefaulted') == 1 and 1 or player:getCharVar('TrustEngageType'))

        xi.trust.spawn(player, GetSpell(xi.magic.spell.NAJI))
        xi.test.world:skipTime(2)

        local naji = nil
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() then
                naji = member
            end
        end

        assert(naji, 'Naji did not come')

        -- A dummy 15 yalms away: too far for the player's own swings
        local mob = player:getZone():insertDynamicEntity(
        {
            objtype = xi.objType.MOB, name = 'TE_Dummy', x = player:getXPos() + 15, y = player:getYPos(), z = player:getZPos(), rotation = 0,
            groupId = 11374, groupZoneId = 86, minLevel = 99, maxLevel = 99, releaseIdOnDisappear = true,
        })
        mob:setSpawn(player:getXPos() + 15, player:getYPos(), player:getZPos(), 0)
        mob:spawn()
        mob:setUnkillable(true)
        mob:setAutoAttackEnabled(false)
        mob:setMobAbilityEnabled(false)
        mob:setMagicCastingEnabled(false)

        player.actions:engage(mob)

        for _ = 1, 6 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
        end

        assert(naji:isEngaged(), 'Naji did not engage without a swing')
        assert(naji:checkDistance(mob) < 10, string.format('Naji did not go to the mob (%.1f yalms away)', naji:checkDistance(mob)))

        DespawnMob(mob:getID())
        player:clearTrusts()
        xi.test.world:skipTime(2)
    end)
end)
