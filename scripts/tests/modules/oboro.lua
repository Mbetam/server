-----------------------------------
-- Oboro (modules/custom/lua/oboro_*.lua; in Ru'Lude Gardens since 2026-09-29): stores Pluton / Riftborn Boulder /
-- Beitetsu and upgrades Relic / Mythic / Empyrean weapons 99 -> 119 (300) -> 119 III (1,000).
-----------------------------------

describe('Oboro', function()
    ---@type CClientEntityPair
    local player
    local flow = require('modules/custom/lua/oboro_flow')
    local menu = nil

    local PLUTON, BOULDER, BEITETSU = 4059, 4061, 4060
    local EXCALIBUR_99, EXCALIBUR_119, EXCALIBUR_119_III = 19748, 20645, 20685
    local BURTGANG_99_II, BURTGANG_119                   = 19954, 20649
    local ALMACE_119, ALMACE_119_III                     = 20653, 20689
    local IDRIS_119, IDRIS_119_III                       = 21070, 21080

    local function pick(label)
        assert(menu ~= nil, 'no menu is open')

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                menu = nil
                option[2](player)

                return
            end
        end

        error('no option "' .. label .. '" in the menu')
    end

    local function trade(items)
        player.actions:tradeNpc('DE_Oboro', items)
        xi.test.world:skipTime(1)
    end

    local function upgrade(fromId, toId)
        player:addItem(fromId)
        trade({ fromId })
        assert(menu ~= nil, 'Oboro offered no upgrade for ' .. fromId)
        pick('Yes')
        assert(player:getItemCount(toId) == 1, 'did not get ' .. toId)
        assert(player:getItemCount(fromId) == 0, 'the old weapon ' .. fromId .. ' was not taken')
    end

    before_each(function()
        menu = nil
        flow.setMenuSender(function(_, sent) menu = sent end)
        player = xi.test.world:spawnPlayer({ zone = xi.zone.RULUDE_GARDENS, job = xi.job.WAR, level = 99 })
    end)

    after_each(function()
        flow.setMenuSender(nil)
        flow.finish(player)
    end)

    it('stores traded materials, each in its own balance', function()
        player:addItem({ id = PLUTON, quantity = 50, silent = true })
        player:addItem({ id = BEITETSU, quantity = 20, silent = true })

        trade({ { itemId = PLUTON, quantity = 50 }, { itemId = BEITETSU, quantity = 20 } })

        assert(flow.getBalance(player, 'relic') == 50, 'Pluton balance ' .. flow.getBalance(player, 'relic'))
        assert(flow.getBalance(player, 'empyrean') == 20, 'Beitetsu balance ' .. flow.getBalance(player, 'empyrean'))
        assert(flow.getBalance(player, 'mythic') == 0, 'Riftborn Boulder balance should be 0')
        assert(player:getItemCount(PLUTON) == 0 and player:getItemCount(BEITETSU) == 0, 'the materials were not taken')
    end)

    it('Relic: 99 -> 119 takes 300 Pluton, 119 -> 119 III takes 1,000', function()
        player:setCharVar('OBORO_PLUTON', 1350)

        upgrade(EXCALIBUR_99, EXCALIBUR_119)
        assert(flow.getBalance(player, 'relic') == 1050, 'expected 1,050 Pluton left, have ' .. flow.getBalance(player, 'relic'))

        player:delItem(EXCALIBUR_119, 1)
        upgrade(EXCALIBUR_119, EXCALIBUR_119_III)
        assert(flow.getBalance(player, 'relic') == 50, 'expected 50 Pluton left, have ' .. flow.getBalance(player, 'relic'))

        trade({ EXCALIBUR_119_III })
        assert(menu == nil, 'offered to upgrade a 119 III')
    end)

    it('Mythic 99 II uses Riftborn Boulders; Empyrean 119 uses Beitetsu; Idris goes 119 -> 119 III', function()
        player:setCharVar('OBORO_BOULDER', 300)
        upgrade(BURTGANG_99_II, BURTGANG_119)
        assert(flow.getBalance(player, 'mythic') == 0, 'Riftborn Boulders not spent')

        player:setCharVar('OBORO_BEITETSU', 1000)
        upgrade(ALMACE_119, ALMACE_119_III)
        assert(flow.getBalance(player, 'empyrean') == 0, 'Beitetsu not spent')

        player:setCharVar('OBORO_BOULDER', 1000)
        upgrade(IDRIS_119, IDRIS_119_III)
    end)

    it('refuses with too little stored, or a weapon traded together with materials, and takes nothing', function()
        player:setCharVar('OBORO_PLUTON', 299)
        player:addItem(EXCALIBUR_99)
        trade({ EXCALIBUR_99 })
        assert(menu == nil, 'offered the upgrade with 299 Pluton')

        player:addItem({ id = PLUTON, quantity = 10, silent = true })
        trade({ EXCALIBUR_99, { itemId = PLUTON, quantity = 10 } })
        assert(menu == nil, 'offered the upgrade with materials in the same trade')

        assert(player:getItemCount(EXCALIBUR_99) == 1 and player:getItemCount(PLUTON) == 10, 'something was taken')
        assert(flow.getBalance(player, 'relic') == 299, 'the balance changed')
    end)

    it('covers 50 weapons, all of which exist', function()
        local config = require('modules/custom/lua/oboro_config')
        local count  = 0

        for _, chains in pairs(config.chains) do
            for _, chain in ipairs(chains) do
                count = count + 1

                for _, id in ipairs({ chain.base[1], chain.base[2], chain.s119, chain.s119ii, chain.s119iii }) do
                    assert(GetReadOnlyItem(id) ~= nil, 'item ' .. id .. ' does not exist')
                end
            end
        end

        assert(count == 50, 'expected 50 weapons, got ' .. count)
    end)

    it('stands in Ru\'Lude Gardens at Eric\'s spot, and the Port Jeuno Oboro is gone', function()
        local oboro = player.entities:get('DE_Oboro')
        assert(oboro ~= nil, 'no Oboro in Ru\'Lude Gardens')
        assert(math.abs(oboro:getXPos() - 10.5124) < 0.01 and math.abs(oboro:getYPos() - 3.1) < 0.01 and math.abs(oboro:getZPos() - 116.5696) < 0.01, 'Oboro is not at X 10.5124 Y 3.1 Z 116.5696')

        xi.test.world:spawnPlayer({ zone = xi.zone.PORT_JEUNO })
        assert(GetNPCByID(17784988):getStatus() == xi.status.DISAPPEAR, 'the Port Jeuno Oboro is still there')
    end)
end)
