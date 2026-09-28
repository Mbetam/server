-----------------------------------
-- Daily hunts (modules/custom/lua/hunt_*.lua): 4 kill hunts and 1 NM hunt a day, EXP / gil / Hunt Marks, a trophy
-- from the NM hunt, party credit, rerolls, a new set after JST midnight.
-----------------------------------

describe('Daily hunts', function()
    local core   = require('modules/custom/lua/hunt_core')
    local config = require('modules/custom/lua/hunt_config')
    local data   = require('modules/custom/lua/hunt_data')

    local RABBITS = xi.zone.WEST_RONFAURE * 1000 + 50 -- Rabbit family in West Ronfaure
    local JACK    = 17187111                         -- Jaggedy-Eared Jack (West Ronfaure)

    local function spawn(level)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = level or 10 })
        core.assign(player)

        return player
    end

    -- Sets hunt n to a known target
    local function setHunt(player, n, kind, key, need)
        player:setCharVar(string.format('HUNT_%d_KIND', n), kind)
        player:setCharVar(string.format('HUNT_%d_KEY', n), key)
        player:setCharVar(string.format('HUNT_%d_NEED', n), need)
        player:setCharVar(string.format('HUNT_%d_HAVE', n), 0)
        player:setCharVar(string.format('HUNT_%d_PAID', n), 0)
    end

    local function kill(player, name)
        local mob = player.entities:moveTo(name)
        mob:respawn()
        mob:setUnkillable(false) -- other tests leave the shared Wild_Rabbit unkillable
        mob:updateClaim(player)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), name .. ' did not die')
    end

    local function hunt(player, n)
        for _, entry in ipairs(core.list(player)) do
            if entry.n == n then
                return entry
            end
        end
    end

    it('every level from 1 to 99 gets 4 kill hunts and 1 NM hunt, all with known targets', function()
        local player = spawn(1)

        for level = 1, 99 do
            player:setLevel(level)
            core.assign(player)

            local kills, nms = 0, 0

            for _, entry in ipairs(core.list(player)) do
                assert(entry.target ~= nil, 'level ' .. level .. ': hunt ' .. entry.n .. ' has no target')
                assert(entry.need >= 1, 'level ' .. level .. ': hunt needs nothing')

                if entry.kind == core.KIND_KILL then
                    kills = kills + 1
                else
                    nms = nms + 1
                end
            end

            assert(kills == config.killHunts and nms == config.nmHunts, string.format('level %d: %d kill and %d NM hunts', level, kills, nms))
        end

        assert(#data.kills > 1000, 'too few kill targets generated')
    end)

    it('keeps the same hunts all day and makes new ones after JST midnight', function()
        local player = spawn()
        local before = core.list(player)[1].key

        core.refresh(player)
        assert(core.list(player)[1].key == before, 'the hunts changed within the day')

        player:setCharVar('HUNT_DAY', 1) -- as if made on an earlier day
        assert(core.refresh(player), 'no new hunts on a new day')
        assert(player:getCharVar('HUNT_DAY') == JstMidnight(), 'the day was not recorded')
    end)

    it('a kill hunt counts the family in its zone and pays EXP, gil and 15 Hunt Marks when done', function()
        local player = spawn()
        setHunt(player, 1, core.KIND_KILL, RABBITS, 2)
        local gil = player:getGil()

        kill(player, 'Wild_Rabbit')
        assert(hunt(player, 1).have == 1, 'the first rabbit did not count')
        assert(core.getMarks(player) == 0, 'paid before the hunt was done')

        kill(player, 'Wild_Rabbit')
        assert(hunt(player, 1).paid, 'the hunt is not marked done after 2 rabbits')
        assert(core.getMarks(player) == config.rewards.kill.marks, 'expected 15 marks, have ' .. core.getMarks(player))
        assert(player:getGil() >= gil + 10 * config.rewards.kill.gilPerLevel, 'no hunt gil')

        kill(player, 'Wild_Rabbit')
        assert(core.getMarks(player) == config.rewards.kill.marks, 'a done hunt paid twice')
    end)

    it('party members in the zone get the kill too', function()
        local leader = spawn()
        local member = spawn()
        setHunt(leader, 1, core.KIND_KILL, RABBITS, 5)
        setHunt(member, 1, core.KIND_KILL, RABBITS, 5)

        leader.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        kill(leader, 'Wild_Rabbit')
        assert(hunt(member, 1).have == 1, 'the party member got no credit')
    end)

    it('the NM hunt pays 40 marks and a Legion trophy, and the last hunt of the day adds the bonus', function()
        local player = spawn()

        for n = 1, core.huntCount() do
            player:setCharVar(string.format('HUNT_%d_PAID', n), 1)
        end

        setHunt(player, 5, core.KIND_NM, JACK, 1)
        kill(player, 'Jaggedy-Eared_Jack')

        assert(core.getMarks(player) == config.rewards.nm.marks + config.rewards.allDoneMarks, 'expected 40 + 20 marks, have ' .. core.getMarks(player))

        local trophies = 0
        for _, itemId in ipairs(config.trophies) do
            trophies = trophies + player:getItemCount(itemId)
        end

        assert(trophies == 1, 'expected one Legion trophy, got ' .. trophies)
    end)

    it('one reroll a day swaps an unfinished hunt for another of the same kind', function()
        local player = spawn()
        local before = hunt(player, 5)

        assert(core.reroll(player, 5), 'the reroll failed')
        local after = hunt(player, 5)
        assert(after.kind == before.kind and after.key ~= before.key, 'the NM hunt was not swapped for another NM hunt')

        local ok = core.reroll(player, 1)
        assert(not ok, 'a second reroll was allowed')

        core.show(player) -- what the Hunt Board and !hunt print; must not error
    end)
end)
