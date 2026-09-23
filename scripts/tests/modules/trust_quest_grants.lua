-----------------------------------
-- Trusts taught for quests/missions whose scripts never teach them (modules/custom/lua/trust_quest_grants.lua):
-- granted at login/zone change, only with a Trust permit, only after the quest or mission is done.
-----------------------------------

describe('Trust quest grants', function()
    ---@type CClientEntityPair
    local player
    local trustGrants = require('modules/custom/lua/trust_quest_grants')

    local questTrusts =
    {
        xi.magic.spell.GESSHO, xi.magic.spell.GADALAR, xi.magic.spell.ZAZARG, xi.magic.spell.KLARA,
        xi.magic.spell.EXCENMILLE_S, xi.magic.spell.ARCIELA,
    }

    local function completeAll()
        -- As the mission flow does it: a mission can only be completed while it is the current one
        player:addMission(xi.mission.log_id.TOAU, xi.mission.id.toau.PASSING_GLORY)
        player:completeMission(xi.mission.log_id.TOAU, xi.mission.id.toau.PASSING_GLORY)
        player:completeQuest(xi.questLog.AHT_URHGAN, xi.quest.id.ahtUrhgan.EMBERS_OF_HIS_PAST)
        player:completeQuest(xi.questLog.AHT_URHGAN, xi.quest.id.ahtUrhgan.FIST_OF_THE_PEOPLE)
        player:completeQuest(xi.questLog.CRYSTAL_WAR, xi.quest.id.crystalWar.BONDS_OF_MYTHRIL)
        player:completeQuest(xi.questLog.CRYSTAL_WAR, xi.quest.id.crystalWar.FACE_OF_THE_FUTURE)
        -- The Light Within is never completed: after its reward it stays current with Status 0 (see the module)
        player:addMission(xi.mission.log_id.SOA, xi.mission.id.soa.THE_LIGHT_WITHIN)
        xi.mission.setVar(player, xi.mission.log_id.SOA, xi.mission.id.soa.THE_LIGHT_WITHIN, 'Status', 0)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })

        for _, rule in ipairs(trustGrants.rules) do
            player:delSpell(rule.spell)
        end

        player:delKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)
        player:delKeyItem(xi.keyItem.BASTOK_TRUST_PERMIT)
        player:delKeyItem(xi.keyItem.WINDURST_TRUST_PERMIT)
    end)

    it('teaches nothing without a Trust permit, even with every quest done', function()
        completeAll()

        assert(#trustGrants.grant(player) == 0, 'taught trusts to a player with no Trust permit')
    end)

    it('with a permit but no quests done, teaches only Cornelia and Matsui-P', function()
        player:addKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)

        trustGrants.grant(player)

        assert(player:hasSpell(xi.magic.spell.CORNELIA), 'no Cornelia')
        assert(player:hasSpell(xi.magic.spell.MATSUI_P), 'no Matsui-P')

        for _, spellId in ipairs(questTrusts) do
            assert(not player:hasSpell(spellId), 'trust ' .. spellId .. ' taught before its quest was done')
        end
    end)

    it('teaches each quest trust once its quest or mission is done, at the next zone change', function()
        player:addKeyItem(xi.keyItem.BASTOK_TRUST_PERMIT)
        completeAll()

        -- The module runs on login and zone change, with a short delay
        xi.player.onGameIn(player, false, true)
        xi.test.world:skipTime(5)

        for _, spellId in ipairs(questTrusts) do
            assert(player:hasSpell(spellId), 'trust ' .. spellId .. ' was not taught')
        end
    end)

    it('does not teach Arciela while The Light Within is still in progress', function()
        player:addKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)
        player:addMission(xi.mission.log_id.SOA, xi.mission.id.soa.THE_LIGHT_WITHIN)
        xi.mission.setVar(player, xi.mission.log_id.SOA, xi.mission.id.soa.THE_LIGHT_WITHIN, 'Status', 3)

        trustGrants.grant(player)

        assert(not player:hasSpell(xi.magic.spell.ARCIELA), 'Arciela taught before the mission was finished')
    end)

    it('teaches nothing twice', function()
        player:addKeyItem(xi.keyItem.WINDURST_TRUST_PERMIT)
        completeAll()

        assert(#trustGrants.grant(player) == #trustGrants.rules, 'the first grant should teach every trust')
        assert(#trustGrants.grant(player) == 0, 'the second grant taught something again')
    end)
end)
