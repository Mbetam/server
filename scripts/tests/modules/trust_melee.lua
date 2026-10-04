-----------------------------------
-- The melee trusts that only auto-attacked (trust audit; fixed 2026-10-04): each one is summoned next to a monster and
-- what it actually uses is recorded through the engine's own listeners. The player holds the monster's hate (a tank).
-----------------------------------

describe('Melee trusts', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local trust
    local used

    local function idOf(thing)
        if type(thing) == 'number' then
            return thing
        end

        return thing:getID()
    end

    local function count(tbl, key)
        tbl[key] = (tbl[key] or 0) + 1
    end

    local function summon(spellId)
        player:spawnTrust(spellId)
        xi.test.world:skipTime(2)

        trust = nil
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                trust = member
            end
        end

        assert(trust, 'the trust was not summoned')

        used = { spell = {}, ability = {}, skill = {} }
        trust:addListener('MAGIC_USE', 'TEST_MELEE_MAGIC', function(entity, target, spell)
            count(used.spell, idOf(spell))
        end)
        trust:addListener('ABILITY_USE', 'TEST_MELEE_ABILITY', function(entity, target, ability)
            count(used.ability, idOf(ability))
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_MELEE_WS', function(entity, target, skill)
            count(used.skill, idOf(skill))
        end)
    end

    local function fight(seconds)
        player.actions:engage(mob)

        for _ = 1, seconds / 2 do
            mob:addEnmity(player, 30000, 30000)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end
    end

    local function reset()
        used = { spell = {}, ability = {}, skill = {} }
    end

    local function usedAny(tbl, ids)
        for _, id in ipairs(ids) do
            if tbl[id] then
                return true
            end
        end

        return false
    end

    local function dump()
        local parts = {}

        for kind, tbl in pairs(used) do
            for id, n in pairs(tbl) do
                table.insert(parts, string.format('%s %d x%d', kind, id, n))
            end
        end

        table.sort(parts)

        return 'used: ' .. (#parts > 0 and table.concat(parts, ', ') or 'nothing')
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    -- name, trust, job abilities it must use, its TP moves (one of them must be used; none from outside the list),
    -- player TP to give (openers wait for a party member's TP)
    local cases =
    {
        { 'Zazarg', 'ZAZARG', { 'FOCUS' }, { 7, 8, 9 } },
        { 'Luzaf', 'LUZAF', { 'TRIPLE_SHOT' }, { 3253 } },
        { 'Najelith', 'NAJELITH', { 'BARRAGE', 'DOUBLE_SHOT' }, { 20, 196, 199 } },
        { 'Elivira', 'ELIVIRA', { 'BERSERK', 'BARRAGE' }, { 216, 212, 214, 209 } },
        { 'Noillurie', 'NOILLURIE', { 'HASSO' }, { 148, 150, 151, 152, 153 } },
        { 'Lhu Mhakaracca', 'LHU_MHAKARACCA', { 'BERSERK', 'AGGRESSOR' }, { 68, 69, 73, 72 } },
        { 'Klara', 'KLARA', { 'BERSERK', 'WARCRY' }, { 32, 40, 42 } },
        { 'Romaa Mihgo', 'ROMAA_MIHGO', { 'FEINT', 'SNEAK_ATTACK' }, { 32, 40, 42 } },
        { 'Flaviria (UC)', 'FLAVIRIA_UC', { 'BERSERK', 'JUMP' }, { 118, 120 } },
        { 'Abenzio', 'ABENZIO', {}, { 3355, 3356, 3357, 3358 } },
        { 'Babban', 'BABBAN', {}, { 3351, 3353 } },
        { 'Lhe Lhangavo', 'LHE_LHANGAVO', { 'FOCUS', 'IMPETUS' }, { 4, 5, 8, 9 } },
        { 'Mayakov', 'MAYAKOV', { 'SABER_DANCE' }, { 32, 41, 40 } },
        { 'Rongelouts', 'RONGELOUTS', { 'BERSERK', 'AGGRESSOR', 'WARCRY' }, { 34, 42, 37 } },
        { 'Maximilian', 'MAXIMILIAN', {}, { 32, 40, 41 }, 1500 },
        { 'Ayame (UC)', 'AYAME_UC', { 'HASSO' }, { 148, 149, 152, 155 } },
        { 'Aldo (UC)', 'ALDO_UC', { 'BULLY', 'SNEAK_ATTACK' }, {} },
        { 'Jakoh (UC)', 'JAKOH_UC', { 'FEINT', 'CONSPIRATOR' }, { 23, 25 } },
        { 'Naja (UC)', 'NAJA_UC', {}, { 3215, 168, 3502, 169 }, 1000 },
        { 'Invincible Shield (UC)', 'INVINCIBLE_SHIELD_UC', { 'PROVOKE', 'AGGRESSOR', 'WARCRY' }, { 86, 88 } },
        { 'Iroha', 'IROHA', { 'HASSO' }, {} },
        { "Selh'teus", 'SELHTEUS', {}, { 3621, 3623 } },
        { 'Lilisette', 'LILISETTE', {}, { 2444, 2445 } },
    }

    for _, case in ipairs(cases) do
        local name, key, abilities, moves, playerTP = case[1], case[2], case[3], case[4], case[5]

        it(name .. ' uses its job abilities and its weapon skills', function()
            local spellId = xi.magic.spell[key]
            assert(spellId, 'no trust spell ' .. key)

            summon(spellId)
            trust:setTP(3000)
            if playerTP then
                player:setTP(playerTP)
            end

            fight(40)

            for _, ja in ipairs(abilities) do
                assert(used.ability[xi.jobAbility[ja]], 'no ' .. ja .. '. ' .. dump())
            end

            if #moves > 0 then
                assert(usedAny(used.skill, moves), 'none of its weapon skills. ' .. dump())
            end
        end)
    end

    it("Selh'teus uses Rejuvenation when his master drops to yellow HP", function()
        summon(xi.magic.spell.SELHTEUS)
        fight(6)
        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.6))
        fight(8)

        assert(used.skill[3622], 'no Rejuvenation. ' .. dump())
        assert(player:getHPP() == 100, 'the master was not restored to full HP: ' .. player:getHPP() .. '%')
    end)

    it('Lhu Mhakaracca uses Feral Howl on an enemy under 20% HP', function()
        summon(xi.magic.spell.LHU_MHAKARACCA)
        fight(6)
        reset()
        mob:setHP(math.floor(mob:getMaxHP() * 0.1))
        fight(10)

        assert(used.ability[xi.jobAbility.FERAL_HOWL], 'no Feral Howl. ' .. dump())
    end)

    it('Klara and Lhe Lhangavo Provoke when the master is under 50% HP', function()
        for _, spellId in ipairs({ xi.magic.spell.KLARA, xi.magic.spell.LHE_LHANGAVO }) do
            summon(spellId)
            player:setHP(math.floor(player:getMaxHP() * 0.4))
            fight(20) -- one action per gambit tick: Berserk / Warcry / Focus may come first

            assert(used.ability[xi.jobAbility.PROVOKE], 'no Provoke for a hurt master (' .. spellId .. '). ' .. dump())
            player:clearTrusts()
            player:setHP(player:getMaxHP())
            xi.test.world:skipTime(4)
        end
    end)

    it('Noillurie cures a master under 50% HP', function()
        summon(xi.magic.spell.NOILLURIE)
        fight(6)
        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.4))
        fight(10)

        assert(usedAny(used.spell, { xi.magic.spell.CURE_IV, xi.magic.spell.CURE_III }), 'no Cure. ' .. dump())
    end)

    it('Iroha and Iroha II keep Protectra / Shellra up', function()
        for _, spellId in ipairs({ xi.magic.spell.IROHA, xi.magic.spell.IROHA_II }) do
            summon(spellId)
            fight(30)

            assert(used.spell[xi.magic.spell.PROTECTRA_V], 'no Protectra V (' .. spellId .. '). ' .. dump())
            -- The highest tier her MP allows (Iroha has little MP)
            assert(usedAny(used.spell, { xi.magic.spell.SHELLRA_V, xi.magic.spell.SHELLRA_IV, xi.magic.spell.SHELLRA_III }), 'no Shellra (' .. spellId .. '). ' .. dump())
            player:clearTrusts()
            xi.test.world:skipTime(4)
        end
    end)

    it('Iroha II magic bursts Flare II on a fire skillchain', function()
        summon(xi.magic.spell.IROHA_II)
        fight(20) -- buffs first

        mob:setMobAbilityEnabled(false)
        trust:setMP(trust:getMaxMP())
        reset()
        mob:delStatusEffect(xi.effect.SKILLCHAIN)
        mob:addStatusEffect(xi.effect.SKILLCHAIN, { power = xi.skillchainType.LIQUEFACTION, duration = 15, tier = 2, origin = player })
        fight(12)

        assert(used.spell[xi.magic.spell.FLARE_II], 'no Flare II burst on Liquefaction. ' .. dump())
    end)

    it('Lilisette keeps Rousing Samba up and Waltzes when her master is under 50% HP', function()
        summon(xi.magic.spell.LILISETTE)
        trust:setTP(1000)
        fight(10)
        assert(used.skill[3312], 'no Rousing Samba. ' .. dump())

        reset()
        trust:setTP(1000)
        player:setHP(math.floor(player:getMaxHP() * 0.4))
        fight(10)
        assert(used.skill[3313], 'no Vivifying Waltz for a master at 40%. ' .. dump())
    end)

    it('melee trusts can be released mid-fight (Lilisette and the burst kit remove their listeners)', function()
        for _, spellId in ipairs({ xi.magic.spell.LILISETTE, xi.magic.spell.IROHA_II, xi.magic.spell.MAYAKOV }) do
            summon(spellId)
            fight(6)
            player:clearTrusts()
            xi.test.world:skipTime(4)
        end
    end)
end)
