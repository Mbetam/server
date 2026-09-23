-----------------------------------
-- Augment rules (modules/custom/lua/augment_core.lua) and the catalog (augment_config.lua).
-- Pure logic only: nothing here needs a player, a zone or the database.
-----------------------------------
local core   = require('modules/custom/lua/augment_core')
local config = core.config

-- The prices and amounts these tests were written against (see augment_test_tuning.lua)
require('scripts/tests/modules/augment_test_tuning').apply(core.config)
-----------------------------------

describe('Augment catalog', function()
    it('offers a bonus for every tier of every stat', function()
        for _, stat in ipairs(config.stats) do
            assert(#stat.amounts == #config.tiers, string.format('%s should have %d amounts', stat.key, #config.tiers))
        end
    end)

    it('never gives less at a higher tier', function()
        for _, stat in ipairs(config.stats) do
            for tier = 2, #stat.amounts do
                assert(stat.amounts[tier] >= stat.amounts[tier - 1], stat.key .. ' gives less at a higher tier')
            end
        end
    end)

    it('unlocks tiers at rising levels for rising prices', function()
        for tier = 2, #config.tiers do
            assert(config.tiers[tier].minLevel > config.tiers[tier - 1].minLevel, 'tier levels must rise')
            assert(config.tiers[tier].price > config.tiers[tier - 1].price, 'tier prices must rise')
        end
    end)

    it('gives every stat its own retail augment ids', function()
        local owner = {}

        for _, stat in ipairs(config.stats) do
            for _, range in ipairs(stat.ranges) do
                assert(owner[range.id] == nil, string.format('augment id %d is used by both %s and %s', range.id, tostring(owner[range.id]), stat.key))
                owner[range.id] = stat.key
            end
        end
    end)

    it('stores and reads back every stat at every tier', function()
        for _, stat in ipairs(config.stats) do
            for tier = 1, #config.tiers do
                local id, value, amount = core.encode(stat.key, tier)

                assert(id ~= nil, string.format('%s tier %d cannot be encoded: %s', stat.key, tier, tostring(value)))
                assert(value >= 0 and value <= 31, string.format('%s tier %d needs stored value %d, which does not fit in 5 bits', stat.key, tier, value))
                assert(amount == stat.amounts[tier], string.format('%s tier %d encoded the wrong bonus', stat.key, tier))

                local key, decodedAmount, decodedTier = core.decode(id, value)

                assert(key == stat.key, string.format('%s tier %d decoded as %s', stat.key, tier, tostring(key)))
                assert(decodedAmount == amount, string.format('%s tier %d decoded a bonus of %s', stat.key, tier, tostring(decodedAmount)))
                assert(decodedTier == core.effectiveTier(stat.key, tier), string.format('%s tier %d decoded as tier %s', stat.key, tier, tostring(decodedTier)))
            end
        end
    end)

    it('keeps the per-stat limit between one and the number of slots', function()
        assert(config.maxPerStat >= 1 and config.maxPerStat <= config.slotsPerItem, 'maxPerStat should be between 1 and ' .. config.slotsPerItem)
    end)

    it('spreads HP and MP over four retail ids', function()
        assert(select(1, core.encode('hp', 1)) == 1, 'HP +20 should use augment 1')
        assert(select(1, core.encode('hp', 2)) == 2, 'HP +40 should use augment 2')
        assert(select(1, core.encode('hp', 4)) == 3, 'HP +80 should use augment 3')
        assert(select(1, core.encode('mp', 4)) == 11, 'MP +80 should use augment 11')
    end)
end)

describe('Augment catalog against the game\'s own augment table', function()
    -- sql/augments.sql is what the server loads into its `augments` table. The catalog must use ids that really are
    -- a single stat, with the base and multiplier the game will apply, or an augment would grant something different
    -- from what the tables (and the player's client) say.
    local rows = {}

    setup(function()
        local file = io.open('sql/augments.sql', 'r')
        assert(file, 'could not open sql/augments.sql (tests must run from the repository root)')

        for line in file:lines() do
            local id, multiplier, modId, value, isPet = line:match('^INSERT INTO `augments` VALUES %((%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%d+),%d+%)')

            if id ~= nil and tonumber(isPet) == 0 then
                local id = tonumber(id)
                rows[id] = rows[id] or {}
                table.insert(rows[id], { multiplier = tonumber(multiplier), modId = tonumber(modId), value = tonumber(value) })
            end
        end

        file:close()
    end)

    it('uses ids that grant exactly the stats the catalog names (one, or both of a combined pair)', function()
        for _, stat in ipairs(config.stats) do
            local mods = type(stat.mod) == 'table' and stat.mod or { stat.mod }

            for _, range in ipairs(stat.ranges) do
                local found = rows[range.id]

                assert(found ~= nil, string.format('%s: augment id %d is not in sql/augments.sql', stat.key, range.id))
                assert(#found == #mods, string.format('%s: augment id %d grants %d stats, the catalog names %d', stat.key, range.id, #found, #mods))

                for _, name in ipairs(mods) do
                    assert(xi.mod[name] ~= nil, string.format('%s: %s is not a real mod', stat.key, name))

                    local present = false
                    for _, row in ipairs(found) do
                        present = present or row.modId == xi.mod[name]
                    end

                    assert(present, string.format('%s: augment id %d does not change %s (%d)', stat.key, range.id, name, xi.mod[name]))
                end
            end
        end
    end)

    it('uses the base value and multiplier the game applies', function()
        for _, stat in ipairs(config.stats) do
            local expectedMultiplier = stat.modPerPoint > 1 and stat.modPerPoint or 0

            for _, range in ipairs(stat.ranges) do
                -- every row: a combined augment must give its full base to both of its stats
                for _, found in ipairs(rows[range.id]) do
                    assert(found.value == range.base, string.format('%s: augment id %d has base %d in the game but the catalog says %d', stat.key, range.id, found.value, range.base))
                    assert(found.multiplier == expectedMultiplier, string.format('%s: augment id %d has multiplier %d in the game but the catalog expects %d', stat.key, range.id, found.multiplier, expectedMultiplier))
                end
            end
        end
    end)
end)

describe('Augment tiers', function()
    it('unlock at the configured main job levels', function()
        assert(core.tierForLevel(1) == 1)
        assert(core.tierForLevel(29) == 1)
        assert(core.tierForLevel(30) == 2)
        assert(core.tierForLevel(59) == 2)
        assert(core.tierForLevel(60) == 3)
        assert(core.tierForLevel(89) == 3)
        assert(core.tierForLevel(90) == 4)
        assert(core.tierForLevel(99) == 4)
    end)

    it('charge the lower tier when a higher one gives the same bonus', function()
        -- Triple Attack is +1, +1, +2, +2
        assert(core.effectiveTier('triple_attack', 1) == 1)
        assert(core.effectiveTier('triple_attack', 2) == 1, 'tier 2 Triple Attack is only +1, so it counts as tier 1')
        assert(core.effectiveTier('triple_attack', 3) == 3)
        assert(core.effectiveTier('triple_attack', 4) == 3, 'tier 4 Triple Attack is only +2, so it counts as tier 3')
        assert(core.effectiveTier('dual_wield', 2) == 2, 'a stat that rises every tier keeps its own tier')
    end)
end)

describe('Adding an augment', function()
    local function ctx(overrides)
        local base = { level = 99, gil = 10000000, augments = {}, key = 'dual_wield', tier = 1 }

        for name, value in pairs(overrides or {}) do
            base[name] = value
        end

        return base
    end

    it('returns what to store and what to charge', function()
        local ok, plan = core.checkAdd(ctx())

        assert(ok, 'a valid add was refused: ' .. tostring(plan))
        assert(plan.id == 146 and plan.value == 0 and plan.amount == 1, 'Dual Wield tier 1 should store augment 146 with value 0')
        assert(plan.price == 10000 and plan.tier == 1)
    end)

    it('charges the tier price', function()
        local _, plan = core.checkAdd(ctx({ key = 'dual_wield', tier = 4 }))

        assert(plan.price == 1000000 and plan.amount == 4 and plan.value == 3, 'Dual Wield tier 4 is +4 for 1,000,000')
    end)

    it('charges the lower tier price for a bonus a lower tier already gives', function()
        local ok, plan = core.checkAdd(ctx({ key = 'triple_attack', tier = 2, level = 30 }))

        assert(ok and plan.price == 10000 and plan.amount == 1, 'Triple Attack tier 2 is +1, so it should cost the tier 1 price')
    end)

    it('refuses a tier the player has not unlocked', function()
        local ok, message = core.checkAdd(ctx({ tier = 3, level = 59 }))

        assert(not ok and message:find('60', 1, true), 'tier 3 needs level 60: ' .. tostring(message))
    end)

    it('lets a player who has just unlocked a tier use it', function()
        assert(core.checkAdd(ctx({ tier = 3, level = 60 })), 'tier 3 should open at level 60')
    end)

    it('refuses when the player cannot afford it', function()
        local ok, message = core.checkAdd(ctx({ gil = 9999 }))

        assert(not ok and message:find('10000', 1, true), 'a 10,000 gil augment should be refused with 9,999 gil: ' .. tostring(message))
    end)

    it('takes the exact price when the player has exactly that much', function()
        assert(core.checkAdd(ctx({ gil = 10000 })), 'exactly enough gil should be enough')
    end)

    it('lets the same stat be stacked', function()
        local three = { { id = 146, value = 0 }, { id = 146, value = 0 }, { id = 146, value = 0 } }
        local ok, plan = core.checkAdd(ctx({ augments = three, key = 'dual_wield', tier = 1 }))

        assert(ok and plan.id == 146, 'a fourth Dual Wield should be allowed while stacking is on: ' .. tostring(plan))
    end)

    it('refuses a stat that has reached the per-stat limit', function()
        local original = config.maxPerStat
        config.maxPerStat = 2

        local two = { { id = 146, value = 0 }, { id = 146, value = 1 } }
        local ok, message = core.checkAdd(ctx({ augments = two, key = 'dual_wield', tier = 1 }))
        local other = core.checkAdd(ctx({ augments = two, key = 'double_attack', tier = 1 }))

        config.maxPerStat = original

        assert(not ok and message:find('2 times', 1, true), 'a third Dual Wield should be refused at a limit of 2: ' .. tostring(message))
        assert(other, 'a different stat should still be accepted')
    end)

    it('says the stat is already there when each stat may only be used once', function()
        local original = config.maxPerStat
        config.maxPerStat = 1

        local ok, message = core.checkAdd(ctx({ augments = { { id = 146, value = 0 } }, key = 'dual_wield', tier = 2 }))

        config.maxPerStat = original

        assert(not ok and message:find('already has that stat', 1, true), 'the once-per-stat rule should still work: ' .. tostring(message))
    end)

    it('counts every copy of a stat', function()
        local list = { { id = 146, value = 0 }, { id = 143, value = 0 }, { id = 146, value = 2 } }

        assert(core.countOf(list, 'dual_wield') == 2 and core.countOf(list, 'double_attack') == 1 and core.countOf(list, 'fast_cast') == 0)
    end)

    it('refuses when every slot is used', function()
        local full = { { id = 146, value = 0 }, { id = 143, value = 0 }, { id = 144, value = 0 }, { id = 41, value = 0 } }
        local ok, message = core.checkAdd(ctx({ augments = full, key = 'fast_cast' }))

        assert(not ok and message:find('slot', 1, true), 'a fifth augment should be refused: ' .. tostring(message))
    end)

    it('accepts the last free slot', function()
        local three = { { id = 146, value = 0 }, { id = 143, value = 0 }, { id = 144, value = 0 } }

        assert(core.checkAdd(ctx({ augments = three, key = 'fast_cast' })), 'the fourth augment should be accepted')
    end)

    it('refuses a stat or tier that does not exist', function()
        assert(not core.checkAdd(ctx({ key = 'movement_speed' })), 'unknown stat')
        assert(not core.checkAdd(ctx({ tier = 9 })), 'unknown tier')
    end)
end)

describe('Removing an augment', function()
    local augments = { { id = 146, value = 2 }, { id = 144, value = 0 } } -- Dual Wield +3 (tier 3), Triple Attack +1 (tier 1)

    it('costs the removal price times the tier', function()
        local ok, plan = core.checkRemove({ gil = 1000000, augments = augments, slot = 1 })

        assert(ok and plan.price == 15000 and plan.tier == 3 and plan.key == 'dual_wield', 'Dual Wield +3 is tier 3, so 15,000')
    end)

    it('charges the lower tier for a bonus that several tiers share', function()
        local ok, plan = core.checkRemove({ gil = 1000000, augments = augments, slot = 2 })

        assert(ok and plan.price == 5000 and plan.tier == 1, 'Triple Attack +1 counts as tier 1, so 5,000')
    end)

    it('refuses without enough gil', function()
        local ok = core.checkRemove({ gil = 14999, augments = augments, slot = 1 })

        assert(not ok, '15,000 gil is needed')
    end)

    it('refuses an empty slot', function()
        local ok, message = core.checkRemove({ gil = 1000000, augments = augments, slot = 3 })

        assert(not ok and message:find('no augment', 1, true), 'nothing to remove in slot 3: ' .. tostring(message))
    end)

    it('refuses an augment it does not recognise', function()
        local ok = core.checkRemove({ gil = 1000000, augments = { { id = 146, value = 20 } }, slot = 1 })

        assert(not ok, 'a +21 Dual Wield is not something this system made')
    end)
end)

describe('Building the new item', function()
    it('adds and removes without touching the original list', function()
        local original = { { id = 146, value = 0 }, { id = 143, value = 1 } }

        local added   = core.withAdded(original, 144, 0)
        local removed = core.withRemoved(original, 1)

        assert(#original == 2 and original[1].id == 146, 'the original list was changed')
        assert(#added == 3 and added[3].id == 144, 'the new augment should go last')
        assert(#removed == 1 and removed[1].id == 143, 'removing slot 1 should close the gap')
    end)

    it('describes the exdata for addItem', function()
        local exdata = core.buildExdata({ { id = 146, value = 2 } })

        assert(exdata.augmentKind == xi.augment.kind.HAS_AUGMENTS and exdata.augmentSubKind == xi.augment.subKind.STANDARD)
        assert(#exdata.augments == 1 and exdata.augments[1].id == 146 and exdata.augments[1].value == 2)
    end)

    it('gives back a plain item when no augments are left', function()
        assert(core.buildExdata({}) == nil, 'an item with no augments should carry no exdata')
    end)

    it('lists what an item carries', function()
        local lines = core.describe({ { id = 146, value = 2 }, { id = 144, value = 0 } })

        assert(#lines == 2)
        assert(lines[1].name == 'Dual Wield' and lines[1].amount == 3 and lines[1].unit == '')
        assert(lines[2].name == 'Triple Attack' and lines[2].amount == 1 and lines[2].unit == '%')
    end)
end)

describe('Reading an item', function()
    local function fakeItem(isGear, exdata)
        return {
            isType    = function(_, itemType) return isGear and (itemType == xi.itemType.ARMOR or itemType == xi.itemType.WEAPON) end,
            getExData = function() return exdata end,
        }
    end

    local function augmented(list, overrides)
        local exdata =
        {
            augmentKind    = xi.augment.kind.HAS_AUGMENTS,
            augmentSubKind = xi.augment.subKind.STANDARD,
            augments       = {},
            signature      = '',
        }

        for slot = 1, 5 do
            exdata.augments[slot] = list[slot] or { id = 0, value = 0 }
        end

        for name, value in pairs(overrides or {}) do
            exdata[name] = value
        end

        return exdata
    end

    it('refuses things that are not weapons or armor', function()
        local list, reason = core.readItem(fakeItem(false, {}))

        assert(list == nil and reason:find('weapons and armor', 1, true), 'a potion is not gear: ' .. tostring(reason))
    end)

    it('accepts a plain item with blank exdata', function()
        local list = core.readItem(fakeItem(true, { [0] = 0, [1] = 0, [2] = 0 }))

        assert(list ~= nil and #list == 0, 'blank gear should have no augments')
    end)

    it('refuses a plain item that carries other data', function()
        local list = core.readItem(fakeItem(true, { [0] = 0, [1] = 5, [2] = 0 }))

        assert(list == nil, 'an item with charges or similar should be left alone')
    end)

    it('accepts an item with augments made by this system', function()
        local list = core.readItem(fakeItem(true, augmented({ { id = 146, value = 2 }, { id = 143, value = 0 } })))

        assert(list ~= nil and #list == 2, 'two catalog augments should be accepted')
        assert(list[1].id == 146 and list[1].value == 2 and list[2].id == 143)
    end)

    it('accepts an augmented item whose augments were all removed', function()
        local list = core.readItem(fakeItem(true, augmented({})))

        assert(list ~= nil and #list == 0)
    end)

    it('refuses a bonus that is not one of the catalog amounts', function()
        local list = core.readItem(fakeItem(true, augmented({ { id = 146, value = 20 } })))

        assert(list == nil, 'a Dual Wield +21 did not come from this system')
    end)

    it('refuses an augment id that is not in the catalog', function()
        local list = core.readItem(fakeItem(true, augmented({ { id = 1500, value = 3 } })))

        assert(list == nil, 'an unknown augment should be left alone')
    end)

    it('refuses Magian trial items', function()
        local trial = augmented({ { id = 146, value = 2 } }, { augmentSubKind = xi.augment.subKind.STANDARD + xi.augment.subKind.TRIAL })

        assert(core.readItem(fakeItem(true, trial)) == nil, 'a trial item must not be touched')
    end)

    it('refuses bundled augments (Odyssey, Dyna-D)', function()
        local bundled = augmented({ { id = 146, value = 2 } }, { augmentKind = xi.augment.kind.BUNDLED })

        assert(core.readItem(fakeItem(true, bundled)) == nil, 'bundled augments must not be touched')
    end)

    it('refuses signed items', function()
        local signed = augmented({}, { signature = 'Somebody' })

        assert(core.readItem(fakeItem(true, signed)) == nil, 'a signed item must not be touched')
    end)

    it('refuses an item using more slots than the system allows', function()
        local five = augmented({ { id = 146, value = 0 }, { id = 143, value = 0 }, { id = 144, value = 0 }, { id = 41, value = 0 }, { id = 140, value = 0 } })

        assert(core.readItem(fakeItem(true, five)) == nil, 'a fifth used slot is beyond what this system manages')
    end)
end)

describe('Augmenter NPC look', function()
    it('is the same model the game gives its own Moogle NPCs', function()
        -- data/zones/lower_jeuno/npcs.yaml lists the zone's Moogle as `display_name: Moogle` then `model: <id>`
        local file = io.open('data/zones/lower_jeuno/npcs.yaml', 'r')
        assert(file, 'could not open the Lower Jeuno NPC data (tests must run from the repository root)')

        local sawMoogle = false
        local model     = nil

        for line in file:lines() do
            if line:match('display_name:%s+Moogle%s*$') then
                sawMoogle = true
            elseif sawMoogle and line:match('^%s+model:') then
                model = tonumber(line:match('model:%s*(%d+)'))

                break
            end
        end

        file:close()

        assert(model ~= nil, 'the game\'s own Moogle was not found in the Lower Jeuno NPC data')
        assert(config.npcModel == model, string.format('the Augmenter uses model %d but the game\'s Moogle uses model %d', config.npcModel, model))
    end)

    it('is not the blank placeholder model', function()
        -- docs/model_ids.txt lists `<id>    <name>`, and a model with no appearance is listed as `*` (the Auction Counters use one, and are invisible)
        local file = io.open('docs/model_ids.txt', 'r')
        assert(file, 'could not open docs/model_ids.txt (tests must run from the repository root)')

        local name = nil

        for line in file:lines() do
            local id, label = line:match('^%s*(%d+)%s+(.-)%s*$')

            if tonumber(id) == config.npcModel then
                name = label

                break
            end
        end

        file:close()

        assert(name ~= nil, 'model ' .. config.npcModel .. ' is not in docs/model_ids.txt')
        assert(name ~= '*', 'model ' .. config.npcModel .. ' is a blank placeholder, so the NPC would be invisible')
    end)
end)

describe('Combined and retired stats (2026-09-23)', function()
    local function fakeItem(list)
        local exdata =
        {
            augmentKind    = xi.augment.kind.HAS_AUGMENTS,
            augmentSubKind = xi.augment.subKind.STANDARD,
            augments       = {},
            signature      = '',
        }

        for slot = 1, 5 do
            exdata.augments[slot] = list[slot] or { id = 0, value = 0 }
        end

        return {
            isType    = function(_, itemType) return itemType == xi.itemType.ARMOR or itemType == xi.itemType.WEAPON end,
            getExData = function() return exdata end,
        }
    end

    it('stores each combined stat under its retail two-stat augment id', function()
        local cases = { acc_att = 68, racc_ratt = 69, macc_matt = 131 }

        for key, expectedId in pairs(cases) do
            for tier = 1, #config.tiers do
                local id, value, amount = core.encode(key, tier)

                assert(id == expectedId, string.format('%s tier %d should use augment %d, got %s', key, tier, expectedId, tostring(id)))
                assert(amount == core.stat(key).amounts[tier] and value == amount - 1)

                local decodedKey, decodedAmount, decodedTier = core.decode(id, value)
                assert(decodedKey == key and decodedAmount == amount and decodedTier == tier, key .. ' does not decode back to itself')
            end
        end
    end)

    it('uses the +33 id for a combined magic bonus above 32', function()
        assert(core.stat('macc_matt').ranges[2].id == 70 and core.stat('macc_matt').ranges[2].base == 33)
    end)

    it('never lets a retired stat be added', function()
        for _, key in ipairs({ 'accuracy', 'attack', 'magic_accuracy', 'magic_attack' }) do
            assert(core.stat(key) ~= nil and core.stat(key).retired, key .. ' should still be in the catalog, marked retired')

            local ok, reason = core.checkAdd({ level = 99, gil = 10000000, augments = {}, key = key, tier = 1 })
            assert(not ok and reason == 'That stat is not available.', key .. ' could still be added')
        end
    end)

    it('still reads, names and removes augments of a retired stat already on gear', function()
        -- A real item on prod at the time: Attack +10, Accuracy +10, Attack +10, Accuracy +10 (all four slots)
        local list = core.readItem(fakeItem({ { id = 25, value = 9 }, { id = 23, value = 9 }, { id = 25, value = 9 }, { id = 23, value = 9 } }))

        assert(list ~= nil and #list == 4, 'an item carrying retired augments must still be accepted by the NPC')

        local lines = core.describe(list)
        assert(lines[1].name == 'Attack' and lines[1].amount == 10, 'a retired augment should still show by name: ' .. tostring(lines[1].name))
        assert(lines[2].name == 'Accuracy' and lines[2].amount == 10)

        local ok, plan = core.checkRemove({ gil = 10000000, augments = list, slot = 1 })
        assert(ok and plan.key == 'attack' and plan.tier == 2, 'a retired augment must still be removable')
    end)

    it('offers the three combined stats and none of the retired ones', function()
        local offered = {}
        for _, stat in ipairs(config.stats) do
            if not stat.retired then
                offered[stat.key] = true
            end
        end

        assert(offered.acc_att and offered.racc_ratt and offered.macc_matt)
        assert(not offered.accuracy and not offered.attack and not offered.magic_accuracy and not offered.magic_attack)
    end)
end)
