-----------------------------------
-- Empyrean set effects that needed engine support (modules/custom/lua/armor_sets.lua, magic_state.cpp,
-- damage_spell.lua, summoner.lua): BLM "Augments Conserve MP", GEO "MP not depleted", SMN "Augments Blood Boon".
-----------------------------------

describe('Empyrean set effects', function()
    local config = require('modules/custom/lua/af_upgrade_config')

    local function piece(job, slot, index)
        return config.chains.empyrean[job][slot].reforged[index]
    end

    -- Wears two pieces and returns the value of the set's modifier (the pieces themselves do not carry it)
    local function setValue(player, mod, a, b)
        player:addItem(a)
        player:addItem(b)
        player:equipItem(a, nil, xi.slot.HEAD)
        player:equipItem(b, nil, xi.slot.BODY)
        xi.gear_sets.checkForGearSet(player) -- the client's equip packet does this in game

        return player:getMod(mod)
    end

    local function castAndWait(player, target, spellId)
        player.actions:useSpell(target, spellId)

        for _ = 1, 10 do
            xi.test.world:skipTime(1)
        end
    end

    it('the new sets give their chance with 2 pieces (BLM 10, GEO 2, SMN 2)', function()
        local blm = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.BLM, level = 99 })
        local geo = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.GEO, level = 99 })
        local smn = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.SMN, level = 99 })

        assert(setValue(blm, xi.mod.AUGMENT_CONSERVE_MP, piece('BLM', 1, 1), piece('BLM', 2, 4)) == 10, 'BLM Wicce set should give 10')
        assert(setValue(geo, xi.mod.GEOMANCY_MP_NO_DEPLETE, piece('GEO', 1, 1), piece('GEO', 2, 4)) == 2, 'GEO Azimuth set should give 2')
        assert(setValue(smn, xi.mod.AUGMENT_BLOOD_BOON, piece('SMN', 1, 1), piece('SMN', 2, 4)) == 2, 'SMN Beckoner\'s set should give 2')
    end)

    it('GEO: with the effect certain, a Geomancy spell costs no MP (and does without it)', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.GEO, level = 99 })
        player:addSpell(xi.magic.spell.INDI_REGEN)

        player:setMP(player:getMaxMP())
        castAndWait(player, player, xi.magic.spell.INDI_REGEN)
        assert(player:getMP() < player:getMaxMP(), 'control: Indi-Regen should cost MP without the set')

        player:addMod(xi.mod.GEOMANCY_MP_NO_DEPLETE, 100)
        player:setMP(player:getMaxMP())
        castAndWait(player, player, xi.magic.spell.INDI_REGEN)
        assert(player:getMP() == player:getMaxMP(), 'with the set effect certain, Indi-Regen cost ' .. (player:getMaxMP() - player:getMP()) .. ' MP')
    end)

    it('BLM: when Conserve MP and the set proc, the saved share is recorded for the damage (and not without the set)', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLM, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        player:setPos(mob:getXPos() + 3, mob:getYPos(), mob:getZPos())
        player:addSpell(xi.magic.spell.FIRE)
        player:addMod(xi.mod.CONSERVE_MP, 100)

        player:setMP(player:getMaxMP())
        castAndWait(player, mob, xi.magic.spell.FIRE)
        assert(player:getLocalVar('[ConserveMP]SavedPermille') == 0, 'recorded a share without the set')

        player:addMod(xi.mod.AUGMENT_CONSERVE_MP, 100)
        player:setMP(player:getMaxMP())
        castAndWait(player, mob, xi.magic.spell.FIRE)

        local permille = player:getLocalVar('[ConserveMP]SavedPermille')
        assert(permille > 0 and permille <= 500, 'expected a saved share between 0 and 50%, got ' .. permille .. ' permille')
    end)

    it('RDM: 2 Lethargy pieces give +10; with Composure, enhancing on others and enfeebling last longer (not on self)', function()
        local rdm   = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RDM, level = 99 })
        local other = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        local mob   = rdm.entities:moveTo('Wild_Rabbit')
        mob:respawn()

        assert(setValue(rdm, xi.mod.AUGMENT_COMPOSURE, piece('RDM', 1, 1), piece('RDM', 2, 4)) == 10, 'RDM Lethargy set should give 10')
        rdm:delMod(xi.mod.AUGMENT_COMPOSURE, 10) -- measure the effect with a known value instead
        rdm:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = 600, origin = rdm })

        local haste = GetSpell(xi.magic.spell.HASTE)
        local function hasteOn(target)
            return xi.spells.enhancing.calculateEnhancingDuration(rdm, target, haste, xi.magic.spell.HASTE, xi.magic.spellGroup.WHITE, xi.effect.HASTE)
        end
        local function paralyze()
            return xi.spells.enfeebling.calculateDuration(rdm, mob, xi.magic.spell.PARALYZE, xi.effect.PARALYSIS, xi.skill.ENFEEBLING_MAGIC)
        end

        local otherBefore, selfBefore, paraBefore = hasteOn(other), hasteOn(rdm), paralyze()
        rdm:addMod(xi.mod.AUGMENT_COMPOSURE, 50)

        assert(math.abs(hasteOn(other) - otherBefore * 1.5) <= 1, string.format('Haste on another: %d -> %d, expected x1.5', otherBefore, hasteOn(other)))
        assert(hasteOn(rdm) == selfBefore, 'Haste on self should not change')
        assert(math.abs(paralyze() - paraBefore * 1.5) <= 1, string.format('Paralyze: %d -> %d, expected x1.5', paraBefore, paralyze()))
    end)

    it('SMN: a recorded Blood Boon saving raises the avatar\'s pact damage by that share', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()

        player:spawnPet(xi.petId.CARBUNCLE)
        xi.test.world:skipTime(2)
        local pet = player:getPet()
        assert(pet, 'no avatar')

        player:setLocalVar('[BloodBoon]SavedPermille', 500)
        local boosted = { damage = 100, hitsLanded = 1 }
        xi.mobskills.processDamage(pet, mob, nil, nil, boosted)
        assert(boosted.damage == 150, 'with 50% saved, 100 damage should become 150, got ' .. boosted.damage)

        player:setLocalVar('[BloodBoon]SavedPermille', 0)
        local plain = { damage = 100, hitsLanded = 1 }
        xi.mobskills.processDamage(pet, mob, nil, nil, plain)
        assert(plain.damage == 100, 'without a saving the damage changed to ' .. plain.damage)
    end)
end)
