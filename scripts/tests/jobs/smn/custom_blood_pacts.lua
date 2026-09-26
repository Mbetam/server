-----------------------------------
-- The 18 Blood Pacts LSB had no script for (docs/custom/NOTES.md, 2026-09-25). Each is used for real by a level 99
-- Summoner with the right avatar, against a Wild Rabbit or on the party.
-----------------------------------

describe('Custom Blood Pacts', function()
    -- A fresh SMN with the avatar out, full MP, standing next to a fresh Wild Rabbit
    local function setup(petId)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        mob:setHP(mob:getMaxHP()) -- the same rabbit is reused between tests
        mob:disengage()
        mob:updateClaim(player) -- the previous test's player may still hold the claim
        player:setPos(mob:getXPos() + 2, mob:getYPos(), mob:getZPos())
        player:capSkill(xi.skill.SUMMONING_MAGIC) -- test characters start with skill 0

        player:spawnPet(petId)
        xi.test.world:skipTime(2)
        player:setMP(player:getMaxMP())

        local pet = player:getPet()
        assert(pet, 'no avatar')
        pet:setPos(mob:getXPos() + 1, mob:getYPos(), mob:getZPos())

        return player, mob, pet
    end

    local function pact(player, target, abilityId)
        player.actions:useAbility(target, abilityId)

        for _ = 1, 8 do
            xi.test.world:skipTime(1)
        end
    end

    local rages =
    {
        { 'Lunar Bay',      xi.petId.FENRIR,   xi.jobAbility.LUNAR_BAY      },
        { 'Impact',         xi.petId.FENRIR,   xi.jobAbility.IMPACT         },
        { 'Conflag Strike', xi.petId.IFRIT,    xi.jobAbility.CONFLAG_STRIKE },
        { 'Crag Throw',     xi.petId.TITAN,    xi.jobAbility.CRAG_THROW     },
        { 'Volt Strike',    xi.petId.RAMUH,    xi.jobAbility.VOLT_STRIKE    },
        { 'Night Terror',   xi.petId.DIABOLOS, xi.jobAbility.NIGHT_TERROR   },
    }

    for _, case in ipairs(rages) do
        it(case[1] .. ' damages the target', function()
            local player, mob = setup(case[2])
            local before      = mob:getHP()

            pact(player, mob, case[3])
            assert(mob:getHP() < before, string.format('%s did no damage (%d -> %d)', case[1], before, mob:getHP()))
        end)
    end

    it('Impact also lowers the target\'s attributes', function()
        local player, mob = setup(xi.petId.FENRIR)
        pact(player, mob, xi.jobAbility.IMPACT)
        assert(mob:hasStatusEffect(xi.effect.STR_DOWN) and mob:hasStatusEffect(xi.effect.CHR_DOWN), 'no attribute down effects')
    end)

    local wards =
    {
        { 'Hastega II',       xi.petId.GARUDA, xi.jobAbility.HASTEGA_II,       xi.effect.HASTE         },
        { 'Fleet Wind',       xi.petId.GARUDA, xi.jobAbility.FLEET_WIND,       xi.effect.QUICKENING    },
        { 'Crystal Blessing', xi.petId.SHIVA,  xi.jobAbility.CRYSTAL_BLESSING, xi.effect.TP_BONUS      },
        { 'Earthen Armor',    xi.petId.TITAN,  xi.jobAbility.EARTHEN_ARMOR,    xi.effect.EARTHEN_ARMOR },
        { 'Inferno Howl',     xi.petId.IFRIT,  xi.jobAbility.INFERNO_HOWL,     xi.effect.ENFIRE        },
    }

    for _, case in ipairs(wards) do
        it(case[1] .. ' buffs the party', function()
            local player = setup(case[2])
            pact(player, player, case[3])
            assert(player:hasStatusEffect(case[4]), case[1] .. ' did not give its effect')
        end)
    end

    it('Hastega II is 30% haste and Crystal Blessing is TP Bonus +250', function()
        local player = setup(xi.petId.GARUDA)
        pact(player, player, xi.jobAbility.HASTEGA_II)
        assert(player:getStatusEffect(xi.effect.HASTE):getPower() == 2998, 'Hastega II power')

        local other = setup(xi.petId.SHIVA)
        local tp    = other:getMod(xi.mod.TP_BONUS)
        pact(other, other, xi.jobAbility.CRYSTAL_BLESSING)
        assert(other:getMod(xi.mod.TP_BONUS) == tp + 250, 'Crystal Blessing should add 250 TP Bonus')
    end)

    it('Heavenward Howl gives Endrain or Enaspir by moon phase', function()
        local player = setup(xi.petId.FENRIR)
        pact(player, player, xi.jobAbility.HEAVENWARD_HOWL)
        assert(player:hasStatusEffect(xi.effect.ENDRAIN) or player:hasStatusEffect(xi.effect.ENASPIR), 'no Endrain/Enaspir')
    end)

    it('Diamond Storm lowers evasion', function()
        local player, mob = setup(xi.petId.SHIVA)
        pact(player, mob, xi.jobAbility.DIAMOND_STORM)
        assert(mob:hasStatusEffect(xi.effect.EVASION_DOWN), 'Diamond Storm: no Evasion Down')
    end)

    it('Shock Squall stuns', function()
        local stunned = false

        for _ = 1, 5 do -- can be resisted, and a partial resist shortens the stun
            local player, mob = setup(xi.petId.RAMUH)
            player.actions:useAbility(mob, xi.jobAbility.SHOCK_SQUALL)

            for _ = 1, 8 do
                xi.test.world:skipTime(1)
                stunned = stunned or mob:hasStatusEffect(xi.effect.STUN)
            end

            if stunned then
                break
            end
        end

        assert(stunned, 'Shock Squall never stunned in 5 pacts')
    end)

    it('Ultimate Terror and Pavor Nocturnus run', function()
        local player, mob = setup(xi.petId.DIABOLOS)
        pact(player, mob, xi.jobAbility.ULTIMATE_TERROR)
        pact(player, mob, xi.jobAbility.PAVOR_NOCTURNUS)
    end)

    it('Ruinous Omen uses all MP and never KOs', function()
        local player2, mob2 = setup(xi.petId.DIABOLOS)
        player2.actions:useAbility(player2, xi.jobAbility.ASTRAL_FLOW)
        xi.test.world:skipTime(2)
        assert(player2:hasStatusEffect(xi.effect.ASTRAL_FLOW), 'Astral Flow did not start')
        player2:setMP(player2:getMaxMP())
        player2:getPet():setAutoAttackEnabled(false) -- only measure the pact, not the avatar's melee on a 33 HP rabbit
        mob2:setUnkillable(false)
        local before = mob2:getHP()
        pact(player2, mob2, xi.jobAbility.RUINOUS_OMEN)
        -- all MP is used; SMN's Auto Refresh may already have given a few back by now
        assert(player2:getMP() < 30, 'Ruinous Omen should use all MP, left ' .. player2:getMP())
        assert(mob2:getHP() > 0, 'Ruinous Omen must not KO')
        assert(mob2:getHP() >= math.floor(before * 0.75), string.format('Ruinous Omen took more than 25%%: %d -> %d', before, mob2:getHP()))
    end)

    it('Pacifying Ruby lowers enmity toward the target', function()
        local player, mob = setup(xi.petId.CARBUNCLE)
        mob:addEnmity(player, 1000, 1000)
        local ce = mob:getCE(player)
        pact(player, player, xi.jobAbility.PACIFYING_RUBY)
        assert(mob:getCE(player) < ce, string.format('CE %d -> %d, expected lower', ce, mob:getCE(player)))
    end)

    it('Endrain (Heavenward Howl) heals the attacker on melee hits', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        mob:setHP(mob:getMaxHP())
        mob:disengage()
        mob:updateClaim(player)
        player:addItem(xi.item.BRONZE_SWORD)
        player:equipItem(xi.item.BRONZE_SWORD, nil, xi.slot.MAIN)

        player:addStatusEffect(xi.effect.ENDRAIN, { power = 100, duration = 60, origin = player })
        player:setHP(100)
        player:setMod(xi.mod.REGEN, 0)
        player.actions:engage(mob)

        for _ = 1, 15 do
            xi.test.world:skipTime(1)
        end

        assert(player:getHP() > 100, 'HP did not rise from melee hits under Endrain: ' .. player:getHP())
    end)
end)
