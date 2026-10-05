-----------------------------------
-- Trusts that were partially working (2026-10-04): Adelheid (storm / helix by the enemy's weakness, helix bursts),
-- Volker (Warrior's Charge), Semih Lafihna (Stealth Shot), Rainemard (en-spell by weakness), Nashmeira II (Curaga only
-- for 3+ hurt), and the Unity rank bonuses at their maximum.
-----------------------------------

describe('Formerly partial trusts', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local used

    local function trustOf(spellId)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                return member
            end
        end
    end

    local function summon(spellId)
        player:spawnTrust(spellId)
        xi.test.world:skipTime(2)

        local trust = trustOf(spellId)
        assert(trust, 'the trust was not summoned')

        trust:addListener('MAGIC_USE', 'TEST_PARTIAL_MAGIC', function(entity, target, spell)
            used.spell[spell:getID()] = (used.spell[spell:getID()] or 0) + 1
        end)
        trust:addListener('ABILITY_USE', 'TEST_PARTIAL_ABILITY', function(entity, target, ability)
            used.ability[ability:getID()] = (used.ability[ability:getID()] or 0) + 1
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_PARTIAL_WS', function(entity, target, skill)
            local id = type(skill) == 'number' and skill or skill:getID()
            used.skill[id] = (used.skill[id] or 0) + 1
        end)

        return trust
    end

    local function fight(seconds, keepHate)
        player.actions:engage(mob)

        for _ = 1, seconds / 2 do
            if keepHate ~= false then
                mob:addEnmity(player, 30000, 30000)
            end

            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end
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

    -- The element the engine treats as the target's weakness: the lowest resistance rank (first one on a tie)
    local function weakestElement(target)
        local best, element = nil, nil

        for el = xi.element.FIRE, xi.element.DARK do
            local rank = target:getMod(xi.data.element.dataTable[el][6])

            if best == nil or rank < best then
                best, element = rank, el
            end
        end

        return element
    end

    -- Spells cast of a given family (spell_list family ids)
    local function castOfFamily(family)
        for id in pairs(used.spell) do
            if GetSpell(id):getSpellFamily() == family then
                return id
            end
        end
    end

    before_each(function()
        used = { spell = {}, ability = {}, skill = {} }
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    it("Adelheid's storm and helix match the enemy's weakness (not a storm on the enemy)", function()
        summon(xi.magic.spell.ADELHEID)
        fight(40)

        local weak   = weakestElement(mob)
        local storms = { xi.magic.spellFamily.FIRESTORM, xi.magic.spellFamily.HAILSTORM, xi.magic.spellFamily.WINDSTORM,
            xi.magic.spellFamily.SANDSTORM, xi.magic.spellFamily.THUNDERSTORM, xi.magic.spellFamily.RAINSTORM,
            xi.magic.spellFamily.AURORASTORM, xi.magic.spellFamily.VOIDSTORM }
        local storm  = castOfFamily(storms[weak])
        assert(storm, 'no storm of the weak element ' .. weak .. '. ' .. dump())

        local helix = nil
        for id in pairs(used.spell) do
            local name = GetSpell(id) and xi.magic.spell[id]
            if id >= xi.magic.spell.GEOHELIX and id <= xi.magic.spell.LUMINOHELIX then
                helix = id
            end
        end

        assert(helix, 'no helix. ' .. dump())
        assert(GetSpell(helix):getElement() == weak, 'helix element ' .. GetSpell(helix):getElement() .. ', weakness ' .. weak)
    end)

    it('Adelheid magic bursts with the matching helix', function()
        local adelheid = summon(xi.magic.spell.ADELHEID)
        fight(20)

        adelheid:setMP(adelheid:getMaxMP())
        mob:setMobAbilityEnabled(false)
        for _ = 1, 10 do
            if adelheid:getCurrentAction() ~= 30 then
                break
            end

            xi.test.world:skipTime(1)
        end

        used.spell = {}
        mob:delStatusEffect(xi.effect.SKILLCHAIN)
        mob:delStatusEffect(xi.effect.HELIX)
        mob:addStatusEffect(xi.effect.SKILLCHAIN, { power = xi.skillchainType.INDURATION, duration = 15, tier = 2, origin = player })
        fight(14)

        assert(used.spell[xi.magic.spell.CRYOHELIX], 'no Cryohelix burst on Induration. ' .. dump())
    end)

    it("Volker uses Warrior's Charge and weapon skills at 2000 TP", function()
        local volker = summon(xi.magic.spell.VOLKER)
        -- Under 2000 TP first, as in play where TP climbs past 1500 first (weapon skills are tried before gambits)
        for _ = 1, 3 do
            volker:setTP(1600)
            fight(8)
        end

        volker:setTP(2000)
        fight(8)

        assert(used.ability[xi.jobAbility.WARRIORS_CHARGE], "no Warrior's Charge. " .. dump())
        local any = false
        for _ in pairs(used.skill) do
            any = true
        end

        assert(any, 'no weapon skill. ' .. dump())
    end)

    it('Semih Lafihna uses Stealth Shot when she has the hate', function()
        local semih = summon(xi.magic.spell.SEMIH_LAFIHNA)
        player.actions:engage(mob)
        for _ = 1, 15 do
            mob:addEnmity(semih, 30000, 30000)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end

        assert(used.ability[xi.jobAbility.STEALTH_SHOT], 'no Stealth Shot. ' .. dump())
    end)

    it("Rainemard's en-spell matches the enemy's weakness", function()
        summon(xi.magic.spell.RAINEMARD)
        fight(30)

        local enspells = { xi.magic.spell.ENFIRE, xi.magic.spell.ENBLIZZARD, xi.magic.spell.ENAERO,
            xi.magic.spell.ENSTONE, xi.magic.spell.ENTHUNDER, xi.magic.spell.ENWATER }
        local weak = weakestElement(mob)
        local cast = nil
        for _, id in ipairs(enspells) do
            if used.spell[id] then
                cast = id
            end
        end

        assert(cast, 'no en-spell. ' .. dump())
        if weak <= xi.element.WATER then
            assert(GetSpell(cast):getElement() == weak, 'en-spell element ' .. GetSpell(cast):getElement() .. ', weakness ' .. weak)
        end
    end)

    it('Nashmeira II casts Curaga only when 3 party members are hurt', function()
        player:spawnTrust(xi.magic.spell.ZAZARG) -- no healing of his own (a paladin would cure the others first)
        xi.test.world:skipTime(2)
        summon(xi.magic.spell.NASHMEIRA_II)
        fight(10)

        used.spell = {}
        player:setHP(math.floor(player:getMaxHP() * 0.6))
        fight(10)

        local function curagas()
            local n = 0
            for id, c in pairs(used.spell) do
                if id >= xi.magic.spell.CURAGA and id <= xi.magic.spell.CURAGA_V then
                    n = n + c
                end
            end

            return n
        end

        assert(curagas() == 0, 'Curaga for one hurt party member. ' .. dump())

        -- An AoE hit on a healthy party: everyone back to full first, then three drop at once
        for _, member in ipairs(player:getPartyWithTrusts()) do
            member:setHP(member:getMaxHP())
        end

        fight(6)
        trustOf(xi.magic.spell.NASHMEIRA_II):setMP(trustOf(xi.magic.spell.NASHMEIRA_II):getMaxMP()) -- she cured earlier
        used.spell = {}
        for _, member in ipairs(player:getPartyWithTrusts()) do
            member:setHP(math.floor(member:getMaxHP() * 0.6))
        end

        fight(20) -- a weapon skill (~5 s) may come first, and Curaga V takes ~5 s to cast

        local where = {}
        local nash  = trustOf(xi.magic.spell.NASHMEIRA_II)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            table.insert(where, string.format('%s %d%% at %.1f MP %d/%d', member:getName(), member:getHPP(), nash:checkDistance(member), member:getMP(), member:getMaxMP()))
        end

        assert(curagas() >= 1, 'no Curaga with 3 hurt. ' .. dump() .. ' | ' .. table.concat(where, ', '))
    end)

    it('Unity rank bonuses are at their maximum (Yoran-Oran MP+25%, Invincible Shield HP+30%)', function()
        local yoran = summon(xi.magic.spell.YORAN_ORAN_UC)
        assert(yoran:getMod(xi.mod.MPP) >= 25, "Yoran-Oran's MP bonus is " .. yoran:getMod(xi.mod.MPP))

        local shield = summon(xi.magic.spell.INVINCIBLE_SHIELD_UC)
        assert(shield:getMod(xi.mod.HPP) >= 30, "Invincible Shield's HP bonus is " .. shield:getMod(xi.mod.HPP))
    end)
end)
