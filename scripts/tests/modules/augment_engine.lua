-----------------------------------
-- Augments in the real engine: the catalog (augment_config.lua) must give exactly the bonus it promises, and the item
-- reader (augment_core.lua) must understand items the engine actually produces.
-----------------------------------
local core   = require('modules/custom/lua/augment_core')
local config = core.config
-----------------------------------

describe('Augments in the engine', function()
    ---@type CClientEntityPair
    local player

    -- Ascetic's Ring (13440): a plain level 1 ring any job can wear, not Rare or Ex (so it can be traded) and not a fishable item.
    -- Do NOT use the Copper Ring: it is fishing junk, the engine treats every fishable item as a fish first, and it then ignores augment data.
    local ring = 13440

    local function spawn()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
    end

    -- Gives the player a ring carrying these augments and puts it on. Returns nothing.
    local function wearRing(augments)
        player:addItem({ id = ring, exdata = core.buildExdata(augments) })
        player:equipItem(ring, nil, xi.slot.RING1)

        assert(player:getEquipID(xi.slot.RING1) == ring, 'precondition: the ring should be equipped')
    end

    before_each(function()
        spawn()
    end)

    it('grants exactly the promised bonus for every stat at every tier', function()
        for _, stat in ipairs(config.stats) do
            for tier = 1, #config.tiers do
                spawn()

                local id, value, amount = core.encode(stat.key, tier)
                local mod               = xi.mod[stat.mod]
                local before            = player:getMod(mod)

                wearRing({ { id = id, value = value } })

                local gained   = player:getMod(mod) - before
                local expected = amount * stat.modPerPoint

                assert(gained == expected, string.format('%s tier %d (augment %d, value %d) should change %s by %d but changed it by %d',
                    stat.key, tier, id, value, stat.mod, expected, gained))
            end
        end
    end)

    it('applies every augment on an item, not only the first', function()
        local dualWieldId, dualWieldValue, dualWieldAmount = core.encode('dual_wield', 2)
        local doubleId, doubleValue, doubleAmount           = core.encode('double_attack', 3)
        local hasteId, hasteValue, hasteAmount              = core.encode('gear_haste', 4)

        local dualWieldBefore = player:getMod(xi.mod.DUAL_WIELD)
        local doubleBefore    = player:getMod(xi.mod.DOUBLE_ATTACK)
        local hasteBefore     = player:getMod(xi.mod.HASTE_GEAR)

        wearRing({ { id = dualWieldId, value = dualWieldValue }, { id = doubleId, value = doubleValue }, { id = hasteId, value = hasteValue } })

        assert(player:getMod(xi.mod.DUAL_WIELD) - dualWieldBefore == dualWieldAmount, 'the first augment was not applied')
        assert(player:getMod(xi.mod.DOUBLE_ATTACK) - doubleBefore == doubleAmount, 'the second augment was not applied')
        assert(player:getMod(xi.mod.HASTE_GEAR) - hasteBefore == hasteAmount * 100, 'the third augment was not applied')
    end)

    it('adds up the same augment used in several slots', function()
        local id, value, amount = core.encode('dual_wield', 2)
        local before            = player:getMod(xi.mod.DUAL_WIELD)

        wearRing({ { id = id, value = value }, { id = id, value = value }, { id = id, value = value }, { id = id, value = value } })

        assert(player:getMod(xi.mod.DUAL_WIELD) - before == amount * 4,
            string.format('four Dual Wield +%d augments should give +%d but gave +%d', amount, amount * 4, player:getMod(xi.mod.DUAL_WIELD) - before))
    end)

    -- The game once added an item's total for a mod once PER ENTRY on that item, so N copies of one augment gave N times
    -- too much (four Dual Wield +2 gave +32). Fixed in CBattleEntity::addEquipModifiers / delEquipModifiers.
    it('gives every copy once, for one to four copies of the same augment', function()
        for copies = 1, config.maxPerStat do
            spawn()

            local id, value, amount = core.encode('dual_wield', 2)
            local list              = {}

            for _ = 1, copies do
                table.insert(list, { id = id, value = value })
            end

            local before = player:getMod(xi.mod.DUAL_WIELD)

            wearRing(list)

            assert(player:getMod(xi.mod.DUAL_WIELD) - before == amount * copies,
                string.format('%d copies of Dual Wield +%d should give +%d but gave +%d', copies, amount, amount * copies, player:getMod(xi.mod.DUAL_WIELD) - before))
        end
    end)

    it('takes the whole bonus back off when the ring comes off', function()
        local id, value = core.encode('double_attack', 3)
        local before    = player:getMod(xi.mod.DOUBLE_ATTACK)

        wearRing({ { id = id, value = value }, { id = id, value = value }, { id = id, value = value } })
        assert(player:getMod(xi.mod.DOUBLE_ATTACK) > before, 'precondition: the bonus should be on')

        player:unequipItem(xi.slot.RING1)

        assert(player:getMod(xi.mod.DOUBLE_ATTACK) == before, 'after taking the ring off Double Attack should be back to ' .. before .. ' but is ' .. player:getMod(xi.mod.DOUBLE_ATTACK))
    end)

    it('reads back an item that carries the same augment four times', function()
        local id, value = core.encode('regen', 1)

        player:addItem({ id = ring, exdata = core.buildExdata({ { id = id, value = value }, { id = id, value = value }, { id = id, value = value }, { id = id, value = value } }) })

        local augments, reason = core.readItem(player:findItem(ring))

        assert(augments ~= nil and #augments == 4, 'an item with the same augment in every slot should be readable: ' .. tostring(reason))
        assert(core.countOf(augments, 'regen') == 4, 'all four should be Regen')
    end)

    it('reads a plain item as having no augments', function()
        player:addItem(ring)

        local augments, reason = core.readItem(player:findItem(ring))

        assert(augments ~= nil and #augments == 0, 'a plain ring should be augmentable: ' .. tostring(reason))
    end)

    it('reads back exactly what the engine stored', function()
        local written =
        {
            { id = select(1, core.encode('dual_wield', 3)), value = select(2, core.encode('dual_wield', 3)) },
            { id = select(1, core.encode('hp', 4)),         value = select(2, core.encode('hp', 4)) },
        }

        player:addItem({ id = ring, exdata = core.buildExdata(written) })

        local augments, reason = core.readItem(player:findItem(ring))

        assert(augments ~= nil, 'an item this system made should be readable: ' .. tostring(reason))
        assert(#augments == 2, 'expected two augments but read ' .. #augments)

        for slot = 1, 2 do
            assert(augments[slot].id == written[slot].id and augments[slot].value == written[slot].value,
                string.format('slot %d was written as %d/%d but read back as %d/%d', slot, written[slot].id, written[slot].value, augments[slot].id, augments[slot].value))
        end
    end)

    it('adds one more augment to an item that already has one, the way the Augmenter will', function()
        local firstId, firstValue = core.encode('dual_wield', 1)
        player:addItem({ id = ring, exdata = core.buildExdata({ { id = firstId, value = firstValue } }) })

        local existing = core.readItem(player:findItem(ring))
        local ok, plan = core.checkAdd({ level = 99, gil = 10000000, augments = existing, key = 'fast_cast', tier = 4 })
        assert(ok, 'the second augment should be allowed: ' .. tostring(plan))

        -- Swap the old ring for the new one, as a trade would
        local combined = core.withAdded(existing, plan.id, plan.value)
        player:delItem(ring, 1)
        player:addItem({ id = ring, exdata = core.buildExdata(combined) })

        local after = core.readItem(player:findItem(ring))
        assert(#after == 2 and after[1].id == firstId and after[2].id == plan.id, 'the new ring should carry both augments')

        local fastCastBefore = player:getMod(xi.mod.FASTCAST)
        player:equipItem(ring, nil, xi.slot.RING1)

        assert(player:getMod(xi.mod.FASTCAST) - fastCastBefore == 4, 'the added Fast Cast +4 should apply')
    end)

    it('gives back a plain item when the last augment is removed', function()
        local id, value = core.encode('regen', 1)
        player:addItem({ id = ring, exdata = core.buildExdata({ { id = id, value = value } }) })

        local existing = core.readItem(player:findItem(ring))
        local remaining = core.withRemoved(existing, 1)

        player:delItem(ring, 1)
        player:addItem({ id = ring, exdata = core.buildExdata(remaining) })

        local after = core.readItem(player:findItem(ring))
        assert(after ~= nil and #after == 0, 'a ring with every augment removed should read as plain')

        local regenBefore = player:getMod(xi.mod.REGEN)
        player:equipItem(ring, nil, xi.slot.RING1)
        assert(player:getMod(xi.mod.REGEN) == regenBefore, 'no augment should be left to apply')
    end)

    it('refuses an item the engine marks as a Magian trial item', function()
        local id, value = core.encode('dual_wield', 1)

        player:addItem(
        {
            id     = ring,
            exdata =
            {
                augmentKind    = xi.augment.kind.HAS_AUGMENTS,
                augmentSubKind = xi.augment.subKind.STANDARD + xi.augment.subKind.TRIAL,
                augments       = { { id = id, value = value } },
            },
        })

        local augments = core.readItem(player:findItem(ring))

        assert(augments == nil, 'a trial item must be left alone')
    end)

    it('refuses gear that carries augments the catalog did not make', function()
        -- Dual Wield +21 is not a bonus any tier hands out
        player:addItem({ id = ring, exdata = { augmentKind = xi.augment.kind.HAS_AUGMENTS, augmentSubKind = xi.augment.subKind.STANDARD, augments = { { id = 146, value = 20 } } } })

        assert(core.readItem(player:findItem(ring)) == nil, 'a foreign augment must be left alone')
    end)

    it('refuses things that are not weapons or armor', function()
        player:addItem(xi.item.POTION)

        local augments = core.readItem(player:findItem(xi.item.POTION))

        assert(augments == nil, 'a potion cannot be augmented')
    end)
end)
