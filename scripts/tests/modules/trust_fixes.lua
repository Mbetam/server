-----------------------------------
-- The 8 trusts fixed after the trust audit (docs/custom/NOTES.md): summoned for real next to a monster, and every
-- spell, job ability and weapon skill they actually use is recorded through the engine's own listeners.
-----------------------------------

describe('Trust fixes', function()
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
            if member:isTrust() then
                trust = member
            end
        end

        assert(trust, 'the trust was not summoned')

        used = { spell = {}, ability = {}, skill = {} }
        trust:addListener('MAGIC_USE', 'TEST_TRUST_MAGIC', function(entity, target, spell, action)
            count(used.spell, idOf(spell))
        end)
        trust:addListener('ABILITY_USE', 'TEST_TRUST_ABILITY', function(entity, target, ability, action)
            count(used.ability, idOf(ability))
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_TRUST_WS', function(entity, target, skill, tp, action, damage)
            count(used.skill, idOf(skill))
        end)
    end

    local function fight(seconds)
        player.actions:engage(mob)

        for _ = 1, seconds / 2 do
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end
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
        -- Trusts join once the master engages (the !trustengage option). Retail waits for the master's first swing
        -- within the last second, which 2-second test ticks never line up with.
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    it('Ingrid casts Haste on her master, Banish on the monster, Cursna on Doom, and uses her weapon skills', function()
        summon(xi.magic.spell.INGRID)
        fight(40)

        assert(used.spell[xi.magic.spell.HASTE], 'no Haste. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.BANISH, xi.magic.spell.BANISH_II, xi.magic.spell.BANISH_III }), 'no Banish. ' .. dump())

        player:addStatusEffect(xi.effect.DOOM, { power = 10, duration = 60, origin = player })
        trust:setTP(3000)
        fight(20)

        assert(used.spell[xi.magic.spell.CURSNA], 'no Cursna on a Doomed master. ' .. dump())
        assert(usedAny(used.skill, { 161, 167, 168 }), 'no Seraph Strike / Judgment / Hexa Strike. ' .. dump())
    end)

    it('Halver uses Berserk, Flash and his weapon skills, and turns tank when his master is under 40% HP', function()
        summon(xi.magic.spell.HALVER)
        trust:setTP(3000)
        fight(30)

        assert(used.ability[xi.jobAbility.BERSERK], 'no Berserk. ' .. dump())
        assert(used.spell[xi.magic.spell.FLASH], string.format('no Flash (MP %d/%d, TP %d). ', trust:getMP(), trust:getMaxMP(), trust:getTP()) .. dump())
        assert(usedAny(used.skill, { 116, 120, 114 }), 'no Penta Thrust / Impulse Drive / Raiden Thrust. ' .. dump())
        assert(not used.ability[xi.jobAbility.SENTINEL], 'tank mode before anyone was hurt. ' .. dump())

        player:setHP(math.floor(player:getMaxHP() * 0.3))
        fight(40) -- one action per gambit tick: Provoke, Sentinel and a Cure take a few ticks

        assert(used.ability[xi.jobAbility.PROVOKE], 'no Provoke in tank mode. ' .. dump())
        assert(used.ability[xi.jobAbility.SENTINEL], 'no Sentinel in tank mode. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.CURE, xi.magic.spell.CURE_II, xi.magic.spell.CURE_III, xi.magic.spell.CURE_IV }), 'no Cure in tank mode. ' .. dump())
    end)

    it('Cid uses Berserk and Aggressor before True Strike / Hexa Strike', function()
        summon(xi.magic.spell.CID)
        fight(10)

        assert(not used.ability[xi.jobAbility.BERSERK], 'Berserk without the TP for a weapon skill. ' .. dump())

        -- TP rises gradually in a real fight: first somewhere between 1000 and the 2500 he holds for a skillchain
        -- (the engine tries weapon skills before gambits, so a jump straight to 3000 would skip that stage)
        trust:setTP(1200)
        fight(10)
        trust:setTP(3000)
        fight(10)

        assert(used.ability[xi.jobAbility.BERSERK], 'no Berserk. ' .. dump())
        assert(used.ability[xi.jobAbility.AGGRESSOR], 'no Aggressor. ' .. dump())
        assert(usedAny(used.skill, { 166, 168 }), 'no True Strike / Hexa Strike. ' .. dump())
    end)

    it('Gilgamesh uses Hasso, Sekkanoki, Hagakure and his tachi weapon skills', function()
        summon(xi.magic.spell.GILGAMESH)
        fight(6)
        -- Holding TP: Sekkanoki and Hagakure. Kept at 1200, or Meditate would take him to a weapon skill first.
        for _ = 1, 10 do
            trust:setTP(1200)
            fight(2)
        end

        trust:setTP(3000)
        fight(14)

        assert(used.ability[xi.jobAbility.HASSO], 'no Hasso. ' .. dump())
        assert(used.ability[xi.jobAbility.SEKKANOKI], 'no Sekkanoki while holding TP. ' .. dump())
        assert(used.ability[xi.jobAbility.HAGAKURE], 'no Hagakure while holding TP. ' .. dump())
        assert(usedAny(used.skill, { 146, 152 }), 'no Tachi: Goten / Tachi: Kasha. ' .. dump())
    end)

    it('Margret stays at range, uses her ranger abilities and her bow weapon skills', function()
        summon(xi.magic.spell.MARGRET)
        trust:setTP(3000)
        fight(40)

        assert(used.ability[xi.jobAbility.BARRAGE], 'no Barrage. ' .. dump())
        assert(used.ability[xi.jobAbility.SHARPSHOT], 'no Sharpshot. ' .. dump())
        assert(used.ability[xi.jobAbility.DOUBLE_SHOT], 'no Double Shot. ' .. dump())
        assert(usedAny(used.skill, { 196, 198, 201, 193 }), 'no bow weapon skill. ' .. dump())
    end)

    it('Makki-Chebukki uses Barrage, Sharpshot, Flashy Shot and his bow weapon skills', function()
        summon(xi.magic.spell.MAKKI_CHEBUKKI)
        trust:setTP(3000)
        fight(40)

        assert(used.ability[xi.jobAbility.BARRAGE], 'no Barrage. ' .. dump())
        assert(used.ability[xi.jobAbility.FLASHY_SHOT], 'no Flashy Shot. ' .. dump())
        assert(usedAny(used.skill, { 196, 199, 194, 192 }), 'no bow weapon skill. ' .. dump())
    end)

    it('Nashmeira cures a master under 33% HP, removes poison, and uses Imperial Authority', function()
        summon(xi.magic.spell.NASHMEIRA)
        fight(10)

        assert(not usedAny(used.spell, { xi.magic.spell.CURE, xi.magic.spell.CURE_II, xi.magic.spell.CURE_III, xi.magic.spell.CURE_IV }), 'cured a healthy master. ' .. dump())

        player:setHP(math.floor(player:getMaxHP() * 0.2))
        player:addStatusEffect(xi.effect.POISON, { power = 1, duration = 120, origin = player })
        trust:setTP(3000)
        fight(30)

        assert(usedAny(used.spell, { xi.magic.spell.CURE, xi.magic.spell.CURE_II, xi.magic.spell.CURE_III, xi.magic.spell.CURE_IV }), 'no Cure at 20% HP. ' .. dump())
        assert(used.spell[xi.magic.spell.POISONA], 'no Poisona. ' .. dump())
        assert(used.skill[3243], 'no Imperial Authority. ' .. dump())
    end)

    it('Morimar: Vehement Resolution heals him and makes 12 Blades of Remorse his next weapon skill, then back to normal', function()
        summon(xi.magic.spell.MORIMAR)
        local order = {}
        trust:addListener('WEAPONSKILL_USE', 'TEST_MORIMAR_ORDER', function(entity, target, skill, tp)
            table.insert(order, string.format('%d(tp%d,glow%d)', type(skill) == 'number' and skill or skill:getID(), tp or -1, entity:getLocalVar('[Morimar]Resolve')))
        end)
        fight(6)

        trust:setHP(math.floor(trust:getMaxHP() / 2))
        trust:setTP(1200) -- holding TP for a skillchain: Vehement Resolution's turn
        fight(8)

        assert(used.skill[3676], 'no Vehement Resolution. ' .. dump())
        assert(trust:getHPP() >= 95, 'Vehement Resolution did not heal him: ' .. trust:getHPP() .. '%')
        assert(trust:getLocalVar('[Morimar]Resolve') == 1, 'no glow after Vehement Resolution')

        -- Between 2000 and 2999: at 3000 TP the engine always uses a TP-list weapon skill, whatever the trust's settings
        -- (in a real fight his TP climbs from 0 after Vehement Resolution, so it passes through this range)
        trust:setTP(2200)
        fight(12)

        assert(used.skill[3680] == 1, '12 Blades of Remorse was not his next weapon skill. ' .. dump() .. ' order: ' .. table.concat(order, ' '))
        assert(not usedAny(used.skill, { 3677, 3678, 3679 }), 'another weapon skill while glowing. ' .. dump())
        assert(trust:getLocalVar('[Morimar]Resolve') == 0, 'the glow did not end with 12 Blades of Remorse')

        trust:setTP(3000)
        fight(12)

        assert(usedAny(used.skill, { 3677, 3678, 3679 }), 'no normal weapon skill after the glow. ' .. dump())
        assert(used.skill[3680] == 1, '12 Blades of Remorse again without Vehement Resolution. ' .. dump())
    end)

    it('Lilisette II: Rousing Samba once for 350 TP, weapon skills, and Vivifying Waltz only with 3 hurt party members', function()
        summon(xi.magic.spell.LILISETTE_II)
        fight(4)

        local critBefore = trust:getMod(xi.mod.CRITHITRATE)
        trust:setTP(500)
        fight(6)

        assert(used.skill[3312] == 1, 'no Rousing Samba. ' .. dump())
        assert(trust:getMod(xi.mod.CRITHITRATE) == critBefore + 65, 'Rousing Samba did not raise her critical hit rate')

        -- Only her master hurt: no Waltz, even holding enough TP
        player:setHP(math.floor(player:getMaxHP() / 2))
        trust:setTP(1500)
        fight(8)

        assert(not used.skill[3313], 'Vivifying Waltz with only one hurt party member. ' .. dump())
        assert(used.skill[3312] == 1, 'Rousing Samba used again while already up. ' .. dump())

        -- A second trust and everyone at half HP: three hurt, Waltz
        player:spawnTrust(xi.magic.spell.NAJI)
        xi.test.world:skipTime(2)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            member:setHP(math.floor(member:getMaxHP() / 2))
        end

        local hpBefore = player:getHP()
        trust:setTP(1500)
        fight(8)

        assert(used.skill[3313], 'no Vivifying Waltz with three hurt party members. ' .. dump())
        assert(player:getHP() > hpBefore, 'Vivifying Waltz did not heal her master')

        trust:setTP(3000)
        fight(10)

        assert(usedAny(used.skill, { 3311, 3310 }), 'no Whirling Edge / Dancer\'s Fury. ' .. dump())
    end)

    describe('Kukki-Chebukki casts only the day\'s element', function()
        local fireSpells = { xi.magic.spell.FIRE, xi.magic.spell.FIRE_II, xi.magic.spell.FIRE_III, xi.magic.spell.FIRE_IV, xi.magic.spell.FIRE_V, xi.magic.spell.BURN }

        it('nukes with fire on Firesday', function()
            stub('VanadielDayElement', xi.element.FIRE)
            summon(xi.magic.spell.KUKKI_CHEBUKKI)
            fight(40)

            assert(usedAny(used.spell, fireSpells), 'no fire spell. ' .. dump())

            for id in pairs(used.spell) do
                local isFire = false
                for _, fire in ipairs(fireSpells) do
                    isFire = isFire or id == fire
                end

                assert(isFire, 'cast a non-fire spell on Firesday. ' .. dump())
            end
        end)

        it('switches to ice when the day changes mid-fight', function()
            -- One stub whose value changes: stubbing the same global twice in one test leaves a dangling stub behind
            -- after the test, and the next call to it (from any later test) crashes xi_test.
            local day = xi.element.FIRE
            stub('VanadielDayElement', function() return day end)
            summon(xi.magic.spell.KUKKI_CHEBUKKI)
            fight(20)

            day = xi.element.ICE
            fight(10) -- a cast already under way, or one more from the old gambits (they are swapped after that tick's gambits), may still be fire
            used.spell = {}
            fight(40)

            assert(usedAny(used.spell, { xi.magic.spell.BLIZZARD, xi.magic.spell.BLIZZARD_II, xi.magic.spell.BLIZZARD_III, xi.magic.spell.BLIZZARD_IV, xi.magic.spell.BLIZZARD_V, xi.magic.spell.FROST }), 'no ice spell after the day changed. ' .. dump())
            assert(not usedAny(used.spell, fireSpells), 'still casting fire after the day changed. ' .. dump())
        end)

        it('can be released mid-fight without crashing the server (his day listener must not outlive him)', function()
            local day = xi.element.FIRE
            stub('VanadielDayElement', function() return day end) -- one stub, see the test above
            summon(xi.magic.spell.KUKKI_CHEBUKKI)
            fight(10)

            player.actions:trigger(trust)
            xi.test.world:skipTime(3)

            day = xi.element.ICE
            for _ = 1, 10 do
                xi.test.world:tickEntity(player)
                xi.test.world:skipTime(2)
            end

            for _, member in ipairs(player:getPartyWithTrusts()) do
                assert(not member:isTrust(), 'Kukki-Chebukki was not released')
            end
        end)

        it('does nothing on Lightsday', function()
            stub('VanadielDayElement', xi.element.LIGHT)
            summon(xi.magic.spell.KUKKI_CHEBUKKI)
            fight(40)

            assert(next(used.spell) == nil, 'cast something on Lightsday. ' .. dump())
        end)
    end)
end)
