-----------------------------------
-- The mob gil floor (modules/custom/lua/mob_gil.lua). Pure logic with a stand-in mob; the real kills are in mob_gil_engine.lua.
-----------------------------------
local mobGil = require('modules/custom/lua/mob_gil')
-----------------------------------

describe('Mob gil floor', function()
    -- A stand-in mob that remembers its gil mods and what was changed
    local function makeMob(mods)
        local mob = { mods = { min = 0, max = 0, bonus = 0 }, changes = 0 }

        for name, value in pairs(mods or {}) do
            mob.mods[name] = value
        end

        mob.getMobMod = function(self, mod)
            if mod == xi.mobMod.GIL_MIN then return self.mods.min end
            if mod == xi.mobMod.GIL_MAX then return self.mods.max end
            if mod == xi.mobMod.GIL_BONUS then return self.mods.bonus end
        end

        mob.setMobMod = function(self, mod, value)
            self.changes = self.changes + 1

            if mod == xi.mobMod.GIL_MIN then self.mods.min = value end
            if mod == xi.mobMod.GIL_MAX then self.mods.max = value end
        end

        return mob
    end

    it('stores the floor divided by the gil multiplier, so players receive the full amount', function()
        assert(mobGil.baseGil == 500, 'the base drop should be 500 gil')
        assert(mobGil.floorFor(2) == 250, 'with the x2 multiplier the floor is 250')
        assert(mobGil.floorFor(1) == 500)
        assert(mobGil.floorFor(4) == 125)
        assert(mobGil.floorFor(0.5) == 1000)
    end)

    it('never delivers less than the base drop, even when the division is not exact', function()
        for _, multiplier in ipairs({ 0.3, 1, 1.5, 2, 2.5, 3, 7 }) do
            assert(mobGil.floorFor(multiplier) * multiplier >= mobGil.baseGil, 'a multiplier of ' .. multiplier .. ' would deliver less than 500')
        end
    end)

    it('treats a missing or zero multiplier as 1', function()
        assert(mobGil.floorFor(nil) == 500 and mobGil.floorFor(0) == 500 and mobGil.floorFor(-3) == 500)
    end)

    it('gives a mob that dropped nothing the floor', function()
        local mob = makeMob()

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 250, 'a mob with no gil should get exactly the floor')
    end)

    it('raises a small natural drop to the floor', function()
        local mob = makeMob({ min = 10, max = 20 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 250, 'a 10-20 gil drop should become the floor')
    end)

    it('keeps a range that is only partly below the floor', function()
        local mob = makeMob({ min = 0, max = 800 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 800, 'the top of the range should be kept')
    end)

    it('never lowers a bigger natural drop', function()
        local mob = makeMob({ min = 3000, max = 9000 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 3000 and mob.mods.max == 9000 and mob.changes == 0, 'a drop above the floor must be left exactly as it is')
    end)

    it('gives a mob the game marks as never dropping gil the floor too', function()
        local mob = makeMob({ max = -1 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 250, 'a negative maximum ("never drops gil") should become the floor: ' .. mob.mods.min .. '-' .. mob.mods.max)
    end)

    it('treats every negative maximum the same', function()
        for _, max in ipairs({ -1, -5, -32000 }) do
            local mob = makeMob({ max = max })

            mobGil.apply(mob, 2)

            assert(mob.mods.min == 250 and mob.mods.max == 250, 'a maximum of ' .. max .. ' should become the floor')
        end
    end)

    it('keeps a minimum above the floor on a never-drop mob', function()
        local mob = makeMob({ min = 900, max = -1 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 900 and mob.mods.max == 900, 'a bigger minimum must not be lowered: ' .. mob.mods.min .. '-' .. mob.mods.max)
    end)

    it('gives a mob that uses a gil bonus a minimum that still delivers the floor after the bonus', function()
        local mob = makeMob({ bonus = 50 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == mobGil.minForBonus(250, 50), 'the minimum should be stored divided by the bonus: ' .. mob.mods.min)
        assert(mob.mods.max == 0, 'a bonus mob keeps no maximum, or the game would ignore its bonus')
        assert(mob.mods.min * 50 / 100 >= 250, 'the minimum times the bonus must reach the floor')
    end)

    it('never stores a minimum that falls short of the floor, for any bonus', function()
        for bonus = 1, 3000 do
            local minimum = mobGil.minForBonus(250, bonus)

            assert(minimum * bonus >= 250 * 100, 'a bonus of ' .. bonus .. ' with minimum ' .. minimum .. ' falls short of 250')
            assert(minimum <= math.ceil(250 * 100 / bonus) + 1, 'a bonus of ' .. bonus .. ' asks for more than needed: ' .. minimum)
        end
    end)

    it('adds nothing extra for the neutral bonus of 100', function()
        assert(mobGil.minForBonus(250, 100) == 250, 'a bonus of 100 multiplies by exactly one')
    end)

    it('adds a point where the bonus divides the floor exactly, so float rounding cannot drop it below', function()
        assert(mobGil.minForBonus(250, 50) == 501 and mobGil.minForBonus(250, 8) == 3126, 'exact multiples need the extra point')
        assert(mobGil.minForBonus(250, 70) == 358, 'a bonus that does not divide it exactly does not')
    end)

    it('does not lower a bonus mob whose natural minimum is already higher', function()
        local mob = makeMob({ min = 5000, bonus = 50 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 5000 and mob.changes == 0, 'a bigger minimum must be left exactly as it is')
    end)

    it('takes the "never drops gil" mark off a mob that also has a bonus', function()
        local mob = makeMob({ max = -1, bonus = 50 })

        mobGil.apply(mob, 2)

        assert(mob.mods.max == 0 and mob.mods.min == mobGil.minForBonus(250, 50), 'the mob should have a minimum and no negative maximum: ' .. mob.mods.min .. '-' .. mob.mods.max)
    end)

    it('leaves a mob with both a maximum and a bonus alone, since a floor could lower it', function()
        local mob = makeMob({ max = 300, bonus = 500 })

        mobGil.apply(mob, 2)

        assert(mob.changes == 0, 'a maximum together with a bonus is rolled in a way the floor could make smaller')
    end)

    it('treats a negative bonus (the game\'s way of saying "no gil") like no bonus', function()
        local mob = makeMob({ bonus = -100 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 250, 'a negative bonus mob should get the plain floor')
    end)

    it('avoids a range of exactly one, which the game treats as a mistake', function()
        -- 10-251 raised to the 250 floor would become 250-251, a range one wide
        local mob = makeMob({ min = 10, max = 251 })

        mobGil.apply(mob, 2)

        assert(mob.mods.min == 250 and mob.mods.max == 250, 'the range should be made exact instead of one wide: ' .. mob.mods.min .. '-' .. mob.mods.max)
    end)

    it('can be applied repeatedly with the same result', function()
        local once  = makeMob({ min = 10, max = 20 })
        local often = makeMob({ min = 10, max = 20 })

        mobGil.apply(once, 2)

        for _ = 1, 5 do
            mobGil.apply(often, 2)
        end

        assert(once.mods.min == often.mods.min and once.mods.max == often.mods.max, 'the game calls the hook once per alliance member')
        assert(often.changes == 2, 'after the first application nothing more should change')
    end)

    it('can be applied repeatedly to a never-drop mob and to a bonus mob', function()
        for _, spec in ipairs({ { max = -1 }, { bonus = 50 }, { max = -1, bonus = 50 }, { bonus = -100 } }) do
            local once  = makeMob(spec)
            local often = makeMob(spec)

            mobGil.apply(once, 2)

            for _ = 1, 5 do
                mobGil.apply(often, 2)
            end

            assert(once.mods.min == often.mods.min and once.mods.max == often.mods.max, 'repeating changed the result')
            assert(often.changes == once.changes, 'after the first application nothing more should change')
        end
    end)
end)
