-----------------------------------
-- modules/custom/lua/skillchain_steps.lua: skillchain damage +20% per step after the first, on top of retail's per-step
-- multipliers; step 6 is reachable (battleutils.cpp cap 6). Checked through the skillchain damage function itself on a
-- dummy, for a Light skillchain at steps 1-6.
-----------------------------------

describe('Skillchain steps', function()
    local steps = xi.custom.skillchainSteps

    -- Retail Level 3 (Light / Darkness) multipliers per step (scripts/combat/skillchain.lua)
    local light = { 1.00, 1.50, 1.75, 2.00, 2.25, 2.50 }

    it('adds 20% per step after the first, up to step 6', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        local mob = player:getZone():insertDynamicEntity(
        {
            objtype = xi.objType.MOB, name = 'SC_Dummy', x = player:getXPos() + 2, y = player:getYPos(), z = player:getZPos(), rotation = 0,
            groupId = 11374, groupZoneId = 86, minLevel = 99, maxLevel = 99, releaseIdOnDisappear = true,
        })
        mob:setSpawn(player:getXPos() + 2, player:getYPos(), player:getZPos(), 0)
        mob:spawn()
        mob:setMaxHP(5000000)
        mob:setHP(5000000)
        mob:setUnkillable(true)

        -- Day / weather can randomly add or take 10%: neutral here, so the steps compare exactly
        local dayWeather = xi.spells.damage.calculateDayAndWeather
        xi.spells.damage.calculateDayAndWeather = function()
            return 1
        end

        local damage = {}
        for step = 1, 6 do
            mob:delStatusEffect(xi.effect.SKILLCHAIN)
            mob:addStatusEffect(xi.effect.SKILLCHAIN, { power = xi.skillchainType.LIGHT, duration = 10, tier = 3, subPower = step, origin = player })
            damage[step] = xi.combat.skillchain.calculateSkillchainDamage(player, mob, 10000)
        end

        xi.spells.damage.calculateDayAndWeather = dayWeather

        assert(damage[1] > 0, 'no skillchain damage at step 1')

        for step = 2, 6 do
            local expected = damage[1] * light[step] / light[1] * (1 + steps.perStep * (step - 1) / 100)
            assert(math.abs(damage[step] - expected) <= expected * 0.01 + 2,
                string.format('step %d: %d damage, expected about %d (step 1: %d)', step, damage[step], expected, damage[1]))
        end

        assert(player:getMod(xi.mod.SKILLCHAINDMG) == 0, 'the bonus was left on the player')
    end)
end)
