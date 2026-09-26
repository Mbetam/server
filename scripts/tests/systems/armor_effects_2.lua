-----------------------------------
-- Remaining armor effects and the base abilities they needed (docs/custom/NOTES.md, 2026-09-26): Mana Wall paying damage
-- with MP, the three Dancer flourishes, the Divine Caress ward and Perpetuance gear.
-----------------------------------

describe('Armor effects part 2', function()
    local function spawn(job, zone)
        local player = xi.test.world:spawnPlayer({ zone = zone or xi.zone.WEST_RONFAURE, job = job, level = 99 })
        player:setMP(player:getMaxMP())

        return player
    end

    local function rabbit(player)
        local mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        mob:setMaxHP(20000)
        mob:setHP(20000)
        mob:disengage()
        mob:updateClaim(player)
        player:setPos(mob:getXPos() + 2, mob:getYPos(), mob:getZPos())

        return mob
    end

    it('Mana Wall pays half the damage with MP (and more with gear), HP untouched while MP lasts', function()
        local player = spawn(xi.job.BLM)
        player:addStatusEffect(xi.effect.MANA_WALL, { power = 1, duration = 300, origin = player })
        local hp, mp = player:getHP(), player:getMP()

        player:takeDamage(400)
        assert(player:getHP() == hp, 'HP changed under Mana Wall: ' .. hp .. ' -> ' .. player:getHP())
        assert(mp - player:getMP() == 200, 'Mana Wall should pay 50% of 400 with MP, paid ' .. (mp - player:getMP()))

        player:addMod(xi.mod.MANA_WALL_BONUS, 25) -- Wicce Sabots +3
        mp = player:getMP()
        player:takeDamage(400)
        assert(mp - player:getMP() == 100, 'with +25% Mana Wall should pay 25% of 400, paid ' .. (mp - player:getMP()))
    end)

    it('Mana Wall sends only what MP cannot cover to HP', function()
        local player = spawn(xi.job.BLM)
        player:addStatusEffect(xi.effect.MANA_WALL, { power = 1, duration = 300, origin = player })
        player:setMP(50)
        local hp = player:getHP()

        player:takeDamage(400) -- 200 after the cut: 50 from MP, 150 to HP
        assert(player:getMP() == 0, 'MP should be empty')
        assert(hp - player:getHP() == 150, 'expected 150 HP lost, lost ' .. (hp - player:getHP()))
    end)

    local function giveFinishingMoves(player, count)
        player:addStatusEffect(xi.effect.FINISHING_MOVE_1, { power = count, duration = 7200, origin = player })
    end

    it('Climactic Flourish uses all finishing moves, gear adds a round and the damage %, and attacking uses it up', function()
        local player = spawn(xi.job.DNC)
        local mob    = rabbit(player)
        player:addItem(xi.item.BRONZE_DAGGER)
        player:equipItem(xi.item.BRONZE_DAGGER, nil, xi.slot.MAIN)
        player:addMod(xi.mod.CLIMACTIC_FLOURISH_BONUS, 31) -- Maculele Tiara +3
        giveFinishingMoves(player, 3)

        player.actions:useAbility(player, xi.jobAbility.CLIMACTIC_FLOURISH)
        xi.test.world:skipTime(2)

        local effect = player:getStatusEffect(xi.effect.CLIMACTIC_FLOURISH)
        assert(effect, 'no Climactic Flourish effect')
        assert(effect:getPower() == 4 and effect:getSubPower() == 31, string.format('power %d sub %d, expected 4 / 31', effect:getPower(), effect:getSubPower()))
        assert(not player:hasStatusEffect(xi.effect.FINISHING_MOVE_1), 'finishing moves should be spent')

        player.actions:engage(mob)
        for _ = 1, 30 do
            xi.test.world:skipTime(1)
        end

        assert(not player:hasStatusEffect(xi.effect.CLIMACTIC_FLOURISH), 'the four forced crits should be used up after 30 s of attacking')
    end)

    it('Striking (2 moves) and Ternary (3 moves) Flourish can be used again and end after one attack round', function()
        for _, case in ipairs({ { xi.jobAbility.STRIKING_FLOURISH, xi.effect.STRIKING_FLOURISH, 2 }, { xi.jobAbility.TERNARY_FLOURISH, xi.effect.TERNARY_FLOURISH, 3 } }) do
            local player = spawn(xi.job.DNC)
            local mob    = rabbit(player)
            player:addItem(xi.item.BRONZE_DAGGER)
            player:equipItem(xi.item.BRONZE_DAGGER, nil, xi.slot.MAIN)
            giveFinishingMoves(player, case[3])

            player.actions:useAbility(player, case[1])
            xi.test.world:skipTime(2)
            assert(player:hasStatusEffect(case[2]), 'flourish ' .. case[1] .. ' was not usable with ' .. case[3] .. ' moves')

            player.actions:engage(mob)
            for _ = 1, 15 do
                xi.test.world:skipTime(1)
            end

            assert(not player:hasStatusEffect(case[2]), 'flourish ' .. case[1] .. ' should end after the round it boosts')
        end
    end)

    it('Divine Caress: Poisona leaves a ward that resists the next Poison (1 + gear times)', function()
        local whm = spawn(xi.job.WHM, xi.zone.GM_HOME)
        whm:addStatusEffect(xi.effect.DIVINE_CARESS_I, { power = 3, duration = 60, origin = whm })
        whm:addMod(xi.mod.DIVINE_CARESS_BONUS, 2) -- Ebers Mitts
        whm:addStatusEffect(xi.effect.POISON, { power = 5, duration = 60, origin = whm })

        whm:addSpell(xi.magic.spell.POISONA)
        whm.actions:useSpell(whm, xi.magic.spell.POISONA)
        for _ = 1, 5 do
            xi.test.world:skipTime(1)
        end

        local ward = whm:getStatusEffect(xi.effect.DIVINE_CARESS_II)
        assert(ward, 'no Divine Caress ward after Poisona')
        assert(ward:getSubPower() == xi.effect.POISON and ward:getPower() == 3, string.format('ward power %d sub %d', ward:getPower(), ward:getSubPower()))

        for i = 1, 3 do
            assert(xi.data.statusEffect.isEffectNullified(whm, xi.effect.POISON, 0), 'resist ' .. i .. ' of 3 failed')
        end

        assert(not whm:hasStatusEffect(xi.effect.DIVINE_CARESS_II), 'the ward should be used up after 3 resists')
        assert(not xi.data.statusEffect.isEffectNullified(whm, xi.effect.POISON, 0), 'a 4th Poison should land')
    end)

    it('Perpetuance gear raises the duration multiplier from x2 to x2.65', function()
        local sch   = spawn(xi.job.SCH, xi.zone.GM_HOME)
        local regen = GetSpell(xi.magic.spell.REGEN)
        sch:addStatusEffect(xi.effect.PERPETUANCE, { power = 1, duration = 60, origin = sch })

        local function duration()
            return xi.spells.enhancing.calculateEnhancingDuration(sch, sch, regen, xi.magic.spell.REGEN, xi.magic.spellGroup.WHITE, xi.effect.REGEN)
        end

        local plain = duration()
        sch:addMod(xi.mod.PERPETUANCE_EFFECT, 65)
        assert(math.abs(duration() - plain * 2.65 / 2) <= 1, string.format('x2 %d -> x2.65 %d', plain, duration()))
    end)
end)
