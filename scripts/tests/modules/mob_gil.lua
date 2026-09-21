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

    it('leaves mobs that must never drop gil alone', function()
        local mob = makeMob({ max = -1 })

        mobGil.apply(mob, 2)

        assert(mob.mods.max == -1 and mob.mods.min == 0 and mob.changes == 0, 'a negative maximum means "no gil" and must be respected')
    end)

    it('leaves a mob that uses the game\'s level formula plus a bonus alone', function()
        local mob = makeMob({ bonus = 500 })

        mobGil.apply(mob, 2)

        assert(mob.changes == 0, 'replacing the formula with a flat floor could lower a special mob\'s drop')
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
end)
