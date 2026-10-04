-----------------------------------
-- modules/custom/lua/trust_tank_hate.lua: tank trusts summoned through xi.trust.spawn get enmity loss reduction, their
-- Provoke / Flash add cumulative enmity, and the Flash-only tanks also Provoke. Non-tanks are untouched.
-- The long measurements live in scripts/tests/benchmarks/tank_hate.lua.
-----------------------------------

describe('Tank trust hate', function()
    local tankHate = xi.custom.tankHate

    local function trustOf(player, spellId)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                return member
            end
        end
    end

    local function bossNear(player)
        local config = require('modules/custom/htbf/htbf_config')
        local boss   = config.bosses[1][1] -- Behemoth
        local mob    = player:getZone():insertDynamicEntity(
        {
            objtype = xi.objType.MOB, name = 'TH_' .. boss.key, x = player:getXPos() + 3, y = player:getYPos(), z = player:getZPos(), rotation = 0,
            groupId = boss.group[1], groupZoneId = boss.group[2], minLevel = config.tiers[1].level, maxLevel = config.tiers[1].level,
            releaseIdOnDisappear = true,
        })
        mob:setSpawn(player:getXPos() + 3, player:getYPos(), player:getZPos(), 0)
        mob:spawn()
        xi.custom.htbfArena.scale(mob, 1, boss)
        mob:setUnkillable(true)
        mob:setMobAbilityEnabled(false)
        mob:setMagicCastingEnabled(false)

        return mob
    end

    it('applies to tank trusts once, not to other trusts', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })

        xi.trust.spawn(player, GetSpell(xi.magic.spell.CURILLA))
        xi.test.world:skipTime(2)
        xi.trust.spawn(player, GetSpell(xi.magic.spell.KUPIPI))
        xi.test.world:skipTime(2)

        local curilla = trustOf(player, xi.magic.spell.CURILLA)
        local kupipi  = trustOf(player, xi.magic.spell.KUPIPI)
        assert(curilla and kupipi, 'trusts did not spawn')

        assert(curilla:getMod(xi.mod.ENMITY_LOSS_REDUCTION) == tankHate.config.lossReduction,
            'Curilla enmity loss reduction ' .. curilla:getMod(xi.mod.ENMITY_LOSS_REDUCTION))
        assert(curilla:getLocalVar('[custom]TankHate') == 1, 'Curilla not marked')
        assert(kupipi:getMod(xi.mod.ENMITY_LOSS_REDUCTION) == 0, 'Kupipi is not a tank')
        assert(kupipi:getLocalVar('[custom]TankHate') == 0, 'Kupipi should not be marked')
    end)

    it('Curilla Provokes, and her Provoke and Flash build cumulative enmity on the boss', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:addMod(xi.mod.ACC, -5000) -- engaged so the trust fights, but adds no enmity of its own worth noting
        player:setCharVar('TrustEngageType', 1)

        xi.trust.spawn(player, GetSpell(xi.magic.spell.CURILLA))
        xi.test.world:skipTime(2)

        local curilla = trustOf(player, xi.magic.spell.CURILLA)
        local used    = { provoke = 0, flash = 0 }

        curilla:addListener('ABILITY_USE', 'TH_TEST_JA', function(entity, target, ability)
            if ability:getID() == xi.jobAbility.PROVOKE then
                used.provoke = used.provoke + 1
            end
        end)
        curilla:addListener('MAGIC_USE', 'TH_TEST_MA', function(entity, target, spell)
            if spell:getID() == xi.magic.spell.FLASH then
                used.flash = used.flash + 1
            end
        end)

        local mob = bossNear(player)
        player.actions:engage(mob)

        for _ = 1, 20 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
        end

        assert(used.provoke >= 1, 'Curilla never used Provoke')
        assert(used.flash >= 1, 'Curilla never cast Flash')
        -- Stock: Provoke CE 1, Flash CE 180. With the module each adds thousands.
        local expected = tankHate.config.provokeCE + tankHate.config.flashCE
        assert(mob:getCE(curilla) >= expected * 0.5,
            string.format('Curilla CE %d after Provoke x%d / Flash x%d, expected at least %d', mob:getCE(curilla), used.provoke, used.flash, expected * 0.5))

        DespawnMob(mob:getID())
        player:clearTrusts()
        xi.test.world:skipTime(2)
    end)

    it('pulses a Provoke worth of hate every 10 s while fighting, not before', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:addMod(xi.mod.ACC, -5000)
        player:setCharVar('TrustEngageType', 1)

        xi.trust.spawn(player, GetSpell(xi.magic.spell.TRION))
        xi.test.world:skipTime(2)

        local trion = trustOf(player, xi.magic.spell.TRION)

        for _ = 1, 15 do
            xi.test.world:skipTime(1)
        end

        assert(trion:getLocalVar('[custom]TankPulses') == 0, 'pulsed while not fighting')

        local mob = bossNear(player)
        player.actions:engage(mob)

        for _ = 1, 25 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
        end

        local pulses = trion:getLocalVar('[custom]TankPulses')
        assert(pulses >= 2 and pulses <= 3, 'expected 2-3 pulses in 25 s of fighting, got ' .. pulses)

        DespawnMob(mob:getID())
        player:clearTrusts()
        xi.test.world:skipTime(2)
    end)
end)
