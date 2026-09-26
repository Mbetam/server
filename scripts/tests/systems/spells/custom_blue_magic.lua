-----------------------------------
-- The 29 Blue Magic spells (levels 77-99) LSB had no script for (docs/custom/NOTES.md, 2026-09-25). Each is cast
-- for real by a level 99 BLU against a Wild Rabbit or on themselves.
-----------------------------------

describe('Custom Blue Magic', function()
    -- Unbridled Learning spells are not set; they need the Unbridled Learning effect (the engine checks it)
    local unbridled =
    {
        [736] = true, [737] = true, [738] = true, [739] = true, [740] = true, [741] = true, [742] = true, [743] = true,
    }

    local function setup(spellId)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLU, level = 99 })
        player:capSkill(xi.skill.BLUE_MAGIC) -- at the cap, so casting can't skill up mid-test
        player:addSpell(spellId)

        if unbridled[spellId] then
            player:addStatusEffect(xi.effect.UNBRIDLED_LEARNING, { power = 1, duration = 60, origin = player })
        else
            player.actions:setBlueSpells({ spellId })
        end

        local mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        mob:setMaxHP(5000)
        mob:setHP(5000)
        mob:disengage()
        mob:updateClaim(player)
        player:setPos(mob:getXPos() + 2, mob:getYPos(), mob:getZPos())
        player:lookAt(mob:getPos())
        player:setMP(player:getMaxMP())
        player:setTP(1000)

        return player, mob
    end

    local function cast(player, target, spellId)
        player:resetRecasts()
        player.actions:useSpell(target, spellId)

        for _ = 1, 12 do
            xi.test.world:skipTime(1)
        end
    end

    local damaging =
    {
        { 'Acrid Stream',    656 }, { 'Blazing Bound',   657 }, { 'Leafstorm',       663 }, { 'Final Sting',  665 },
        { 'Vanity Dive',     667 }, { 'Benthic Typhoon', 670 }, { 'Barbed Crescent', 699 }, { 'Dark Orb',     689 },
        { 'Water Bomb',      687 }, { 'Vapor Spray',     694 }, { 'Thunder Breath',  695 }, { 'Thunderbolt',  736 },
        { 'Gates of Hades',  739 }, { 'Tourbillion',     740 }, { 'Bilgestorm',      742 }, { 'Bloodrake',    743 },
    }

    for _, case in ipairs(damaging) do
        it(case[1] .. ' deals damage', function()
            local player, mob = setup(case[2])
            cast(player, mob, case[2])
            assert(mob:getHP() < 5000, case[1] .. ' did no damage')
        end)
    end

    it('Everyone\'s Grudge scales with Tonberry kills and does nothing without any', function()
        local player, mob = setup(683)
        cast(player, mob, 683)
        assert(mob:getHP() == 5000, 'no kills should mean no damage')

        player:setCharVar('EVERYONES_GRUDGE_KILLS', 40)
        cast(player, mob, 683)
        assert(mob:getHP() < 5000, 'with 40 kills it should hit')
    end)

    it('Bloodrake heals the caster', function()
        local player, mob = setup(743)
        player:setHP(100)
        cast(player, mob, 743)
        assert(player:getHP() > 100, 'no HP drained')
    end)

    it('Final Sting drops the caster to 1 HP', function()
        local player, mob = setup(665)
        cast(player, mob, 665)
        assert(player:getHP() == 1, 'HP should be 1, is ' .. player:getHP())
    end)

    local debuffs =
    {
        { 'Demoralizing Roar', 659, xi.effect.ATTACK_DOWN   },
        { 'Absolute Terror',   738, xi.effect.TERROR        },
        { 'Acrid Stream',      656, xi.effect.MAGIC_DEF_DOWN },
    }

    for _, case in ipairs(debuffs) do
        it(case[1] .. ' applies its effect', function()
            local landed = false

            for _ = 1, 5 do -- can be resisted
                local player, mob = setup(case[2])
                cast(player, mob, case[2])
                landed = mob:hasStatusEffect(case[3])

                if landed then
                    break
                end
            end

            assert(landed, case[1] .. ' did not land in 5 casts')
        end)
    end

    it('Reaving Wind takes 1000 TP', function()
        local player, mob = setup(684)
        mob:setTP(2000)
        cast(player, mob, 684)
        assert(mob:getTP() <= 1000, 'TP is ' .. mob:getTP())
    end)

    it('Osmosis drains HP and steals a buff', function()
        local player, mob = setup(672)
        mob:addStatusEffect(xi.effect.PROTECT, { power = 20, duration = 300, origin = mob })
        player:setHP(100)
        cast(player, mob, 672)
        assert(player:getHP() > 100, 'no HP drained')
        assert(not mob:hasStatusEffect(xi.effect.PROTECT) and player:hasStatusEffect(xi.effect.PROTECT), 'Protect not stolen')
    end)

    local selfBuffs =
    {
        { 'Magic Barrier',        668, xi.effect.STONESKIN       },
        { 'Barrier Tusk',         685, xi.effect.PHALANX         },
        { 'Harden Shell',         737, xi.effect.DEFENSE_BOOST   },
        { 'Orcish Counterstance', 696, xi.effect.COUNTER_BOOST   },
        { 'Pyric Bulwark',        741, xi.effect.PHYSICAL_SHIELD },
        { 'Fantod',               674, xi.effect.BOOST           },
    }

    for _, case in ipairs(selfBuffs) do
        it(case[1] .. ' buffs the caster', function()
            local player = setup(case[2])
            cast(player, player, case[2])
            assert(player:hasStatusEffect(case[3]), case[1] .. ' gave no effect')
        end)
    end

    it('buff numbers: Magic Barrier = Blue Magic skill, Barrier Tusk -15% uncapped, Counterstance +10 / +50%', function()
        local p1 = setup(668)
        cast(p1, p1, 668)
        assert(p1:getStatusEffect(xi.effect.STONESKIN):getPower() == p1:getSkillLevel(xi.skill.BLUE_MAGIC), 'Magic Barrier power')

        local p2 = setup(685)
        local udmg = p2:getMod(xi.mod.UDMGPHYS)
        cast(p2, p2, 685)
        assert(p2:getMod(xi.mod.UDMGPHYS) == udmg - 1500, 'Barrier Tusk should add -1500 UDMGPHYS')

        local p3 = setup(696)
        local counter, counterDmg = p3:getMod(xi.mod.COUNTER), p3:getMod(xi.mod.COUNTER_DAMAGE)
        cast(p3, p3, 696)
        assert(p3:getMod(xi.mod.COUNTER) == counter + 10 and p3:getMod(xi.mod.COUNTER_DAMAGE) == counterDmg + 50, 'Counterstance mods')
    end)

    it('Pyric Bulwark ends after the first physical hit', function()
        local player, mob = setup(741)
        cast(player, player, 741)
        assert(player:hasStatusEffect(xi.effect.PHYSICAL_SHIELD), 'no shield')

        mob:updateEnmity(player)

        for _ = 1, 30 do
            xi.test.world:skipTime(1)

            if not player:hasStatusEffect(xi.effect.PHYSICAL_SHIELD) then
                break
            end
        end

        assert(not player:hasStatusEffect(xi.effect.PHYSICAL_SHIELD), 'shield still up after the rabbit attacked for 30 s')
    end)

    it('Winds of Promyvion erases a debuff', function()
        local player = setup(681)
        player:addStatusEffect(xi.effect.SLOW, { power = 1000, duration = 120, origin = player })
        cast(player, player, 681)
        assert(not player:hasStatusEffect(xi.effect.SLOW), 'Slow not erased')
    end)

    it('Mortal Ray runs (Doom has a very low hit rate, so it may miss)', function()
        local player, mob = setup(686)
        cast(player, mob, 686)
    end)

    it('fixed in bluemagic.lua: LSB\'s own physical spells apply their added effect again (Sudden Lunge stuns)', function()
        local sudden = xi.magic.spell.SUDDEN_LUNGE
        local stunned = false

        for _ = 1, 5 do -- the stun can be resisted
            local player, mob = setup(sudden)
            player:resetRecasts()
            player.actions:useSpell(mob, sudden)

            for _ = 1, 8 do -- the stun only lasts 5 s, so look while it is up
                xi.test.world:skipTime(1)
                stunned = stunned or mob:hasStatusEffect(xi.effect.STUN)
            end

            if stunned then
                break
            end
        end

        assert(stunned, 'Sudden Lunge never stunned in 5 casts')
    end)
end)
