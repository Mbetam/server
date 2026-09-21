-----------------------------------
-- The !buff command (modules/custom/commands/buff.lua): EXP +200%, Regen +50, Refresh +50, Regain +50
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

    it('gives an EXP bonus of +200%', function()
        local mob = player.entities:get('Volcanic_Bomb')
        local baseExp = 100

        assert(killExp(mob, baseExp) == baseExp, 'precondition: a kill without the buff should pay the base EXP')

        xi.commands.buff.onTrigger(player)

        assert(killExp(mob, baseExp) == baseExp * 3, 'a +200% bonus should pay three times the base EXP')
    end)

    it('lasts an hour', function()
        xi.commands.buff.onTrigger(player)

        for _, effectId in ipairs({ xi.effect.DEDICATION, xi.effect.REGEN, xi.effect.REFRESH, xi.effect.REGAIN }) do
            local effect = player:getStatusEffect(effectId)

            assert(effect ~= nil, 'the buff is missing an effect')

            -- getDuration() is in milliseconds
            assert(effect:getDuration() == 3600 * 1000,
                string.format('every effect in the buff should last 3600 seconds (effect %d lasts %d ms)', effectId, effect:getDuration()))
        end
    end)

    it('does not stack when used again', function()
        local regenBefore  = player:getMod(xi.mod.REGEN)
        local regainBefore = player:getMod(xi.mod.REGAIN)

        xi.commands.buff.onTrigger(player)
        xi.commands.buff.onTrigger(player)

        assert(player:getMod(xi.mod.REGEN) == regenBefore + 50, 'using the command twice stacked Regen')
        assert(player:getMod(xi.mod.REGAIN) == regainBefore + 50, 'using the command twice stacked Regain')
        assert(player:getStatusEffect(xi.effect.DEDICATION):getPower() == 200, 'using the command twice changed the EXP bonus')
    end)

    it('does nothing for a KO\'d player', function()
        player:die({ expLoss = false })
        xi.test.world:tickEntity(player)
        assert(player:isDead(), 'precondition: the player should be dead')

        xi.commands.buff.onTrigger(player)

        assert(player:getStatusEffect(xi.effect.DEDICATION) == nil, 'a KO\'d player received the EXP buff')
    end)
end)
