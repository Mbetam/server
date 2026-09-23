-----------------------------------
-- The Trust Vendor (modules/custom/lua/trust_vendor_*.lua): sells the trusts players cannot get in normal play here.
-----------------------------------

describe('Trust Vendor', function()
    ---@type CClientEntityPair
    local player
    local config      = require('modules/custom/lua/trust_vendor_config')
    local flow        = require('modules/custom/lua/trust_vendor_flow')
    local trustGrants = require('modules/custom/lua/trust_quest_grants')

    -- The most recent menu the NPC sent. Real menus are not opened in tests (see flow.setMenuSender).
    local menu = nil

    local function optionLabels()
        local labels = {}

        for _, option in ipairs(menu.options) do
            table.insert(labels, option[1])
        end

        return labels
    end

    -- Clicks an option in the most recent menu, the way a player would
    local function pick(label)
        assert(menu ~= nil, 'no menu is open')

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                menu = nil
                option[2](player)

                return
            end
        end

        error('no option "' .. label .. '" in the menu; the options are: ' .. table.concat(optionLabels(), ' | '))
    end

    local function allTrusts()
        local list = {}

        for _, group in ipairs(config.groups) do
            for _, trust in ipairs(group.trusts) do
                table.insert(list, trust)
            end
        end

        return list
    end

    before_each(function()
        menu = nil
        flow.setMenuSender(function(_, sent) menu = sent end)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
        player:addKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)
        player:setGil(1000000)

        for _, trust in ipairs(allTrusts()) do
            player:delSpell(trust.spell)
        end
    end)

    after_each(function()
        flow.setMenuSender(nil)
    end)

    it('sells 69 different trusts at 100,000 gil, none of them obtainable another way here', function()
        local seen  = {}
        local count = 0

        for _, trust in ipairs(allTrusts()) do
            assert(trust.spell ~= nil, trust.name .. ': unknown spell constant')
            assert(not seen[trust.spell], trust.name .. ' is listed twice')
            seen[trust.spell] = true
            count = count + 1
        end

        assert(count == 69, 'expected 69 trusts, the list has ' .. count)
        assert(config.price == 100000, 'the price should be 100,000 gil')

        for _, rule in ipairs(trustGrants.rules) do
            assert(not seen[rule.spell], rule.name .. ' is granted by its quest; it should not be sold')
        end
    end)

    it('stands in GM Home', function()
        assert(player.entities:get('DE_Trust_Vendor') ~= nil, 'the Trust Vendor should be in GM Home')
    end)

    it('stands in Lower Jeuno, 3 yalms from the Augmenter', function()
        local jeuno     = xi.test.world:spawnPlayer({ zone = xi.zone.LOWER_JEUNO })
        local vendor    = jeuno.entities:get('DE_Trust_Vendor')
        local augmenter = jeuno.entities:get('DE_Augmenter')

        assert(vendor ~= nil, 'the Trust Vendor should be in Lower Jeuno')
        assert(augmenter ~= nil, 'the Augmenter should be in Lower Jeuno')

        local distance = vendor:checkDistance(augmenter)
        assert(distance > 2.5 and distance < 3.5, string.format('the two NPCs are %.2f yalms apart', distance))
    end)

    it('sells a trust through the menus: takes 100,000 gil and teaches it', function()
        flow.onTrigger(player)
        pick('Unity trusts (11)')
        pick('Apururu (UC)')
        pick('Yes')

        assert(player:hasSpell(xi.magic.spell.APURURU_UC), 'Apururu (UC) was not taught')
        assert(player:getGil() == 900000, 'expected 900,000 gil left, have ' .. player:getGil())
    end)

    it('no longer lists a trust the player knows', function()
        player:addSpell(xi.magic.spell.APURURU_UC, { silentLog = true })

        flow.onTrigger(player)
        pick('Unity trusts (10)')

        for _, label in ipairs(optionLabels()) do
            assert(label ~= 'Apururu (UC)', 'a known trust is still offered')
        end
    end)

    it('pages through a long list', function()
        flow.onTrigger(player)
        pick('Event and campaign trusts (46)')
        assert(menu.title == 'Event and campaign trusts (page 1 of 8)', 'unexpected title: ' .. menu.title)

        pick('Next page')
        assert(menu.title == 'Event and campaign trusts (page 2 of 8)', 'unexpected title: ' .. menu.title)

        pick('Previous page')
        pick('Back')
        assert(#menu.options == 3, 'the first menu should offer the three groups')
    end)

    it('refuses without enough gil and takes nothing', function()
        player:setGil(99999)

        local ok = flow.buy(player, xi.magic.spell.ZEID)

        assert(not ok, 'sold a trust for less than its price')
        assert(not player:hasSpell(xi.magic.spell.ZEID), 'taught the trust anyway')
        assert(player:getGil() == 99999, 'gil changed')
    end)

    it('refuses without a Trust permit', function()
        player:delKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)

        local ok = flow.buy(player, xi.magic.spell.ZEID)

        assert(not ok, 'sold a trust without a permit')
        assert(player:getGil() == 1000000, 'gil changed')

        flow.onTrigger(player)
        assert(menu == nil, 'opened the menu for a player without a permit')
    end)

    it('does not sell a trust twice, or one it does not carry', function()
        assert(flow.buy(player, xi.magic.spell.ZEID), 'first purchase failed')
        assert(not flow.buy(player, xi.magic.spell.ZEID), 'sold the same trust twice')
        assert(not flow.buy(player, xi.magic.spell.SHANTOTTO), 'sold a trust it does not carry')
        assert(player:getGil() == 900000, 'expected one charge only, have ' .. player:getGil())
    end)
end)
