-----------------------------------
-- The Armor Upgrader (modules/custom/lua/af_upgrade_*.lua): Artifact, Relic and Empyrean armor one tier per trade, for
-- the retail materials of each step (af_upgrade_materials.lua), up to +3. And the added material drops
-- (modules/custom/lua/upgrade_drops*.lua).
-----------------------------------

describe('Armor Upgrader', function()
    ---@type CClientEntityPair
    local player
    local config    = require('modules/custom/lua/af_upgrade_config')
    local flow      = require('modules/custom/lua/af_upgrade_flow')
    local core      = require('modules/custom/lua/augment_core')
    local materials = require('modules/custom/lua/af_upgrade_materials')

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

    -- Gives the player the materials of the step that makes nextId; returns them as trade entries
    local function giveMaterials(nextId)
        local list  = flow.materialsFor(nextId)
        local trade = {}

        assert(list, 'no materials for ' .. nextId)

        for _, material in ipairs(list) do
            assert(player:addItem({ id = material.id, quantity = material.quantity, silent = true }), 'could not give item ' .. material.id)
            table.insert(trade, { itemId = material.id, quantity = material.quantity })
        end

        return trade
    end

    local function tradeWith(pieceId, trade)
        local items = { pieceId }

        for _, entry in ipairs(trade) do
            table.insert(items, entry)
        end

        player.actions:tradeNpc('DE_Armor_Upgrader', items)
        xi.test.world:skipTime(1)
    end

    -- Gives the materials, trades them with the piece, says Yes; returns the gil paid
    local function upgrade(pieceId)
        local entry = flow.lookup(pieceId)
        assert(entry and entry.next, 'no next step for ' .. pieceId)

        local before = player:getGil()
        tradeWith(pieceId, giveMaterials(entry.next))
        assert(menu ~= nil, 'the Upgrader did not offer an upgrade for ' .. pieceId)
        pick('Yes')

        assert(player:getItemCount(entry.next) == 1, 'did not get ' .. entry.next .. ' from ' .. pieceId)
        assert(player:getItemCount(pieceId) == 0, 'the old piece ' .. pieceId .. ' was not taken')

        for _, material in ipairs(flow.materialsFor(entry.next)) do
            assert(player:getItemCount(material.id) == 0, 'material ' .. material.id .. ' was not taken')
        end

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

    it('every step up to +3 has retail materials that exist, and +4 is not offered', function()
        local steps = 0

        for family, jobs in pairs(config.chains) do
            for job, slots in pairs(jobs) do
                for index in ipairs(slots) do
                    for _, id in ipairs(fullChain(family, job, index)) do
                        local entry = flow.lookup(id)

                        if entry.next then
                            steps = steps + 1
                            local list = flow.materialsFor(entry.next)
                            assert(list and #list > 0, family .. ' ' .. job .. ': no materials to make ' .. entry.next)

                            for _, material in ipairs(list) do
                                assert(GetReadOnlyItem(material.id) ~= nil, 'material ' .. material.id .. ' for ' .. entry.next .. ' does not exist')
                                assert(material.quantity >= 1 and material.quantity <= 99, 'bad quantity for ' .. material.id)
                            end
                        end
                    end
                end
            end
        end

        assert(flow.lookup(config.chains.af.WAR[2].reforged[4]).next == nil, 'Pummeler\'s Lorica +3 should be the top')
        assert(flow.lookup(config.chains.relic.WAR[2].reforged[4]).next == nil, 'Agoge Lorica +3 should be the top')

        local count = 0
        for _ in pairs(materials) do
            count = count + 1
        end

        assert(steps == count, string.format('%d steps but %d material entries', steps, count))
    end)

    it('stands in Norg and in GM Home', function()
        assert(player.entities:get('DE_Armor_Upgrader') ~= nil, 'the Upgrader should be in GM Home')

        local norg = xi.test.world:spawnPlayer({ zone = xi.zone.NORG })
        assert(norg.entities:get('DE_Armor_Upgrader') ~= nil, 'the Upgrader should be in Norg')
    end)

    it('Artifact: Sagheera\'s materials for +1, then the Reforged set climbs to +3 with no gil', function()
        local chain = fullChain('af', 'WAR', 2) -- Fighter's Lorica ... Pummeler's Lorica +4

        -- Retail +1: Ecarlate Cloth, Argyro Rivet, Dark Bronze Sheet and 35 Ancient Beastcoins
        local plusOne = flow.materialsFor(chain[2])
        assert(#plusOne == 4 and plusOne[4].id == xi.item.ANCIENT_BEASTCOIN and plusOne[4].quantity == 35, 'Fighter\'s Lorica +1 should take 35 beastcoins')

        player:addItem(chain[1])

        for index = 1, #chain - 2 do
            assert(upgrade(chain[index]) == 0, 'Artifact steps cost no gil')
        end

        assert(player:getItemCount(chain[#chain - 1]) == 1, 'did not reach Pummeler\'s Lorica +3')

        player.actions:tradeNpc('DE_Armor_Upgrader', { chain[#chain - 1] })
        xi.test.world:skipTime(1)
        assert(menu == nil, 'offered to make a +4')
    end)

    it('Relic: +2 takes 80 Forgotten items (both Magian trials), then goes on to the Reforged set', function()
        local chain = fullChain('relic', 'WAR', 1) -- Warrior's Mask ... Agoge Mask +4
        local list  = flow.materialsFor(chain[3])
        assert(#list == 1 and list[1].id == xi.item.FORGOTTEN_THOUGHT and list[1].quantity == 80, 'Warrior\'s Mask +2 should take 80 Forgotten Thoughts')

        player:addItem(chain[2])
        upgrade(chain[2])
        upgrade(chain[3])
        assert(player:getItemCount(chain[4]) == 1, 'no Agoge Mask')
    end)

    it('Empyrean +2 to +3 takes a Ra\'Kazarch Starstone and 1,000,000 gil, and keeps Augmenter augments', function()
        local chain = fullChain('empyrean', 'WAR', 2) -- Ravager's Lorica ... Boii Lorica +3

        player:addItem({ id = chain[#chain - 1], exdata = core.buildExdata({ { id = 146, value = 0 } }) })
        assert(upgrade(chain[#chain - 1]) == config.gil.empyrean.reforgedPlus3, 'wrong gil for Boii Lorica +3')

        local augments = core.readItem(player:findItem(chain[#chain]))
        assert(#augments == 1 and augments[1].id == 146, 'the Dual Wield augment was lost')

        player.actions:tradeNpc('DE_Armor_Upgrader', { chain[#chain] })
        xi.test.world:skipTime(1)
        assert(menu == nil, 'offered to upgrade an Empyrean +3')
    end)

    it('the piece alone gets a list, not a menu; missing or extra items are refused and nothing is taken', function()
        local chain = fullChain('af', 'WAR', 1) -- Fighter's Mask ...
        player:addItem(chain[1])

        player.actions:tradeNpc('DE_Armor_Upgrader', { chain[1] })
        xi.test.world:skipTime(1)
        assert(menu == nil, 'the piece alone should only list the materials')

        -- One material short
        local trade = giveMaterials(chain[2])
        local short = { trade[1], trade[2], trade[3] }
        tradeWith(chain[1], short)
        assert(menu == nil, 'offered the upgrade with a material missing')

        -- Something that is not needed
        player:addItem(xi.item.COPPER_RING)
        table.insert(trade, xi.item.COPPER_RING)
        tradeWith(chain[1], trade)
        assert(menu == nil, 'offered the upgrade with a Copper Ring in the trade')

        assert(player:getItemCount(chain[1]) == 1 and player:getItemCount(xi.item.ANCIENT_BEASTCOIN) == 20, 'something was taken')
    end)

    it('if a material is gone before Yes, nothing changes', function()
        local chain = fullChain('af', 'WAR', 1)
        player:addItem(chain[1])

        tradeWith(chain[1], giveMaterials(chain[2]))
        assert(menu ~= nil, 'no menu')

        player:delItem(xi.item.ANCIENT_BEASTCOIN, 20)
        pick('Yes')

        assert(player:getItemCount(chain[1]) == 1 and player:getItemCount(chain[2]) == 0, 'the upgrade went through without the beastcoins')
        assert(player:getItemCount(xi.item.SQUARE_OF_ECARLATE_CLOTH) == 1, 'a material was taken')
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

describe('Upgrade material drops', function()
    local dropConfig = require('modules/custom/lua/upgrade_drops_config')

    -- Records what the drop code adds to a loot container
    local function fakeLoot()
        local loot = { items = {}, groups = {} }

        loot.addItem = function(self, item, rate, quantity)
            table.insert(self.items, { item = item, rate = rate, quantity = quantity or 1 })
        end

        loot.addGroup = function(self, rate, items)
            table.insert(self.groups, { rate = rate, items = items })
        end

        return loot
    end

    local function fakeMob(zone, name, isNM)
        return { getZoneID = function() return zone end, getName = function() return name end, isNM = function() return isNM end }
    end

    it('knows its sources: zone NMs, named bosses by zone, and not copies elsewhere', function()
        local drops = xi.custom.upgradeDrops
        local function tiers(zone, name, isNM)
            return table.concat(drops.tiersFor(fakeMob(zone, name, isNM)), ',')
        end

        assert(tiers(xi.zone.DYNAMIS_XARCABARD, 'Dynamis_Lord', true) == 'dynamisNM,dynamisLord,omenBoss', tiers(xi.zone.DYNAMIS_XARCABARD, 'Dynamis_Lord', true))
        assert(tiers(xi.zone.ABYSSEA_LA_THEINE, 'Briareus', true) == 'abysseaNM,bigBoss', 'Briareus')
        assert(tiers(xi.zone.ABYSSEA_LA_THEINE, 'Some_Crab', false) == '', 'a normal Abyssea mob drops nothing extra')
        assert(tiers(xi.zone.RUAUN_GARDENS, 'Genbu', true) == 'omenBoss,bigBoss', 'Genbu')
        assert(tiers(xi.zone.NYZUL_ISLE, 'Genbu', true) == '', 'the Nyzul Isle copy of Genbu must not drop')
    end)

    it('job items are the killer\'s job: 3 cards from an Omen boss, 2 shards from Dynamis Lord', function()
        local drkCard = 9288 -- paragon_dark_knight_card (these items have no xi.item name)
        local loot    = fakeLoot()
        xi.custom.upgradeDrops.addLoot(loot, { 'omenBoss' }, xi.job.DRK)
        assert(#loot.items == 1 and loot.items[1].item == drkCard and loot.items[1].quantity == 3, 'expected 3 Paragon Dark Knight Cards')
        assert(#loot.groups == 2, 'expected the Omen item and scale groups')

        loot = fakeLoot()
        xi.custom.upgradeDrops.addLoot(loot, { 'dynamisLord' }, xi.job.RUN)
        assert(#loot.groups >= 2, 'expected two shard rolls')
        local shards = loot.groups[1].items
        -- 9565 headshard_run ... 9741 footshard_run
        assert(#shards == 5 and shards[1].item == 9565 and shards[5].item == 9741, 'shards should be the RUN ones of every slot')
    end)

    it('a real kill: Briareus drops a Ra\'Kazarch Sapphire', function()
        local bigBoss = dropConfig.tiers.bigBoss
        dropConfig.tiers.bigBoss = { { 'sapphire', xi.drop_rate.GUARANTEED } } -- make the roll certain for the test

        local player = xi.test.world:spawnPlayer({ zone = xi.zone.ABYSSEA_LA_THEINE, job = xi.job.WAR, level = 99 })
        local mob    = player.entities:moveTo('Briareus')
        mob:respawn()
        mob:updateClaim(player)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 5 do
            xi.test.world:skipTime(1)
        end

        dropConfig.tiers.bigBoss = bigBoss
        assert(mob:isDead(), 'Briareus did not die')

        -- Solo, drops go straight to the inventory; in a party they go to the treasure pool
        local found = player:getItemCount(9927) > 0 -- rakaznar_sapphire

        for _, item in ipairs(player:getTreasurePool():getItems()) do
            found = found or item.id == 9927
        end

        assert(found, 'Briareus dropped no Ra\'Kazarch Sapphire')
    end)
end)
