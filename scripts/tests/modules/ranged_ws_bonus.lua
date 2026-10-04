-----------------------------------
-- modules/custom/lua/ranged_ws_bonus.lua: archery and marksmanship weapon skills get +25% damage
-- (ALL_WSDMG_ALL_HITS while the ranged weapon skill is worked out); melee weapon skills do not.
-----------------------------------

describe('Ranged weapon skill bonus', function()
    local bonus = xi.custom.rangedWs.bonus

    -- Records the attacker's ALL_WSDMG_ALL_HITS each time a weapon skill's damage is worked out
    local function spyWsd()
        local seen = {}
        local calc = xi.weaponskills.calculateRawWSDmg

        xi.weaponskills.calculateRawWSDmg = function(attacker, ...)
            table.insert(seen, attacker:getMod(xi.mod.ALL_WSDMG_ALL_HITS))
            return calc(attacker, ...)
        end

        return seen, function() xi.weaponskills.calculateRawWSDmg = calc end
    end

    local function dummyNear(player)
        local mob = player:getZone():insertDynamicEntity(
        {
            objtype = xi.objType.MOB, name = 'RWS_Dummy', x = player:getXPos() + 2, y = player:getYPos(), z = player:getZPos(), rotation = 0,
            groupId = 11374, groupZoneId = 86, minLevel = 99, maxLevel = 99, releaseIdOnDisappear = true,
        })
        mob:setSpawn(player:getXPos() + 2, player:getYPos(), player:getZPos(), 0)
        mob:spawn()
        mob:setMaxHP(1000000)
        mob:setHP(1000000)
        mob:setUnkillable(true)
        mob:setAutoAttackEnabled(false)

        return mob
    end

    it('adds the bonus during a ranged weapon skill and removes it after; melee weapon skills get none', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RNG, level = 99 })
        player:setSkillLevel(xi.skill.ARCHERY, 5000)
        player:setSkillLevel(xi.skill.AXE, 5000)
        player:addLearnedWeaponskill(xi.wsUnlock.DECIMATION)
        player:addItem(21231) -- Eminent Bow
        player:addItem(21302, 99) -- Eminent Arrow
        player:addItem(20817) -- Eminent Axe
        player:equipItem(20817, nil, xi.slot.MAIN)
        player:equipItem(21231, nil, xi.slot.RANGED)
        player:equipItem(21302, nil, xi.slot.AMMO)

        local mob  = dummyNear(player)
        local base = player:getMod(xi.mod.ALL_WSDMG_ALL_HITS)
        player.actions:engage(mob)

        local seen, restore = spyWsd()

        player:setTP(1000)
        player.actions:useWeaponskill(mob, xi.weaponskill.SIDEWINDER)
        for _ = 1, 4 do
            xi.test.world:skipTime(1) -- one tick per second: a weapon skill takes several ticks to finish
        end

        player:setTP(1000)
        player.actions:useWeaponskill(mob, xi.weaponskill.DECIMATION)
        for _ = 1, 4 do
            xi.test.world:skipTime(1) -- one tick per second: a weapon skill takes several ticks to finish
        end

        restore()

        assert(#seen >= 2, 'expected a ranged and a melee weapon skill, saw ' .. #seen)
        assert(seen[1] == base + bonus, string.format('Sidewinder ran with ALL_WSDMG_ALL_HITS %d, expected %d', seen[1], base + bonus))
        assert(seen[#seen] == base, string.format('Decimation (melee) ran with %d, expected %d', seen[#seen], base))
        assert(player:getMod(xi.mod.ALL_WSDMG_ALL_HITS) == base, 'the bonus was left on the player')
    end)
end)
