-----------------------------------
-- Trusts that retail hands out for a quest or mission LSB already has, but whose scripts never teach the trust.
-- Not a module (only loaded by require): trust_quest_grants_login.lua calls grant() at every login and zone change,
-- so a player learns the trust the next time they zone after finishing the quest, and players who finished it
-- before this existed get it too. Like retail, every one needs a Trust permit (any nation's Trust quest).
-- Retail sources (BG Wiki): docs/custom/NOTES.md, "Trust acquisition".
-----------------------------------
local M = {}

-- The Light Within is the last SoA mission in LSB and is never completed: after its reward (the ring choice from
-- Ploh Trishbahk) it stays the current mission with its Status reset to 0. Status is 1 from the moment it starts,
-- so current + Status 0 means finished. hasCompletedMission covers a later LSB that adds the missions after it.
M.finishedTheLightWithin = function(player)
    local log = xi.mission.log_id.SOA
    local id  = xi.mission.id.soa.THE_LIGHT_WITHIN

    return player:hasCompletedMission(log, id) or
        (player:getCurrentMission(log) == id and xi.mission.getVar(player, log, id, 'Status') == 0)
end

M.rules =
{
    { spell = xi.magic.spell.GESSHO,       name = 'Gessho',          done = function(player) return player:hasCompletedMission(xi.mission.log_id.TOAU, xi.mission.id.toau.PASSING_GLORY) end },
    { spell = xi.magic.spell.GADALAR,      name = 'Gadalar',         done = function(player) return player:hasCompletedQuest(xi.questLog.AHT_URHGAN, xi.quest.id.ahtUrhgan.EMBERS_OF_HIS_PAST) end },
    { spell = xi.magic.spell.ZAZARG,       name = 'Zazarg',          done = function(player) return player:hasCompletedQuest(xi.questLog.AHT_URHGAN, xi.quest.id.ahtUrhgan.FIST_OF_THE_PEOPLE) end },
    { spell = xi.magic.spell.KLARA,        name = 'Klara',           done = function(player) return player:hasCompletedQuest(xi.questLog.CRYSTAL_WAR, xi.quest.id.crystalWar.BONDS_OF_MYTHRIL) end },
    { spell = xi.magic.spell.EXCENMILLE_S, name = 'Excenmille (S)',  done = function(player) return player:hasCompletedQuest(xi.questLog.CRYSTAL_WAR, xi.quest.id.crystalWar.FACE_OF_THE_FUTURE) end },
    { spell = xi.magic.spell.ARCIELA,      name = 'Arciela',         done = function(player) return M.finishedTheLightWithin(player) end },

    -- Retail gives these two at login to everyone who has finished a Trust quest
    { spell = xi.magic.spell.CORNELIA,     name = 'Cornelia',        done = function(player) return true end },
    { spell = xi.magic.spell.MATSUI_P,     name = 'Matsui-P',        done = function(player) return true end },
}

-- Teaches every trust the player has earned but not learned yet. Returns the spell ids it taught.
M.grant = function(player)
    local taught = {}

    if xi.settings.main.ENABLE_TRUST_QUESTS ~= 1 or not xi.trust.hasPermit(player) then
        return taught
    end

    for _, rule in ipairs(M.rules) do
        if not player:hasSpell(rule.spell) and rule.done(player) then
            player:addSpell(rule.spell, { silentLog = true })
            player:printToPlayer(string.format('You learned Trust: %s!', rule.name), xi.msg.channel.SYSTEM_3)
            table.insert(taught, rule.spell)
        end
    end

    return taught
end

return M
