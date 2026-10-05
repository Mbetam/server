-----------------------------------
-- modules/custom/lua/ws_power.lua: melee and magic weapon skills run with WEAPON_SKILL_POWER x1.45; ranged ones keep
-- the base (they have ranged_ws_bonus.lua instead); the setting is put back after each.
-----------------------------------

describe('Weapon skill power', function()
    local power = xi.custom.wsPower

    -- Records WEAPON_SKILL_POWER each time a weapon skill's damage is applied
    local function spyPower()
        local seen = {}
        local take = xi.weaponskills.takeWeaponskillDamage

        xi.weaponskills.takeWeaponskillDamage = function(...)
            table.insert(seen, xi.settings.main.WEAPON_SKILL_POWER)
            return take(...)
        end

        return seen, function() xi.weaponskills.takeWeaponskillDamage = take end
    end

    local function dummyNear(player)
        local mob = player:getZone():insertDynamicEntity(
        {
            objtype = xi.objType.MOB, name = 'WSP_Dummy', x = player:getXPos() + 2, y = player:getYPos(), z = player:getZPos(), rotation = 0,
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

    local function use(player, mob, ws)
        player:setTP(1000)
        player.actions:useWeaponskill(mob, ws)
        for _ = 1, 4 do
            xi.test.world:skipTime(1) -- one tick per second: a weapon skill takes several ticks to finish
        end
    end

    it('multiplies melee and magic weapon skills, not ranged ones, and restores the setting', function()
        local base   = xi.settings.main.WEAPON_SKILL_POWER
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RNG, level = 99 })

        player:setSkillLevel(xi.skill.AXE, 5000)
        player:setSkillLevel(xi.skill.DAGGER, 5000)
        player:setSkillLevel(xi.skill.ARCHERY, 5000)
        player:addLearnedWeaponskill(xi.wsUnlock.DECIMATION)
        player:addItem(20817) -- Eminent Axe
        player:addItem(xi.item.BRONZE_DAGGER)
        player:addItem(21231) -- Eminent Bow
        player:addItem(21302, 99) -- Eminent Arrow

        local mob = dummyNear(player)
        local seen, restore = spyPower()

        player:equipItem(20817, nil, xi.slot.MAIN)
        player.actions:engage(mob)
        use(player, mob, xi.weaponskill.DECIMATION)

        player:equipItem(xi.item.BRONZE_DAGGER, nil, xi.slot.MAIN)
        use(player, mob, xi.weaponskill.AEOLIAN_EDGE)

        player:equipItem(21231, nil, xi.slot.RANGED)
        player:equipItem(21302, nil, xi.slot.AMMO)
        use(player, mob, xi.weaponskill.SIDEWINDER)

        restore()

        assert(#seen >= 3, 'expected three weapon skills, saw ' .. #seen)
        assert(math.abs(seen[1] - base * power.physical) < 0.001, string.format('Decimation ran with %.3f, expected %.3f', seen[1], base * power.physical))
        assert(math.abs(seen[2] - base * power.magical) < 0.001, string.format('Aeolian Edge ran with %.3f, expected %.3f', seen[2], base * power.magical))
        assert(math.abs(seen[#seen] - base) < 0.001, string.format('Sidewinder (ranged) ran with %.3f, expected %.3f', seen[#seen], base))
        assert(xi.settings.main.WEAPON_SKILL_POWER == base, 'WEAPON_SKILL_POWER was not restored')
    end)
end)
