-----------------------------------
-- The !buff command (modules/custom/commands/buff.lua): EXP +100%, Regen +50, Refresh +50, Regain +50 for ten hours
-----------------------------------

describe('!buff command', function()
    ---@type CClientEntityPair
    local player

    -- The data the C++ side hands to xi.experiencePoints.calculate for a single kill at the player's own level
    local function killExp(mob, baseExp)
        local data =
        {
            baseExp            = baseExp,
            mobDifficulty      = xi.mobDifficulty.TOO_WEAK,
            memberLevel        = 99,
            highestMemberLevel = 99,
            partySize          = 1,
            memberTNL          = 1000,
            highestMemberTNL   = 1000,
            regionId           = xi.region.RONFAURE,
            chainNumber        = 0,
            chainActive        = false,
        }

        return xi.experiencePoints.calculate(player, mob, data).exp
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.IFRITS_CAULDRON, job = xi.job.WAR, level = 99 })

        -- Do not rely on what a fresh character starts with
        for _, effectId in ipairs({ xi.effect.DEDICATION, xi.effect.REGEN, xi.effect.REFRESH, xi.effect.REGAIN }) do
            player:delStatusEffect(effectId)
        end
    end)

    it('is registered as a command any player can use', function()
        local command = xi.commands.buff

        assert(command ~= nil, 'the module did not register !buff (is custom/commands/ listed in modules/init.txt?)')
        assert(command.cmdprops.permission == 0, 'permission 0 is what makes a command available to every player')
    end)

    it('gives Regen +50, Refresh +50 and Regain +50', function()
        local regenBefore   = player:getMod(xi.mod.REGEN)
        local refreshBefore = player:getMod(xi.mod.REFRESH)
        local regainBefore  = player:getMod(xi.mod.REGAIN)

        xi.commands.buff.onTrigger(player)

        assert(player:getMod(xi.mod.REGEN) == regenBefore + 50, 'Regen should have risen by 50')
        assert(player:getMod(xi.mod.REFRESH) == refreshBefore + 50, 'Refresh should have risen by 50')
        assert(player:getMod(xi.mod.REGAIN) == regainBefore + 50, 'Regain should have risen by 50')
    end)

    it('gives an EXP bonus of +100%', function()
        local mob = player.entities:get('Volcanic_Bomb')
        local baseExp = 100

        assert(killExp(mob, baseExp) == baseExp, 'precondition: a kill without the buff should pay the base EXP')

        xi.commands.buff.onTrigger(player)

        assert(killExp(mob, baseExp) == baseExp * 2, 'a +100% bonus should pay twice the base EXP')
    end)

    it('keeps the EXP pool small enough for the database to save', function()
        -- char_effects.subpower is a signed smallint. A pool above 32767 makes every effects save fail with
        -- "Out of range value for column 'subpower'" and the whole batch is rolled back.
        xi.commands.buff.onTrigger(player)

        local pool = player:getStatusEffect(xi.effect.DEDICATION):getSubPower()

        assert(pool > 0 and pool <= 32767, 'the EXP pool is ' .. pool .. ', which char_effects.subpower cannot store')
    end)

    it('tops the EXP pool back up after every kill so it never runs dry', function()
        local mob = player.entities:get('Volcanic_Bomb')

        xi.commands.buff.onTrigger(player)
        local full = player:getStatusEffect(xi.effect.DEDICATION):getSubPower()

        for _ = 1, 5 do
            assert(killExp(mob, 1000) > 1000, 'the buff should be paying a bonus')
        end

        local effect = player:getStatusEffect(xi.effect.DEDICATION)
        assert(effect ~= nil, 'the EXP buff ended after a few kills')
        assert(effect:getSubPower() == full, 'the pool should be full again after each kill, but it is ' .. effect:getSubPower())
    end)

    it('lasts ten hours', function()
        xi.commands.buff.onTrigger(player)

        for _, effectId in ipairs({ xi.effect.DEDICATION, xi.effect.REGEN, xi.effect.REFRESH, xi.effect.REGAIN }) do
            local effect = player:getStatusEffect(effectId)

            assert(effect ~= nil, 'the buff is missing an effect')

            -- getDuration() is in milliseconds
            assert(effect:getDuration() == 10 * 3600 * 1000,
                string.format('every effect in the buff should last 10 hours (effect %d lasts %d ms)', effectId, effect:getDuration()))
        end
    end)

    it('does not stack when used again', function()
        local regenBefore  = player:getMod(xi.mod.REGEN)
        local regainBefore = player:getMod(xi.mod.REGAIN)

        xi.commands.buff.onTrigger(player)
        xi.commands.buff.onTrigger(player)

        assert(player:getMod(xi.mod.REGEN) == regenBefore + 50, 'using the command twice stacked Regen')
        assert(player:getMod(xi.mod.REGAIN) == regainBefore + 50, 'using the command twice stacked Regain')
        assert(player:getStatusEffect(xi.effect.DEDICATION):getPower() == require('modules/custom/lua/buff_config').expPercent, 'using the command twice changed the EXP bonus')
    end)

    it('does nothing for a KO\'d player', function()
        player:die({ expLoss = false })
        xi.test.world:tickEntity(player)
        assert(player:isDead(), 'precondition: the player should be dead')

        xi.commands.buff.onTrigger(player)

        assert(player:getStatusEffect(xi.effect.DEDICATION) == nil, 'a KO\'d player received the EXP buff')
    end)
end)
