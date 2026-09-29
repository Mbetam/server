-----------------------------------
-- JSE weapon progression (modules/custom/jse_progression/): the Splintery Chest sells a base weapon, the family's
-- Magian Moogle takes it to 85 / 95 / 99 for Abyssea NM materials, Oboro to 119 / 119 III, and finishing a family
-- unlocks the next one. Plus the material drops and the NM difficulty.
-----------------------------------

describe('JSE weapon progression', function()
    ---@type CClientEntityPair
    local player
    local config   = require('modules/custom/jse_progression/jse_config')
    local progress = require('modules/custom/jse_progression/jse_progress')
    local oboro    = require('modules/custom/lua/oboro_flow')
    local chest    = xi.custom.jseChest
    local menu     = nil

    local CHEST, GREEN, ORANGE = 17772781, 17772784, 17772778
    local relic                = config.families.relic
    local excalibur            = relic.weapons[3]
    local gjallarhorn          = relic.weapons[15]
    local daurdabla            = config.families.empyrean.weapons[15]

    local function pick(label)
        assert(menu ~= nil, 'no menu is open (wanted "' .. label .. '")')

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                menu = nil
                option[2](player)

                return
            end
        end

        error('no option "' .. label .. '" in the menu "' .. tostring(menu.title) .. '"')
    end

    -- Gives the stage's materials and trades them with the weapon to the NPC
    local function tradeStage(npcId, weaponId, materials)
        local items = { weaponId }

        for _, material in ipairs(materials) do
            player:addItem({ id = material[1], quantity = material[2], silent = true })
            table.insert(items, { itemId = material[1], quantity = material[2] })
        end

        player.actions:tradeNpc(npcId, items)
        xi.test.world:skipTime(1)
    end

    local function kill(name)
        local mob = player.entities:moveTo(name)
        mob:respawn()
        mob:updateClaim(player)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), name .. ' did not die')

        return mob
    end

    before_each(function()
        menu = nil
        chest.setMenuSender(function(_, sent) menu = sent end)
        oboro.setMenuSender(function(_, sent) menu = sent end)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.RULUDE_GARDENS, job = xi.job.WAR, level = 99 })
        player:setGil(3000000)
    end)

    after_each(function()
        chest.setMenuSender(nil)
        oboro.setMenuSender(nil)
    end)

    it('has 52 weapons whose stage items all exist, and 27 existing materials', function()
        local weapons = 0

        for _, family in pairs(config.families) do
            for _, weapon in ipairs(family.weapons) do
                weapons = weapons + 1

                for _, id in ipairs({ weapon.base, weapon.s85, weapon.s95, weapon.s99 }) do
                    assert(GetReadOnlyItem(id) ~= nil, weapon.name .. ': item ' .. id .. ' does not exist')
                end
            end

            for _, stage in ipairs(family.stages) do
                for _, material in ipairs(stage) do
                    assert(GetReadOnlyItem(material[1]) ~= nil, 'material ' .. material[1] .. ' does not exist')
                end
            end
        end

        assert(weapons == 52, 'expected 52 weapons, got ' .. weapons)
    end)

    it('the chest names every missing requirement and takes nothing', function()
        player:setLevel(98)
        player:setGil(100)

        local problems = chest.problems(player, 'mythic')
        assert(#problems == 3, 'expected level, unlock and gil problems, got: ' .. table.concat(problems, ' / '))

        local ok = chest.buy(player, 'mythic', config.families.mythic.weapons[1])
        assert(not ok and player:getGil() == 100 and progress.getActive(player) == 0, 'the chest sold anyway')
    end)

    it('buying through the chest menu: family, page, weapon, Yes; then one weapon at a time', function()
        player.entities:gotoAndTrigger(CHEST)
        xi.test.world:skipTime(1)
        pick('Relic')
        pick(excalibur.name)
        pick('Yes')

        assert(player:getItemCount(excalibur.base) == 1, 'no Excalibur (75)')
        assert(player:getGil() == 3000000 - config.price, 'wrong price')
        assert(progress.getActive(player) == excalibur.base, 'Excalibur is not the active weapon')

        assert(#chest.problems(player, 'relic') == 1, 'a second weapon should be refused while Excalibur is in progress')

        -- Lost it: a new one can be bought, and replaces it
        player:delItem(excalibur.base, 1)
        assert(#chest.problems(player, 'relic') == 0, 'a lost weapon should be buyable again')
    end)

    it('Relic: 75 -> 85 -> 95 -> 99 at the green moogle; wrong moogle, missing or extra items are refused', function()
        player:addItem(excalibur.base)
        progress.setActive(player, excalibur.base)

        -- Wrong family moogle: nothing taken
        tradeStage(ORANGE, excalibur.base, relic.stages[1])
        assert(player:getItemCount(excalibur.base) == 1 and player:getItemCount(relic.stages[1][1][1]) == 5, 'the orange moogle took a Relic trade')

        -- One material short: nothing taken
        player:delItem(relic.stages[1][3][1], 5)
        player.actions:tradeNpc(GREEN, { excalibur.base, { itemId = relic.stages[1][1][1], quantity = 5 }, { itemId = relic.stages[1][2][1], quantity = 5 } })
        xi.test.world:skipTime(1)
        assert(player:getItemCount(excalibur.base) == 1, 'an incomplete trade was taken')
        player:delItem(relic.stages[1][1][1], 5)
        player:delItem(relic.stages[1][2][1], 5)

        tradeStage(GREEN, excalibur.base, relic.stages[1])
        assert(player:getItemCount(excalibur.s85) == 1, 'no Excalibur (85)')
        tradeStage(GREEN, excalibur.s85, relic.stages[2])
        assert(player:getItemCount(excalibur.s95) == 1, 'no Excalibur (95)')
        tradeStage(GREEN, excalibur.s95, relic.stages[3])
        assert(player:getItemCount(excalibur.s99) == 1, 'no Excalibur (99)')

        for _, stage in ipairs(relic.stages) do
            for _, material in ipairs(stage) do
                assert(player:getItemCount(material[1]) == 0, 'material ' .. material[1] .. ' was not used up')
            end
        end

        assert(progress.getActive(player) == excalibur.base, 'still in progress until 119 III')
    end)

    it('Oboro 99 -> 119 -> 119 III finishes it: active slot clears, Mythic unlocks', function()
        player:addItem(excalibur.s99)
        progress.setActive(player, excalibur.base)
        player:setCharVar('OBORO_PLUTON', 1300)

        for _, step in ipairs({ { excalibur.s99, excalibur.oboro.s119 }, { excalibur.oboro.s119, excalibur.oboro.s119iii } }) do
            player.actions:tradeNpc('DE_Oboro', { step[1] })
            xi.test.world:skipTime(1)
            pick('Yes')
            assert(player:getItemCount(step[2]) == 1, 'Oboro did not make ' .. step[2])
        end

        assert(progress.getActive(player) == 0, 'the active weapon did not clear')
        assert(progress.isDone(player, 'relic'), 'Relic not marked done')
        assert(#chest.problems(player, 'mythic') == 0, 'Mythic should now be open')
        assert(#chest.problems(player, 'empyrean') == 1, 'Empyrean should still need a finished Mythic')
    end)

    it('no-119 weapons finish at 99 (Gjallarhorn); Daurdabla starts at 85', function()
        player:addItem(gjallarhorn.s95)
        progress.setActive(player, gjallarhorn.base)
        tradeStage(GREEN, gjallarhorn.s95, relic.stages[3])
        assert(player:getItemCount(gjallarhorn.s99) == 1, 'no Gjallarhorn (99)')
        assert(progress.isDone(player, 'relic') and progress.getActive(player) == 0, 'Gjallarhorn 99 should finish the Relic')

        local step = progress.moogleStep(daurdabla.base)
        assert(step == 2, 'Daurdabla (85) should start at the 85 -> 95 step, got ' .. tostring(step))
    end)

    it('NM drops: Ovni gives a Stone of Voyage every kill; Carabosse at least one Gem', function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.ABYSSEA_LA_THEINE, job = xi.job.WAR, level = 99 })
        xi.abyssea.afterZoneIn(player)

        kill('Ovni')
        assert(player:getItemCount(3226) >= 1, 'Ovni dropped no Stone of Voyage')

        kill('Carabosse')
        assert(player:getItemCount(2930) >= 1, 'Carabosse dropped no Carabosse\'s Gem')
    end)

    it('difficulty: a Mythic megaboss (Sedna) spawns with x1.15 x1.25 HP, and respawns do not stack it', function()
        local vunkerl = xi.test.world:spawnPlayer({ zone = xi.zone.ABYSSEA_VUNKERL, job = xi.job.WAR, level = 99 })
        local sedna   = GetMobByID(17666500)

        SpawnMob(17666500)
        xi.test.world:skipTime(1)
        local base = sedna:getLocalVar('JSE_BASE_HP')
        assert(base > 0, 'Sedna was not scaled')
        assert(sedna:getMaxHP() == math.floor(base * 1.15 * 1.25), string.format('max HP %d, base %d', sedna:getMaxHP(), base))
        assert(sedna:getMod(xi.mod.ATTP) == 44, 'attack bonus ' .. sedna:getMod(xi.mod.ATTP))

        DespawnMob(17666500)
        xi.test.world:skipTime(1)
        SpawnMob(17666500)
        xi.test.world:skipTime(1)
        assert(sedna:getMaxHP() == math.floor(base * 1.15 * 1.25), 'the HP bonus stacked on respawn: ' .. sedna:getMaxHP())

        DespawnMob(17666500)
        assert(vunkerl)
    end)

    it('talking to a moogle gives the JSE instructions, not a retail event; other trades are turned away', function()
        player.entities:gotoAndTrigger(GREEN)
        xi.test.world:skipTime(1)
        assert(not player:isInEvent(), 'the green moogle started a retail event')

        player:addItem(xi.item.COPPER_RING)
        player.actions:tradeNpc(ORANGE, { xi.item.COPPER_RING })
        xi.test.world:skipTime(1)
        assert(not player:isInEvent() and player:getItemCount(xi.item.COPPER_RING) == 1, 'a non-JSE trade started an event or was taken')
    end)
end)
