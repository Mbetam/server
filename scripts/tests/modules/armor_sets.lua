-----------------------------------
-- Armor set bonuses for the Upgrader's gear (modules/custom/lua/armor_sets.lua): pieces added to LSB's own sets, and
-- new sets for effects the engine already supports.
-----------------------------------

describe('Armor set bonuses', function()
    local config = require('modules/custom/lua/af_upgrade_config')

    local function tier(family, job, slot, index)
        return config.chains[family][job][slot].reforged[index]
    end

    -- The set bonus alone: (both pieces) - (piece A alone) - (piece B alone) + (neither)
    local function setBonus(player, mod, a, slotA, b, slotB)
        player:addItem(a)
        player:addItem(b)

        -- In game the client's equip packet runs the set check after every change; equipItem from Lua does not
        local function recheck()
            xi.gear_sets.checkForGearSet(player)
        end

        local none = player:getMod(mod)
        player:equipItem(a, nil, slotA)
        recheck()
        local onlyA = player:getMod(mod)
        player:equipItem(b, nil, slotB)
        recheck()
        local both = player:getMod(mod)
        player:unequipItem(slotA)
        recheck()
        local onlyB = player:getMod(mod)

        return both - onlyA - onlyB + none
    end

    it('control: LSB\'s own AF set with two +3 pieces gives Accuracy +15', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })

        local bonus = setBonus(player, xi.mod.ACC, tier('af', 'WAR', 1, 4), xi.slot.HEAD, tier('af', 'WAR', 2, 4), xi.slot.BODY)
        assert(bonus == 15, 'two Pummeler\'s +3 pieces should add Accuracy +15, got ' .. bonus)
    end)

    it('Artifact +4 counts toward the AF +2/+3/+4 set (WAR: Accuracy +15 with 2 pieces)', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })

        local bonus = setBonus(player, xi.mod.ACC, tier('af', 'WAR', 1, 5), xi.slot.HEAD, tier('af', 'WAR', 2, 5), xi.slot.BODY)
        assert(bonus == 15, 'two Pummeler\'s +4 pieces should add a set bonus of Accuracy +15, got ' .. bonus)
    end)

    it('Empyrean Reforged +3 counts toward its set (WAR Boii: "Double Attack" double damage +2 with 2 pieces)', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })

        local bonus = setBonus(player, xi.mod.DA_DOUBLE_DMG_RATE, tier('empyrean', 'WAR', 1, 4), xi.slot.HEAD, tier('empyrean', 'WAR', 2, 4), xi.slot.BODY)
        assert(bonus == 2, 'two Boii +3 pieces should give the set bonus 2, got ' .. bonus)
    end)

    it('new DNC Maculele set: Samba double damage +2 with 2 pieces', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.DNC, level = 99 })

        local bonus = setBonus(player, xi.mod.SAMBA_DOUBLE_DAMAGE, tier('empyrean', 'DNC', 1, 1), xi.slot.HEAD, tier('empyrean', 'DNC', 2, 4), xi.slot.BODY)
        assert(bonus == 2, 'two Maculele pieces should give the set bonus 2, got ' .. bonus)
    end)

    it('new RUN Erilaz set: absorb damage chance +2 with 2 pieces', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.RUN, level = 99 })

        local bonus = setBonus(player, xi.mod.ABSORB_DMG_CHANCE, tier('empyrean', 'RUN', 1, 2), xi.slot.HEAD, tier('empyrean', 'RUN', 2, 3), xi.slot.BODY)
        assert(bonus == 2, 'two Erilaz pieces should give the set bonus 2, got ' .. bonus)
    end)
end)
