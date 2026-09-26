-----------------------------------
-- Job-audit fixes (docs/custom/NOTES.md, 2026-09-25): BRD Carol II, DRK Endark II, SCH Animus Augeo / Minuo /
-- Adloquium and Libra, RNG Hover Shot. Each is used for real.
-----------------------------------

describe('Job fixes', function()
    local function spawn(job, zone)
        local player = xi.test.world:spawnPlayer({ zone = zone or xi.zone.GM_HOME, job = job, level = 99 })
        player:setMP(player:getMaxMP())

        return player
    end

    local function cast(player, target, spellId)
        player:addSpell(spellId)
        player:resetRecasts()
        player.actions:useSpell(target, spellId)

        for _ = 1, 10 do
            xi.test.world:skipTime(1)
        end
    end

    it('Fire Carol II gives +100 fire resistance and 15% fire nullify, and stacks with Fire Carol', function()
        local player = spawn(xi.job.BRD)
        player:capSkill(xi.skill.SINGING)
        player:addMod(xi.mod.MAXIMUM_SONGS_BONUS, 1) -- no instrument means one song; this test needs two
        local meva, null = player:getMod(xi.mod.FIRE_MEVA), player:getMod(xi.mod.FIRE_NULL)

        cast(player, player, xi.magic.spell.FIRE_CAROL_II)
        assert(player:getMod(xi.mod.FIRE_MEVA) == meva + 100, string.format('fire MEVA %d -> %d, expected +100', meva, player:getMod(xi.mod.FIRE_MEVA)))
        assert(player:getMod(xi.mod.FIRE_NULL) == null + 15, 'fire nullify should be +15, is ' .. player:getMod(xi.mod.FIRE_NULL))

        local withII = player:getMod(xi.mod.FIRE_MEVA)
        cast(player, player, xi.magic.spell.FIRE_CAROL)
        assert(player:getMod(xi.mod.FIRE_MEVA) > withII, 'Fire Carol should stack on top of Fire Carol II')
        assert(player:getMod(xi.mod.FIRE_NULL) == null + 15, 'Carol I must not remove Carol II')
    end)

    it('Endark II gives Endark with the BG Wiki potency', function()
        local player = spawn(xi.job.DRK)
        player:capSkill(xi.skill.DARK_MAGIC)
        cast(player, player, xi.magic.spell.ENDARK_II)

        local skill    = player:getSkillLevel(xi.skill.DARK_MAGIC)
        local expected = skill >= 500 and math.floor((math.floor((skill + 2) * 5 / 66) + 7) * 2.5) or math.floor(math.floor((skill + 400) / 20) * 2.5)
        local effect   = player:getStatusEffect(xi.effect.ENDARK)

        assert(effect, 'no Endark effect')
        assert(effect:getPower() == expected, string.format('power %d, expected %d (skill %d)', effect:getPower(), expected, skill))
    end)

    it('SCH: Animus Augeo +20 enmity, Animus Minuo -10 enmity, Adloquium Regain 10', function()
        local player = spawn(xi.job.SCH)
        player:capSkill(xi.skill.ENHANCING_MAGIC)

        local enmity = player:getMod(xi.mod.ENMITY)
        cast(player, player, xi.magic.spell.ANIMUS_AUGEO)
        assert(player:getMod(xi.mod.ENMITY) == enmity + 20, 'Animus Augeo')
        player:delStatusEffect(xi.effect.ENMITY_BOOST)

        cast(player, player, xi.magic.spell.ANIMUS_MINUO)
        assert(player:getMod(xi.mod.ENMITY) == enmity - 10, 'Animus Minuo')

        local regain = player:getMod(xi.mod.REGAIN)
        cast(player, player, xi.magic.spell.ADLOQUIUM)
        assert(player:getMod(xi.mod.REGAIN) == regain + 10, 'Adloquium')
    end)

    it('Libra is refused without enmity and works with it', function()
        local player = spawn(xi.job.SCH, xi.zone.WEST_RONFAURE)
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        player:setPos(mob:getXPos() + 2, mob:getYPos(), mob:getZPos())

        local libra = require('scripts/actions/abilities/libra')
        assert(libra.onAbilityCheck(player, mob, nil) ~= 0, 'Libra should be refused when nobody is on the hate list')

        mob:addEnmity(player, 100, 100)
        assert(libra.onAbilityCheck(player, mob, nil) == 0, 'Libra should be allowed with enmity')
        libra.onUseAbility(player, mob, nil) -- prints the enmity table; must not error
    end)

    it('Hover Shot: stacks rise when shooting from a new spot and reset from the same spot', function()
        local player = spawn(xi.job.RNG, xi.zone.WEST_RONFAURE)
        local mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        mob:setMaxHP(5000)
        mob:setHP(5000)

        local racc = player:getMod(xi.mod.RACC)
        player.actions:useAbility(player, 395) -- Hover Shot (client id 395)
        xi.test.world:skipTime(2)
        assert(player:hasStatusEffect(xi.effect.HOVER_SHOT), 'no Hover Shot effect')

        -- Drive the stack logic as each completed ranged attack does (the RANGED_ATTACK listener)
        local shoot = function(x)
            player:setPos(x, mob:getYPos(), mob:getZPos())
            xi.job_utils.ranger.onHoverShotAttack(player, mob)
        end

        shoot(mob:getXPos() + 10)
        shoot(mob:getXPos() + 12)
        shoot(mob:getXPos() + 14)
        assert(player:getStatusEffect(xi.effect.HOVER_SHOT):getPower() == 3, 'expected 3 stacks, got ' .. player:getStatusEffect(xi.effect.HOVER_SHOT):getPower())
        assert(player:getMod(xi.mod.RACC) == racc + 12, 'Ranged Accuracy should be +12 at 3 stacks')
        assert(player:getMod(xi.mod.TRUE_SHOT_EFFECT) == 12, 'ranged damage should be +12% at 3 stacks')

        shoot(mob:getXPos() + 14) -- same spot
        assert(player:getStatusEffect(xi.effect.HOVER_SHOT):getPower() == 1, 'same spot should reset to 1')
    end)

    it('Asylum (WHM) and Decoy Shot (RNG) are self buffs again (job_fixes.sql target fix)', function()
        local whm = spawn(xi.job.WHM)
        whm.actions:useAbility(whm, 325)
        xi.test.world:skipTime(3)
        assert(whm:hasStatusEffect(xi.effect.ASYLUM), 'Asylum should buff the White Mage')

        local rng = spawn(xi.job.RNG)
        rng.actions:useAbility(rng, 286)
        xi.test.world:skipTime(3)
        assert(rng:hasStatusEffect(xi.effect.DECOY_SHOT), 'Decoy Shot should buff the Ranger')
    end)

    it('Caper Emissarius hands the Scholar\'s enmity to the party member', function()
        local sch   = spawn(xi.job.SCH, xi.zone.WEST_RONFAURE)
        local other = spawn(xi.job.WAR, xi.zone.WEST_RONFAURE)
        local mob   = sch.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
        sch:setPos(mob:getXPos() + 2, mob:getYPos(), mob:getZPos())
        other:setPos(mob:getXPos() + 3, mob:getYPos(), mob:getZPos())

        sch.actions:inviteToParty(other)
        other.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        mob:addEnmity(sch, 1000, 1000)
        sch.actions:useAbility(other, 342)
        xi.test.world:skipTime(3)

        assert(mob:getCE(other) > mob:getCE(sch), string.format('CE scholar %d, party member %d', mob:getCE(sch), mob:getCE(other)))
    end)
end)
