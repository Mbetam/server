-----------------------------------
-- !gotoexp (modules/custom/lua/gotoexp_core.lua, gotoexp_data.lua)
-----------------------------------

describe('!gotoexp', function()
    local core = require('modules/custom/lua/gotoexp_core')
    local data = require('modules/custom/lua/gotoexp_data')
    local menus

    local function settle()
        for _ = 1, 8 do
            xi.test.world:skipTime(1)
        end
    end

    -- Picks the option whose label starts with `prefix` (or the first one)
    local function pick(player, prefix)
        local menu = table.remove(menus, 1)
        assert(menu, 'no menu was sent')

        for _, option in ipairs(menu.options) do
            if prefix == nil or option[1]:sub(1, #prefix) == prefix then
                option[2](player)
                return menu
            end
        end

        error('no option starting with ' .. tostring(prefix))
    end

    before_each(function()
        menus = {}
        core.setMenuSender(function(player, menu)
            table.insert(menus, menu)
        end)
    end)

    after_each(function()
        core.setMenuSender(nil)
    end)

    it('is a command every player can use', function()
        assert(xi.commands['gotoexp'] ~= nil, '!gotoexp is not registered')
        assert(xi.commands['gotoexp'].cmdprops.permission == 0, '!gotoexp should be available to every player')
    end)

    it('offers camps whose monsters fit the level, each with a landing spot', function()
        for _, level in ipairs({ 5, 12, 20, 30, 45, 60, 75, 85, 99 }) do
            local camps = core.camps(level)
            assert(#camps >= 1, 'no camp for level ' .. level)

            for _, camp in ipairs(camps) do
                assert(camp.landing and #camp.landing >= 4, camp.name .. ' has no landing spot')
                assert(data.zones[camp.zone] ~= nil, camp.name .. ' is not in the data')
                assert(camp.high >= level - 3 and camp.low <= level + 12, string.format('%s (%d-%d) does not fit level %d', camp.name, camp.low, camp.high, level))
            end
        end
    end)

    it('fits every menu into the 150-byte packet, for every level', function()
        for level = 1, 99 do
            local camps  = core.camps(level)
            local title  = string.format('EXP camps, Lv.%d', level)
            local labels = core.labels(title, camps)
            local size   = #title + 2

            for _, label in ipairs(labels) do
                size = size + #label + 3
            end

            assert(size <= core.menuLimit, string.format('level %d menu is %d bytes', level, size))
        end
    end)

    it('teleports a solo player to the chosen camp', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 30 })
        local camps  = core.camps(30)

        xi.commands['gotoexp'].onTrigger(player)
        pick(player)
        settle()

        assert(player:getZoneID() == camps[1].zone, string.format('expected zone %d, in %d', camps[1].zone, player:getZoneID()))
    end)

    it('lets the party leader bring the party (members in the zone), and only the leader gets that choice', function()
        local leader = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 40 })
        local member = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 35 })

        leader.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        -- The party's lowest level picks the camps
        assert(core.level(leader) == 35, 'party level ' .. core.level(leader))

        -- Not the leader: no party choice, straight to the camp
        xi.commands['gotoexp'].onTrigger(member)
        local first = menus[1]
        first.options[1][2](member)
        assert(#menus == 1, 'a party member who is not the leader got a party choice')
        table.remove(menus, 1)
        settle()

        -- Bring them back next to the leader, then the leader brings the party
        member:setPos(leader:getXPos(), leader:getYPos(), leader:getZPos(), 0, xi.zone.WEST_RONFAURE)
        settle()
        assert(member:getZoneID() == xi.zone.WEST_RONFAURE, 'precondition: the member is back in West Ronfaure')

        local camps = core.camps(core.level(leader))
        xi.commands['gotoexp'].onTrigger(leader)
        pick(leader)
        pick(leader, 'Bring party')
        settle()

        assert(leader:getZoneID() == camps[1].zone, 'the leader did not arrive')
        assert(member:getZoneID() == camps[1].zone, 'the party member was not brought along')
    end)

    it('is refused in battle', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 30 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        player.actions:engage(mob)
        xi.test.world:skipTime(2)

        xi.commands['gotoexp'].onTrigger(player)
        assert(#menus == 0, 'a menu was offered while engaged')
    end)
end)
