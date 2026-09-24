-----------------------------------
-- Apururu (UC), Yoran-Oran (UC), Monberaux and Koru-Moru checked against their retail behaviour (BG Wiki), summoned
-- for real next to a monster. Every spell, job ability and mob skill they use is recorded through the engine's own
-- listeners, together with who it was used on. Notes: docs/custom/NOTES.md (trust round 3).
-----------------------------------

describe('Healer and support trusts', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local used

    local function idOf(thing)
        if type(thing) == 'number' then
            return thing
        end

        return thing:getID()
    end

    -- used.spell[spellId] = { [targetId] = count }, the same for ability and skill
    local function record(kind, id, target)
        table.insert(used.seq, string.format('%s%d>%d', kind:sub(1, 1), id, target and target:getID() % 1000 or 0))
        used[kind][id] = used[kind][id] or {}
        local targetId = target and target:getID() or 0
        used[kind][id][targetId] = (used[kind][id][targetId] or 0) + 1
    end

    local function watch(trust)
        trust:addListener('MAGIC_USE', 'TEST_HEALER_MAGIC', function(entity, target, spell, action)
            record('spell', idOf(spell), target)
        end)
        trust:addListener('ABILITY_USE', 'TEST_HEALER_ABILITY', function(entity, target, ability, action)
            record('ability', idOf(ability), target)
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_HEALER_WS', function(entity, target, skill, tp, action, damage)
            record('skill', idOf(skill), target)
        end)
        trust:addListener('WEAPONSKILL_BEFORE_USE', 'TEST_HEALER_WS_TRY', function(entity, skillId)
            table.insert(used.seq, 'try' .. tostring(idOf(skillId)))
        end)
    end

    -- Summons the trusts in order and returns them in the same order
    local function summon(...)
        local trusts = {}

        for _, spellId in ipairs({ ... }) do
            local before = {}
            for _, member in ipairs(player:getPartyWithTrusts()) do
                before[member:getID()] = true
            end

            player:spawnTrust(spellId)
            xi.test.world:skipTime(2)

            local trust = nil
            for _, member in ipairs(player:getPartyWithTrusts()) do
                if member:isTrust() and not before[member:getID()] then
                    trust = member
                end
            end

            assert(trust, 'trust ' .. spellId .. ' was not summoned')
            watch(trust)
            table.insert(trusts, trust)
        end

        return unpack(trusts)
    end

    -- Fights for a number of seconds, one server tick per second. `each`, if given, runs every second (to keep
    -- someone hurt, low on MP, ...).
    local function fight(seconds, each)
        player.actions:engage(mob)

        for _ = 1, seconds do
            if each then
                each()
            end

            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
        end
    end

    local function usedOn(kind, ids, target)
        for _, id in ipairs(type(ids) == 'table' and ids or { ids }) do
            local targets = used[kind][id]

            if targets and (target == nil or targets[target:getID()]) then
                return true
            end
        end

        return false
    end

    local function dump()
        local parts = {}

        for kind, tbl in pairs(used) do
            for id, targets in pairs(kind ~= 'seq' and tbl or {}) do
                for targetId, n in pairs(targets) do
                    table.insert(parts, string.format('%s %d on %d x%d', kind, id, targetId, n))
                end
            end
        end

        table.sort(parts)

        return 'used: ' .. (#parts > 0 and table.concat(parts, ', ') or 'nothing') .. '. In order: ' .. table.concat(used.seq, ' ')
    end

    local spell = xi.magic.spell
    local cures = { spell.CURE, spell.CURE_II, spell.CURE_III, spell.CURE_IV, spell.CURE_V, spell.CURE_VI }
    local curagas = { spell.CURAGA, spell.CURAGA_II, spell.CURAGA_III, spell.CURAGA_IV, spell.CURAGA_V }
    local protectras = { spell.PROTECTRA, spell.PROTECTRA_II, spell.PROTECTRA_III, spell.PROTECTRA_IV, spell.PROTECTRA_V }
    local shellras = { spell.SHELLRA, spell.SHELLRA_II, spell.SHELLRA_III, spell.SHELLRA_IV, spell.SHELLRA_V }

    before_each(function()
        used = { spell = {}, ability = {}, skill = {}, seq = {} }

        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
        -- Trusts join once the master engages (the !trustengage option)
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    -----------------------------------
    -- Subjobs (retail main/sub from BG Wiki, sql/mob_pools.sql)
    -----------------------------------
    it('trusts are summoned with their retail subjob', function()
        local yoran, koru, gilgamesh = summon(spell.YORAN_ORAN_UC, spell.KORU_MORU, spell.GILGAMESH)

        assert(yoran:getSubJob() == xi.job.BLM, 'Yoran-Oran (UC) should be WHM/BLM, sub is ' .. yoran:getSubJob())
        assert(koru:getSubJob() == xi.job.WHM, 'Koru-Moru should be RDM/WHM, sub is ' .. koru:getSubJob())
        assert(gilgamesh:getSubJob() == xi.job.WAR, 'Gilgamesh should be SAM/WAR, sub is ' .. gilgamesh:getSubJob())
    end)

    -----------------------------------
    -- Apururu (UC)
    -----------------------------------
    it('Apururu (UC) keeps up Protectra, Shellra, Stoneskin and Haste on her master and herself, and cures', function()
        local apururu = summon(spell.APURURU_UC)

        fight(90)

        assert(usedOn('spell', protectras), 'no Protectra. ' .. dump())
        assert(usedOn('spell', shellras), 'no Shellra. ' .. dump())
        assert(usedOn('spell', spell.STONESKIN, apururu), 'no Stoneskin on herself. ' .. dump())
        assert(usedOn('spell', spell.HASTE, player), 'no Haste on her master. ' .. dump())
        assert(usedOn('spell', spell.HASTE, apururu), 'no Haste on herself. ' .. dump())

        player:setHP(player:getMaxHP() / 2)
        fight(10)

        assert(usedOn('spell', cures, player), 'no Cure on a master at 50% HP. ' .. dump())
    end)

    it('Apururu (UC) casts Curaga when 3 party members are under 75% HP, but not for just one', function()
        local apururu, shantotto = summon(spell.APURURU_UC, spell.SHANTOTTO)

        fight(30) -- buffs first

        player:setHP(player:getMaxHP() * 0.6)
        fight(10)
        assert(not usedOn('spell', curagas), 'Curaga for a single hurt member. ' .. dump())

        fight(20, function()
            apururu:setMP(apururu:getMaxMP()) -- the buffing and curing above can leave her out of MP
            for _, member in ipairs({ player, apururu, shantotto }) do
                if member:getHPP() >= 70 then
                    member:setHP(member:getMaxHP() * 0.6)
                end
            end
        end)

        assert(usedOn('spell', curagas), 'no Curaga with 3 members under 75% HP. ' .. dump())
    end)

    it('Apururu (UC) uses Devotion on a party member low on MP, never on one without MP', function()
        local apururu, shantotto = summon(spell.APURURU_UC, spell.SHANTOTTO)

        fight(30, function()
            shantotto:setMP(shantotto:getMaxMP() * 0.1)
        end)

        assert(usedOn('ability', xi.jobAbility.DEVOTION, shantotto), 'no Devotion on Shantotto at 10% MP. ' .. dump())
        assert(not usedOn('ability', xi.jobAbility.DEVOTION, player), 'Devotion on a WAR master who has no MP. ' .. dump())
    end)

    it('Apururu (UC) uses Convert and Martyr only at very low MP', function()
        local apururu = summon(spell.APURURU_UC)

        fight(20)
        assert(not usedOn('ability', { xi.jobAbility.CONVERT, xi.jobAbility.MARTYR }), 'Convert or Martyr with plenty of MP. ' .. dump())

        fight(30, function()
            apururu:setMP(apururu:getMaxMP() * 0.05)
            player:setHP(player:getMaxHP() * 0.3)
        end)

        assert(usedOn('ability', xi.jobAbility.CONVERT, apururu), 'no Convert at 5% MP. ' .. dump())
        assert(usedOn('ability', xi.jobAbility.MARTYR, player), 'no Martyr on a hurt master at 5% MP. ' .. dump())
    end)

    it('Apururu (UC) uses Nott to get MP back', function()
        local apururu = summon(spell.APURURU_UC)

        fight(40, function()
            if apururu:getMPP() >= 50 then
                apururu:setMP(apururu:getMaxMP() * 0.4)
            end
        end)

        assert(usedOn('skill', xi.mobSkill.NOTT), 'no Nott at 40% MP. ' .. dump())
    end)

    it('Apururu (UC) removes Poison and Paralysis', function()
        local apururu = summon(spell.APURURU_UC)

        fight(30)
        player:addStatusEffect(xi.effect.POISON, { power = 1, duration = 120, origin = mob })
        fight(10)
        player:addStatusEffect(xi.effect.PARALYSIS, { power = 20, duration = 120, origin = mob })
        fight(10)

        assert(usedOn('spell', spell.POISONA, player), 'no Poisona. ' .. dump())
        assert(usedOn('spell', spell.PARALYNA, player), 'no Paralyna. ' .. dump())
    end)

    -----------------------------------
    -- Protectra / Shellra spam (Eric, 2026-09-24): the -ra spells only reach members within 10 yalms of the caster,
    -- so a member out of range kept the healer casting them forever.
    -----------------------------------
    it('Kupipi does not spam Protectra/Shellra when a party member never gets them', function()
        summon(spell.KUPIPI)

        -- The master loses Protect and Shell every second, like a member standing out of the spell's range
        fight(90, function()
            player:delStatusEffect(xi.effect.PROTECT)
            player:delStatusEffect(xi.effect.SHELL)
        end)

        local function casts(ids)
            local n = 0

            for _, id in ipairs(ids) do
                for _, count in pairs(used.spell[id] or {}) do
                    n = n + count
                end
            end

            return n
        end

        assert(casts(protectras) >= 1, 'no Protectra at all. ' .. dump())
        assert(casts(protectras) <= 3, casts(protectras) .. ' Protectras in 90 s: still spamming. ' .. dump())
        assert(casts(shellras) <= 3, casts(shellras) .. ' Shellras in 90 s: still spamming. ' .. dump())
    end)

    -----------------------------------
    -- Yoran-Oran (UC)
    -----------------------------------
    it('Yoran-Oran (UC) uses Afflatus Solace, Protectra, Shellra, Stoneskin and cures', function()
        local yoran = summon(spell.YORAN_ORAN_UC)

        fight(90)

        assert(usedOn('ability', xi.jobAbility.AFFLATUS_SOLACE), 'no Afflatus Solace. ' .. dump())
        assert(usedOn('spell', protectras), 'no Protectra. ' .. dump())
        assert(usedOn('spell', shellras), 'no Shellra. ' .. dump())
        assert(usedOn('spell', spell.STONESKIN, yoran), 'no Stoneskin on himself. ' .. dump())

        player:setHP(player:getMaxHP() / 2)
        player:addStatusEffect(xi.effect.BLINDNESS, { power = 20, duration = 120, origin = mob })
        fight(16)

        assert(usedOn('spell', cures, player), 'no Cure on a master at 50% HP. ' .. dump())
        assert(usedOn('spell', spell.BLINDNA, player), 'no Blindna. ' .. dump())
    end)

    it('Yoran-Oran (UC) uses Nott to get MP back', function()
        local yoran = summon(spell.YORAN_ORAN_UC)

        fight(50, function()
            if yoran:getMPP() >= 50 then
                yoran:setMP(yoran:getMaxMP() * 0.4)
            end
        end)

        assert(usedOn('skill', xi.mobSkill.NOTT), 'no Nott at 40% MP. ' .. dump())
    end)

    -----------------------------------
    -- Monberaux
    -----------------------------------
    it('Monberaux uses Guard Drink and Life Water, and potions on a hurt master', function()
        summon(spell.MONBERAUX)

        fight(40)

        assert(usedOn('skill', 4255), 'no Mix: Guard Drink. ' .. dump())
        local info = {}
        for _, member in ipairs(player:getPartyWithTrusts()) do
            local effects = {}
            for _, e in ipairs(member:getStatusEffects()) do
                table.insert(effects, e:getEffectType())
            end
            table.insert(info, string.format('%d: tp %d engaged %s erasable %s action %d effects %s', member:getID() % 1000, member:getTP(), tostring(member:isEngaged()), tostring(member:hasStatusEffectByFlag(xi.effectFlag.ERASABLE)), member:getCurrentAction(), table.concat(effects, ',')))
        end
        assert(usedOn('skill', 4257), 'no Mix: Life Water (' .. table.concat(info, ' | ') .. '). ' .. dump())

        player:setHP(player:getMaxHP() * 0.3)
        fight(8)

        assert(usedOn('skill', { 4236, 4237 }, player), 'no Max. Potion / Mix: Max. Potion on a master at 30% HP. ' .. dump())
    end)

    it('Monberaux cures Poison and Curse with the single-target mixes', function()
        summon(spell.MONBERAUX)

        fight(20)
        player:addStatusEffect(xi.effect.POISON, { power = 1, duration = 120, origin = mob })
        fight(8)
        player:addStatusEffect(xi.effect.CURSE_I, { power = 10, duration = 120, origin = mob })
        fight(8)

        assert(usedOn('skill', 4246, player), 'no Mix: Antidote. ' .. dump())
        assert(usedOn('skill', 4250, player), 'no single-target Mix: Holy Water. ' .. dump())
        assert(player:getStatusEffect(xi.effect.CURSE_I) == nil, 'Curse is still on. ' .. dump())
    end)

    -----------------------------------
    -- Koru-Moru
    -----------------------------------
    it('Koru-Moru hastes the melee master, refreshes the caster, buffs and enfeebles', function()
        local koru, shantotto = summon(spell.KORU_MORU, spell.SHANTOTTO)

        fight(150)

        assert(usedOn('spell', { spell.HASTE, spell.HASTE_II }, player), 'no Haste on the WAR master. ' .. dump())
        assert(usedOn('spell', { spell.REFRESH, spell.REFRESH_II }, shantotto), 'no Refresh on Shantotto. ' .. dump())
        assert(not usedOn('spell', { spell.REFRESH, spell.REFRESH_II }, player), 'Refresh on a WAR. ' .. dump())
        assert(usedOn('spell', { spell.PROTECT, spell.PROTECT_II, spell.PROTECT_III, spell.PROTECT_IV, spell.PROTECT_V }), 'no Protect. ' .. dump())
        assert(usedOn('spell', { spell.SHELL, spell.SHELL_II, spell.SHELL_III, spell.SHELL_IV, spell.SHELL_V }), 'no Shell. ' .. dump())
        assert(usedOn('spell', { spell.DIA, spell.DIA_II, spell.DIA_III }, mob), 'no Dia. ' .. dump())
        assert(usedOn('spell', { spell.SLOW, spell.SLOW_II }, mob), 'no Slow. ' .. dump())
        local effects = {}
        for _, e in ipairs(mob:getStatusEffects()) do
            table.insert(effects, e:getEffectType())
        end
        assert(usedOn('spell', { spell.DISTRACT, spell.DISTRACT_II }, mob), 'no Distract (monster effects: ' .. table.concat(effects, ',') .. '). ' .. dump())
        assert(usedOn('spell', spell.PHALANX_II), 'no Phalanx II. ' .. dump())
    end)

    it('Koru-Moru dispels the monster and cures a master under 50% HP', function()
        summon(spell.KORU_MORU)

        fight(30)
        mob:addStatusEffect(xi.effect.PROTECT, { power = 50, duration = 300, origin = mob })
        player:setHP(player:getMaxHP() * 0.3)
        fight(16)

        assert(usedOn('spell', spell.DISPEL, mob), 'no Dispel on a monster with Protect. ' .. dump())
        assert(usedOn('spell', { spell.CURE, spell.CURE_II, spell.CURE_III, spell.CURE_IV }, player), 'no Cure on a master at 30% HP. ' .. dump())
    end)
end)
