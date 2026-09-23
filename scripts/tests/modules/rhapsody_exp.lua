-----------------------------------
-- Rhapsodies of Vana'diel key items and EXP (scripts/globals/experience_points.lua, handleRoVBonus).
-- Retail (BG Wiki): White, Umber, Azure, Crimson, Emerald and Mauve each give +30% EXP (up to +180%);
-- Fuchsia, Puce and Ochre give capacity points instead (handled in C++, charutils.cpp), not EXP.
-- Calls xi.experiencePoints.calculate, the function the engine itself calls for every kill (luautils.cpp),
-- with a real player and a real monster, so the real key item checks run.
-----------------------------------

describe('Rhapsody key items and EXP', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    local expRhapsodies =
    {
        xi.keyItem.RHAPSODY_IN_WHITE,
        xi.keyItem.RHAPSODY_IN_UMBER,
        xi.keyItem.RHAPSODY_IN_AZURE,
        xi.keyItem.RHAPSODY_IN_CRIMSON,
        xi.keyItem.RHAPSODY_IN_EMERALD,
        xi.keyItem.RHAPSODY_IN_MAUVE,
    }

    local capacityRhapsodies =
    {
        xi.keyItem.RHAPSODY_IN_FUCHSIA,
        xi.keyItem.RHAPSODY_IN_PUCE,
        xi.keyItem.RHAPSODY_IN_OCHRE,
    }

    -- The EXP a solo kill of an even-match monster would give (before the server's EXP_RATE, which C++ applies after).
    local function killExp()
        local data =
        {
            baseExp            = 200,
            memberLevel        = 30,
            highestMemberLevel = 30,
            memberTNL          = 1000,
            highestMemberTNL   = 1000,
            partySize          = 1,
            regionId           = player:getCurrentRegion(),
            mobDifficulty      = xi.mobDifficulty.EVEN_MATCH,
            chainActive        = false,
            chainNumber        = 0,
        }

        return xi.experiencePoints.calculate(player, mob, data).exp
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 30 })
        mob    = player.entities:moveTo('Wild_Rabbit')

        for _, ki in ipairs(expRhapsodies) do
            player:delKeyItem(ki)
        end

        for _, ki in ipairs(capacityRhapsodies) do
            player:delKeyItem(ki)
        end
    end)

    it('gives +30% EXP for one EXP Rhapsody', function()
        local base = killExp()
        assert(base > 0, 'precondition: the kill should give EXP')

        player:addKeyItem(xi.keyItem.RHAPSODY_IN_WHITE)

        local expected = base + math.floor(base * 30 / 100)
        assert(killExp() == expected, string.format('with Rhapsody in White: expected %d, got %d (base %d)', expected, killExp(), base))
    end)

    it('gives +30% for EACH of the six EXP Rhapsodies, +180% with all of them', function()
        local base = killExp()

        for count, ki in ipairs(expRhapsodies) do
            player:addKeyItem(ki)

            local expected = base + math.floor(base * 30 * count / 100)
            assert(killExp() == expected, string.format('with %d Rhapsodies: expected %d, got %d (base %d)', count, expected, killExp(), base))
        end
    end)

    it('does not add EXP for the capacity point Rhapsodies (Fuchsia, Puce, Ochre)', function()
        local base = killExp()

        for _, ki in ipairs(capacityRhapsodies) do
            player:addKeyItem(ki)
        end

        assert(killExp() == base, string.format('capacity Rhapsodies changed EXP: %d -> %d', base, killExp()))
    end)
end)
