-----------------------------------
-- Armor "fix it all" pass (docs/custom/NOTES.md, 2026-09-25): BRD song set, old +2 / Reforged set merges, the
-- "attack varies with HP" sets, SMN ward duration, pet TP bonus, and status-effect latents on Upgrader pieces.
-----------------------------------

describe('Armor effects, second pass', function()
    local config = require('modules/custom/lua/af_upgrade_config')
    local slots  = { xi.slot.HEAD, xi.slot.BODY, xi.slot.HANDS, xi.slot.LEGS, xi.slot.FEET }

    local function reforged(job, slot, index)
        return config.chains.empyrean[job][slot].reforged[index]
    end

    -- The old Empyrean +2 is the last item of the chain's base part
    local function oldPlus2(job, slot)
        local base = config.chains.empyrean[job][slot].base

        return base[#base]
    end

    -- Wears { { itemId, chainSlot }, ... } and runs the set check (equipItem from Lua does not)
    local function wear(player, pieces)
        for _, p in ipairs(pieces) do
            player:addItem(p[1])
            player:equipItem(p[1], nil, slots[p[2]])
        end

        xi.gear_sets.checkForGearSet(player)
    end

    it('BRD: an old Aoidos\' +2 and a Fili piece give AUGMENT_SONG_STAT 1, and Ballad now adds it as CHR', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.BRD, level = 99 })
        wear(player, { { oldPlus2('BRD', 1), 1 }, { reforged('BRD', 2, 4), 2 } })
        assert(player:getMod(xi.mod.AUGMENT_SONG_STAT) == 1, 'expected 1, got ' .. player:getMod(xi.mod.AUGMENT_SONG_STAT))

        local chr = player:getMod(xi.mod.CHR)
        player:addStatusEffect(xi.effect.BALLAD, { power = 1, duration = 60, origin = player, subPower = 4 })
        assert(player:getMod(xi.mod.CHR) == chr + 4, 'Ballad with subPower 4 should add 4 CHR')
        player:delStatusEffect(xi.effect.BALLAD)
        assert(player:getMod(xi.mod.CHR) == chr, 'CHR should return when Ballad wears off')
    end)

    it('old +2 and Reforged pieces now count as one set (1 + 1 used to give nothing)', function()
        local war = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
        wear(war, { { oldPlus2('WAR', 1), 1 }, { reforged('WAR', 2, 4), 2 } })
        assert(war:getMod(xi.mod.DA_DOUBLE_DMG_RATE) == 2, 'WAR Ravager +2 + Boii: got ' .. war:getMod(xi.mod.DA_DOUBLE_DMG_RATE))

        local dnc = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.DNC, level = 99 })
        wear(dnc, { { oldPlus2('DNC', 1), 1 }, { reforged('DNC', 2, 4), 2 } })
        assert(dnc:getMod(xi.mod.SAMBA_DOUBLE_DAMAGE) == 2, 'DNC Charis +2 + Maculele: got ' .. dnc:getMod(xi.mod.SAMBA_DOUBLE_DAMAGE))

        local blu = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.BLU, level = 99 })
        wear(blu, { { oldPlus2('BLU', 1), 1 }, { reforged('BLU', 2, 4), 2 } })
        assert(blu:getMod(xi.mod.AUGMENT_BLU_MAGIC) == 2, 'BLU Mavi +2 + Hashishin: got ' .. blu:getMod(xi.mod.AUGMENT_BLU_MAGIC))

        local war2 = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
        wear(war2, { { oldPlus2('WAR', 1), 1 }, { oldPlus2('WAR', 2), 2 }, { reforged('WAR', 3, 4), 3 } })
        assert(war2:getMod(xi.mod.DA_DOUBLE_DMG_RATE) == 3, '2 old + 1 Reforged should be the 3-piece value, got ' .. war2:getMod(xi.mod.DA_DOUBLE_DMG_RATE))
    end)

    it('DRK: set gives ATT_VARIES_WITH_HP 2; a proc raises damage by the HP percent', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.DRK, level = 99 })
        wear(player, { { oldPlus2('DRK', 1), 1 }, { reforged('DRK', 2, 4), 2 } })
        assert(player:getMod(xi.mod.ATT_VARIES_WITH_HP) == 2, 'expected 2, got ' .. player:getMod(xi.mod.ATT_VARIES_WITH_HP))

        player:addItem(xi.item.BRONZE_SWORD)
        player:equipItem(xi.item.BRONZE_SWORD, nil, xi.slot.MAIN)
        player:addMod(xi.mod.ATT_VARIES_WITH_HP, 98) -- certain

        player:setHP(player:getMaxHP())
        local full = player:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(full == 200, 'at 100% HP 100 damage should double, got ' .. full)

        player:setHP(math.floor(player:getMaxHP() / 2))
        local half = player:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(half >= 148 and half <= 150, 'at ~50% HP expected ~150, got ' .. half)
    end)

    it('pet sets boost the PET\'s hits by its HP percent, not the master\'s', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 99 })
        player:addItem(xi.item.ASH_CLUB)
        player:equipItem(xi.item.ASH_CLUB, nil, xi.slot.MAIN)
        player:addMod(xi.mod.ATT_VARIES_WITH_PET_HP, 100)

        local own = player:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(own == 100, 'the master\'s own hits should not change, got ' .. own)

        player:spawnPet(xi.petId.CARBUNCLE)
        xi.test.world:skipTime(2)
        local pet = player:getPet()
        assert(pet, 'no avatar')
        pet:setHP(pet:getMaxHP())
        local full = pet:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(full == 200, 'pet at full HP should double 100, got ' .. full)

        pet:setHP(math.floor(pet:getMaxHP() / 2))
        local half = pet:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(half >= 148 and half <= 150, 'pet at ~50% HP expected ~150, got ' .. half)

        player:delMod(xi.mod.ATT_VARIES_WITH_PET_HP, 100)
        pet:setHP(pet:getMaxHP())
        local off = pet:addDamageFromMultipliers(100, xi.physicalAttackType.NORMAL, xi.slot.MAIN, true)
        assert(off == 100, 'without the set the pet\'s damage should not change, got ' .. off)
    end)

    it('SMN: ward duration grows by the Blood Boon share; pets get the master\'s PET_TP_BONUS', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 99 })
        player:setLocalVar('[BloodBoon]SavedPermille', 500)
        assert(xi.job_utils.summoner.wardDuration(player, 180) == 270, 'expected 270')
        player:setLocalVar('[BloodBoon]SavedPermille', 0)
        assert(xi.job_utils.summoner.wardDuration(player, 180) == 180, 'expected 180 without a saving')

        player:spawnPet(xi.petId.CARBUNCLE)
        xi.test.world:skipTime(2)
        local pet  = player:getPet()
        local base = xi.mobskills.getTPBonus(pet)
        player:addMod(xi.mod.PET_TP_BONUS, 650)
        assert(xi.mobskills.getTPBonus(pet) == base + 650, 'pet TP bonus should include the master\'s 650')
    end)

    it('status-effect latents: Hattori Zukin +3 gives Double Attack +13 only under Innin', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.NIN, level = 99 })
        local zukin  = 23432 -- hattori_zukin_+3
        player:addItem(zukin)
        player:equipItem(zukin, nil, xi.slot.HEAD)

        local before = player:getMod(xi.mod.DOUBLE_ATTACK)
        player:addStatusEffect(xi.effect.INNIN, { power = 1, duration = 300, origin = player })
        local under = player:getMod(xi.mod.DOUBLE_ATTACK)
        player:delStatusEffect(xi.effect.INNIN)
        xi.test.world:skipTime(2) -- latents are rechecked on the next tick after an effect is removed

        assert(under == before + 13, string.format('Double Attack %d -> %d under Innin, expected +13', before, under))
        assert(player:getMod(xi.mod.DOUBLE_ATTACK) == before, 'Double Attack should drop back after Innin')
    end)
end)
