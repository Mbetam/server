-----------------------------------
-- GEO Collimated Fervor and RUN Odyllic Subterfuge (scripts added 2026-09-23), and the Leveling Guide NPC in Norg
-- (modules/custom/lua/leveling_guide_npc.lua). The Guide's six teleports are checked in game.
-----------------------------------

describe('GEO/RUN abilities and the Leveling Guide', function()
    it('Collimated Fervor gives its 60 second effect', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.GEO, level = 99 })

        player.actions:useAbility(player, xi.jobAbility.COLLIMATED_FERVOR)
        xi.test.world:skipTime(2)

        local effect = player:getStatusEffect(xi.effect.COLLIMATED_FERVOR)
        assert(effect ~= nil, 'no Collimated Fervor effect')
        assert(effect:getDuration() == 60000, 'expected 60 s, got ' .. effect:getDuration() .. ' ms')
    end)

    it('Odyllic Subterfuge\'s script lowers the target\'s magic accuracy by 40 for 30 s', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RUN, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()

        local maccBefore = mob:getMod(xi.mod.MACC)
        local ability    = { setMsg = function() end }

        xi.actions.abilities.odyllic_subterfuge.onUseAbility(player, mob, ability, nil)

        local effect = mob:getStatusEffect(xi.effect.ODYLLIC_SUBTERFUGE)
        assert(effect ~= nil, 'the target has no Odyllic Subterfuge effect')
        assert(effect:getDuration() == 30000, 'expected 30 s, got ' .. effect:getDuration() .. ' ms')
        assert(mob:getMod(xi.mod.MACC) == maccBefore - 40, 'Magic Accuracy should drop by 40, got ' .. (mob:getMod(xi.mod.MACC) - maccBefore))
    end)

    it('the Leveling Guide stands in Norg', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.NORG, job = xi.job.WAR, level = 99 })

        assert(player.entities:get('DE_Leveling_Guide') ~= nil, 'the Leveling Guide should be in Norg')
    end)
end)
