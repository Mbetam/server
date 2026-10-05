-----------------------------------
-- Trust-unique moves written with estimated numbers (2026-10-04): each trust, given TP, uses its moves; damaging ones
-- deal damage; the conditional heals (Rise From Ashes, Illustrious Aid, Naakual's Vengeance) fire and heal.
-----------------------------------

describe('Trust-unique moves', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local trust
    local used

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

        used = { skill = {}, damage = {} }
        trust:addListener('WEAPONSKILL_USE', 'TEST_UNIQUE_WS', function(entity, target, skill, tp, action, damage)
            local id = type(skill) == 'number' and skill or skill:getID()
            used.skill[id] = (used.skill[id] or 0) + 1
            used.damage[id] = math.max(used.damage[id] or 0, damage or 0)
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

    local function dump()
        local parts = {}

        for id, n in pairs(used.skill) do
            table.insert(parts, string.format('%d x%d (dmg %d)', id, n, used.damage[id] or 0))
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
        mob:setMaxHP(1000000)
        mob:setHP(1000000)
    end)

    -- trust, its new moves, the damaging ones among them
    local cases =
    {
        { 'IROHA', { 3556, 3558, 3559, 3560 }, { 3556, 3558, 3559, 3560 } },
        { 'IROHA_II', { 3733, 3734, 3736, 3737 }, { 3733, 3734, 3736, 3737 } },
        { 'TEODOR', { 3632, 3633, 3634, 3635, 3636 }, { 3632, 3633, 3634, 3635, 3636 } },
        { 'BALAMOR', { 3617, 3618, 3619, 3620 }, { 3617, 3618, 3619, 3620 } },
        { 'ROSULATIA', { 3662, 3663, 3666 }, { 3662, 3663, 3666 } },
        { 'YGNAS', { 3815, 2979 }, { 3815, 2979 } },
        { 'ARCIELA', { 3453, 3451 }, {} },
        { 'ARCIELA_II', { 3699, 3700, 3701, 3702, 3703, 3704 }, { 3699, 3700, 3701, 3702 } },
        { 'INGRID_II', { 3644, 3645, 3647, 164 }, { 3644, 3645, 3647 } },
        { 'LUZAF', { 3252, 3253, 3254, 3255 }, { 3252, 3254, 3255 } },
    }

    for _, case in ipairs(cases) do
        local key, moves, damaging = case[1], case[2], case[3]

        it(key .. ' uses its trust-unique moves' .. (#damaging > 0 and ', and they deal damage' or ''), function()
            summon(xi.magic.spell[key])

            for _ = 1, 8 do
                trust:setTP(3000)
                fight(6)
            end

            local usedAny, hit = false, false
            for _, id in ipairs(moves) do
                usedAny = usedAny or used.skill[id] ~= nil
            end

            for _, id in ipairs(damaging) do
                hit = hit or (used.damage[id] or 0) > 0
            end

            assert(usedAny, 'none of its moves. ' .. dump())
            assert(#damaging == 0 or hit, 'none of its damaging moves did damage. ' .. dump())
        end)
    end

    -- Moves added to trusts that already had other weapon skills: forced, since they pick at random
    it('the single new moves of the other trusts land and deal damage', function()
        local singles =
        {
            { 'ZAZARG', 3240 }, { 'NAJELITH', 3239 }, { 'KLARA', 3296 }, { 'ROMAA_MIHGO', 3297 }, { 'MAYAKOV', 3454 },
            { 'NAJA_UC', 3503 }, { 'GADALAR', 2089 }, { 'ROBEL_AKBEL', 3538 }, { 'DOMINA_SHANTOTTO', 3264 }, { 'OVJANG', 3244 },
        }

        for _, entry in ipairs(singles) do
            summon(xi.magic.spell[entry[1]])
            fight(4)

            -- A physical move can simply miss: up to five tries. A mob skill can't start mid-cast: wait until free.
            for _ = 1, 5 do
                if (used.damage[entry[2]] or 0) > 0 then
                    break
                end

                for _ = 1, 25 do
                    local action = trust:getCurrentAction()
                    if action ~= 30 and action ~= 3 and action ~= 34 and action ~= 6 then
                        break -- free: not casting, weapon skilling, using a mob skill or an ability
                    end

                    xi.test.world:skipTime(1)
                end

                trust:setTP(1000)
                trust:useMobAbility(entry[2], mob)
                fight(6)
            end

            assert((used.damage[entry[2]] or 0) > 0, entry[1] .. ' ' .. entry[2] .. ' did no damage. ' .. dump())
            player:clearTrusts()
            xi.test.world:skipTime(4)
        end
    end)

    it('Iroha II uses Rise From Ashes when three party members are hurt', function()
        player:spawnTrust(xi.magic.spell.KUPIPI)
        player:spawnTrust(xi.magic.spell.TRION)
        summon(xi.magic.spell.IROHA_II)
        fight(4)

        for _, member in ipairs(player:getPartyWithTrusts()) do
            member:setHP(math.floor(member:getMaxHP() * 0.5))
        end

        fight(8)
        assert(used.skill[3738], 'no Rise From Ashes. ' .. dump())
        assert(player:hasStatusEffect(xi.effect.STONESKIN), 'the master got no Stoneskin')
    end)

    it('Arciela uses Illustrious Aid when two party members are hurt', function()
        player:spawnTrust(xi.magic.spell.KUPIPI)
        summon(xi.magic.spell.ARCIELA)
        fight(4)

        local before = player:getHP()
        player:setHP(math.floor(player:getMaxHP() * 0.5))
        trust:setHP(math.floor(trust:getMaxHP() * 0.5))
        before = player:getHP()

        fight(20) -- the move waits for her current cast to end
        assert(used.skill[3452], 'no Illustrious Aid. ' .. dump())
        assert(player:getHP() > before, 'the master was not healed')
    end)

    it("Arciela II uses Naakual's Vengeance at low HP", function()
        summon(xi.magic.spell.ARCIELA_II)
        fight(4)
        trust:setHP(math.floor(trust:getMaxHP() * 0.2))
        fight(20) -- the move waits for her current cast to end

        assert(used.skill[3705], "no Naakual's Vengeance. " .. dump())
        assert(trust:getHPP() > 90, "Naakual's Vengeance did not restore her HP: " .. trust:getHPP() .. '%')
    end)
end)
