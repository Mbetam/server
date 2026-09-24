-----------------------------------
-- The Augmenter NPC in the real engine (modules/custom/lua/augmenter_npc.lua and augmenter_flow.lua):
-- a real trade, real items, real gil and the real augment mods.
-----------------------------------
local core = require('modules/custom/lua/augment_core')
local flow = require('modules/custom/lua/augmenter_flow')

-- The prices and amounts these tests were written against (see augment_test_tuning.lua)
require('scripts/tests/modules/augment_test_tuning').apply(core.config)
-----------------------------------

describe('Augmenter NPC', function()
    ---@type CClientEntityPair
    local player

    -- Ascetic's Ring (13440): a plain level 1 ring any job can wear, not Rare or Ex (so it can be traded) and not a fishable item.
    -- Do NOT use the Copper Ring: it is fishing junk, the engine treats every fishable item as a fish first, and it then ignores augment data.
    local ring = 13440

    local function settle()
        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end
    end

    -- A ring that already carries these augments
    local function giveAugmentedRing(list)
        player:addItem({ id = ring, exdata = core.buildExdata(list) })
    end

    -- The most recent menu the NPC sent. Real menus are not opened in tests (see flow.setMenuSender).
    local menu = nil

    -- Clicks an option in the most recent menu, the way a player would
    local function pick(label)
        assert(menu ~= nil, 'no menu is open')

        local options = {}

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                menu = nil
                option[2](player)

                return
            end

            table.insert(options, option[1])
        end

        error('no option "' .. label .. '" in the menu; the options are: ' .. table.concat(options, ' | '))
    end

    before_each(function()
        menu = nil
        flow.setMenuSender(function(_, sent) menu = sent end)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
        player:setGil(10000000)
    end)

    after_each(function()
        flow.setMenuSender(nil)
        -- The conversation now stays open after an augment (back to the first menu), as it would until the player
        -- closes the menu: end it, so the next test starts clean
        flow.finish(player)
    end)

    it('stands in GM Home', function()
        assert(player.entities:get('DE_Augmenter') ~= nil, 'the Augmenter should be in GM Home')
    end)

    it('stands in Norg', function()
        local norg = xi.test.world:spawnPlayer({ zone = xi.zone.NORG })

        assert(norg.entities:get('DE_Augmenter') ~= nil, 'the Augmenter should be in Norg')
    end)

    it('only starts a conversation when an item is traded', function()
        player:addItem(ring)

        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        assert(player:getGil() == 10000000, 'nothing should be charged by the trade itself')
        assert(player:getItemCount(ring) == 1, 'the ring should still be in the bag')
    end)

    it('walks a real trade through the menus from start to finish', function()
        player:addItem(ring)
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        assert(menu ~= nil and menu.title:find('Augmenter', 1, true), 'the trade should have opened the first menu')

        pick('Add an augment')
        pick('Dual Wield')
        pick('+2 (50,000 gil)')
        assert(menu.title == 'Add Dual Wield +2 for 50,000 gil?', 'the confirmation should state the price: ' .. menu.title)
        assert(player:getGil() == 10000000, 'nothing should be charged before confirming')

        pick('Yes, augment it')

        assert(player:getGil() == 10000000 - 50000, 'the ring should have cost 50,000 gil')

        local augments = core.readItem(player:findItem(ring))
        assert(#augments == 1 and augments[1].id == 146 and augments[1].value == 1, 'the ring should carry Dual Wield +2')
    end)

    it('adds an augment to a traded ring, takes the gil, and the augment works', function()
        player:addItem(ring)
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        flow.commitAdd(player, 'dual_wield', 1)

        assert(player:getGil() == 10000000 - 10000, 'a tier 1 augment costs 10,000 gil but the player paid ' .. (10000000 - player:getGil()))
        assert(player:getItemCount(ring) == 1, 'the ring should be replaced, not duplicated: the player has ' .. player:getItemCount(ring))

        local augments = core.readItem(player:findItem(ring))
        assert(#augments == 1 and augments[1].id == 146 and augments[1].value == 0, 'the ring should carry Dual Wield +1')

        local before = player:getMod(xi.mod.DUAL_WIELD)
        player:equipItem(ring, nil, xi.slot.RING1)

        assert(player:getMod(xi.mod.DUAL_WIELD) - before == 1, 'the new ring should give Dual Wield +1')
    end)

    it('augments a Rare item in place (Cassie Earring), even with a full bag', function()
        local earring = xi.item.CASSIE_EARRING

        player:addItem(earring)

        -- Fill the bag: augmenting no longer needs a free slot
        while player:getFreeSlotsCount() > 0 do
            player:addItem(xi.item.PEBBLE, 99) -- a full stack takes a slot of its own
        end

        player.actions:tradeNpc('DE_Augmenter', { earring })
        settle()

        flow.commitAdd(player, 'dual_wield', 1)
        settle()

        assert(player:getGil() == 10000000 - 10000, 'a tier 1 augment costs 10,000 gil but the player paid ' .. (10000000 - player:getGil()))
        assert(player:getItemCount(earring) == 1, 'there should still be exactly one earring: ' .. player:getItemCount(earring))

        local augments = core.readItem(player:findItem(earring))
        assert(#augments == 1 and augments[1].id == 146 and augments[1].value == 0, 'the Rare earring should carry Dual Wield +1')

        local before = player:getMod(xi.mod.DUAL_WIELD)
        player:equipItem(earring, nil, xi.slot.EAR1)

        assert(player:getMod(xi.mod.DUAL_WIELD) - before == 1, 'the earring should give Dual Wield +1')
    end)

    it('stacks the same augment through two real conversations', function()
        player:addItem(ring)

        for _ = 1, 2 do
            player.actions:tradeNpc('DE_Augmenter', { ring })
            settle()

            pick('Add an augment')
            pick('Dual Wield')
            pick('+1 (10,000 gil)')
            pick('Yes, augment it')
        end

        local augments = core.readItem(player:findItem(ring))

        assert(#augments == 2 and augments[1].id == 146 and augments[2].id == 146, 'the ring should carry Dual Wield twice')
        assert(player:getGil() == 10000000 - 20000, 'two augments should cost 20,000 gil')

        local before = player:getMod(xi.mod.DUAL_WIELD)
        player:equipItem(ring, nil, xi.slot.RING1)

        assert(player:getMod(xi.mod.DUAL_WIELD) - before == 2, 'two Dual Wield +1 augments should give +2')
    end)

    it('keeps the augments a ring already has', function()
        giveAugmentedRing({ { id = 146, value = 0 } })
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        flow.commitAdd(player, 'double_attack', 2)

        local augments = core.readItem(player:findItem(ring))
        assert(#augments == 2 and augments[1].id == 146 and augments[2].id == 143, 'the ring should carry both augments')
        assert(player:getGil() == 10000000 - 50000, 'a tier 2 augment costs 50,000 gil')
    end)

    it('removes an augment for gil and leaves a plain ring', function()
        giveAugmentedRing({ { id = 146, value = 0 } })
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        flow.commitRemove(player, 1)

        assert(player:getGil() == 10000000 - 5000, 'removing a tier 1 augment costs 5,000 gil')
        assert(#core.readItem(player:findItem(ring)) == 0, 'the ring should have no augments left')

        local before = player:getMod(xi.mod.DUAL_WIELD)
        player:equipItem(ring, nil, xi.slot.RING1)
        assert(player:getMod(xi.mod.DUAL_WIELD) == before, 'no Dual Wield should be left')
    end)

    it('does nothing when there has been no trade', function()
        player:addItem(ring)

        flow.commitAdd(player, 'dual_wield', 1)

        assert(player:getGil() == 10000000 and #core.readItem(player:findItem(ring)) == 0, 'confirming without a conversation must change nothing')
    end)

    it('refuses something that is not gear', function()
        player:addItem(xi.item.POTION)

        player.actions:tradeNpc('DE_Augmenter', { xi.item.POTION })
        settle()
        flow.commitAdd(player, 'dual_wield', 1)

        assert(player:getGil() == 10000000 and player:getItemCount(xi.item.POTION) == 1, 'a potion must be left alone')
    end)

    it('refuses more than one item', function()
        player:addItem(ring)
        player:addItem(xi.item.POTION)

        player.actions:tradeNpc('DE_Augmenter', { ring, xi.item.POTION })
        settle()
        flow.commitAdd(player, 'dual_wield', 1)

        assert(player:getGil() == 10000000, 'a two-item trade must not start a conversation')
    end)

    it('refuses to charge if the item was replaced while the menus were open', function()
        player:addItem(ring)
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        -- Swap the ring for a different one behind the NPC's back
        player:delItem(ring, 1)
        giveAugmentedRing({ { id = 144, value = 0 } })

        flow.commitAdd(player, 'dual_wield', 1)

        local augments = core.readItem(player:findItem(ring))
        assert(player:getGil() == 10000000, 'nothing should be charged for an item that changed')
        assert(#augments == 1 and augments[1].id == 144, 'the changed ring must be left exactly as it was')
    end)

    it('refuses to charge if the item is gone', function()
        player:addItem(ring)
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        player:delItem(ring, 1)
        flow.commitAdd(player, 'dual_wield', 1)

        assert(player:getGil() == 10000000 and player:getItemCount(ring) == 0, 'nothing should be charged or given for an item that is gone')
    end)

    it('refuses a bonus the player has not unlocked', function()
        player:setLevel(20)
        player:addItem(ring)
        player.actions:tradeNpc('DE_Augmenter', { ring })
        settle()

        flow.commitAdd(player, 'dual_wield', 3)

        assert(player:getGil() == 10000000 and #core.readItem(player:findItem(ring)) == 0, 'tier 3 needs level 60')
    end)
end)
