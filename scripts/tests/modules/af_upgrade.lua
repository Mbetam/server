-----------------------------------
-- The Armor Upgrader (modules/custom/lua/af_upgrade_*.lua): Artifact, Relic and Empyrean armor one tier per trade.
-----------------------------------

describe('Armor Upgrader', function()
    ---@type CClientEntityPair
    local player
    local config = require('modules/custom/lua/af_upgrade_config')
    local flow   = require('modules/custom/lua/af_upgrade_flow')
    local core   = require('modules/custom/lua/augment_core')

    -- The most recent menu the NPC sent. Real menus are not opened in tests.
    local menu = nil

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

    -- Trades the piece, confirms, and returns the gil paid
    local function upgrade(itemId)
        local before = player:getGil()

        player.actions:tradeNpc('DE_Armor_Upgrader', { itemId })
        xi.test.world:skipTime(1)
        assert(menu ~= nil, 'the Upgrader did not offer an upgrade for ' .. itemId)
        pick('Yes')

        return before - player:getGil()
    end

    -- The whole chain of one piece, lowest tier first
    local function fullChain(family, job, slot)
        local chain = config.chains[family][job][slot]
        local ids   = {}

        for _, id in ipairs(chain.base) do
            table.insert(ids, id)
        end

        for _, id in ipairs(chain.reforged) do
            table.insert(ids, id)
        end

        return ids
    end

    before_each(function()
        menu = nil
        flow.setMenuSender(function(_, sent) menu = sent end)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
        player:setGil(20000000)
    end)

    after_each(function()
        flow.setMenuSender(nil)
        flow.finish(player)
    end)

    it('has complete chains for 3 families x 22 jobs x 5 slots (+5 female DNC), and every item exists', function()
        local lengths = { af = { 2, 5 }, relic = { 3, 5 }, empyrean = { 3, 4 } }
        local count   = 0

        for family, jobs in pairs(config.chains) do
            for job, slots in pairs(jobs) do
                -- DNC Artifact: a male and a female chain per slot
                local expected = (family == 'af' and job == 'DNC') and 10 or 5
                assert(#slots == expected, family .. ' ' .. job .. ' has ' .. #slots .. ' chains')

                for _, chain in ipairs(slots) do
                    count = count + 1
                    local oldLength = (job == 'GEO' or job == 'RUN') and 0 or lengths[family][1]

                    assert(#chain.base == oldLength and #chain.reforged == lengths[family][2], family .. ' ' .. job .. ': wrong chain length')

                    for _, id in ipairs(fullChain(family, job, _)) do
                        assert(GetReadOnlyItem(id) ~= nil, 'item ' .. id .. ' does not exist')
                    end
                end
            end
        end

        assert(count == 335, 'expected 335 chains, got ' .. count)
    end)

    it('stands in Norg and in GM Home', function()
        assert(player.entities:get('DE_Armor_Upgrader') ~= nil, 'the Upgrader should be in GM Home')

        local norg = xi.test.world:spawnPlayer({ zone = xi.zone.NORG })
        assert(norg.entities:get('DE_Armor_Upgrader') ~= nil, 'the Upgrader should be in Norg')
    end)

    it('Artifact: first set to +1 costs 50,000, and a Reforged piece climbs to +4', function()
        local chain = fullChain('af', 'WAR', 2) -- Fighter's Lorica ... Pummeler's Lorica +4

        player:addItem(chain[1])
        assert(upgrade(chain[1]) == config.prices.oldPlus1, 'wrong price for +1')
        assert(player:getItemCount(chain[2]) == 1, 'no Fighter\'s Lorica +1')

        for index = 2, #chain - 1 do
            upgrade(chain[index])
        end

        assert(player:getItemCount(chain[#chain]) == 1, 'did not reach Pummeler\'s Lorica +4')
    end)

    it('Relic: +1 to +2 costs 75,000, and +2 goes on to the Reforged set', function()
        local chain = fullChain('relic', 'WAR', 2) -- Warrior's Lorica ... Agoge Lorica +4

        player:addItem(chain[2])
        assert(upgrade(chain[2]) == config.prices.oldPlus2, 'wrong price for the Relic +2')
        assert(upgrade(chain[3]) == config.prices.reforged, 'wrong price for the Reforged Relic')
        assert(player:getItemCount(chain[4]) == 1, 'no Agoge Lorica')
    end)

    it('Empyrean stops at +3, and keeps Augmenter augments on the way', function()
        local chain = fullChain('empyrean', 'WAR', 2) -- Ravager's Lorica ... Boii Lorica +3

        player:addItem({ id = chain[#chain - 1], exdata = core.buildExdata({ { id = 146, value = 0 } }) })
        upgrade(chain[#chain - 1])

        local augments = core.readItem(player:findItem(chain[#chain]))
        assert(#augments == 1 and augments[1].id == 146, 'the Dual Wield augment was lost')

        player.actions:tradeNpc('DE_Armor_Upgrader', { chain[#chain] })
        xi.test.world:skipTime(1)
        assert(menu == nil, 'offered to upgrade an Empyrean +3')
    end)

    it('a +4 piece has its stats when worn (modules/custom/sql/armor_stats.sql)', function()
        local lorica4 = config.chains.af.WAR[2].reforged[5] -- Pummeler's Lorica +4

        player:addItem(lorica4)

        local def, str, haste = player:getMod(xi.mod.DEF), player:getMod(xi.mod.STR), player:getMod(xi.mod.HASTE_GEAR)
        player:equipItem(lorica4, nil, xi.slot.BODY)

        assert(player:getMod(xi.mod.DEF) - def == 168, 'DEF +168 expected, got +' .. (player:getMod(xi.mod.DEF) - def))
        assert(player:getMod(xi.mod.STR) - str == 40, 'STR +40 expected, got +' .. (player:getMod(xi.mod.STR) - str))
        assert(player:getMod(xi.mod.HASTE_GEAR) - haste == 400, 'Haste +4% expected')
    end)

    it('refuses anything that is not Artifact, Relic or Empyrean armor', function()
        player:addItem(xi.item.COPPER_RING)
        player.actions:tradeNpc('DE_Armor_Upgrader', { xi.item.COPPER_RING })
        xi.test.world:skipTime(1)
        assert(menu == nil, 'offered to upgrade a Copper Ring')
    end)
end)
