-----------------------------------
-- Bard trusts (Joachim, Ulmia; trust_song_kit) and the last melee trusts with no AI (Ark Angel MR / GK, Iron Eater,
-- Mildaurion), 2026-10-04. Songs are read off the master: effect, tier and singer (the effect's sub type).
-----------------------------------

describe('Bard trusts and the last melee trusts', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local used

    local function trustOf(spellId)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                return member
            end
        end
    end

    local function summon(spellId)
        player:spawnTrust(spellId)
        xi.test.world:skipTime(2)

        local trust = trustOf(spellId)
        assert(trust, 'the trust was not summoned')

        used = used or { spell = {}, ability = {}, skill = {} }
        trust:addListener('MAGIC_USE', 'TEST_BARD_MAGIC', function(entity, target, spell)
            used.spell[spell:getID()] = (used.spell[spell:getID()] or 0) + 1
        end)
        trust:addListener('ABILITY_USE', 'TEST_BARD_ABILITY', function(entity, target, ability)
            used.ability[ability:getID()] = (used.ability[ability:getID()] or 0) + 1
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_BARD_WS', function(entity, target, skill)
            local id = type(skill) == 'number' and skill or skill:getID()
            used.skill[id] = (used.skill[id] or 0) + 1
        end)

        return trust
    end

    local function fight(seconds)
        player.actions:engage(mob)

        for _ = 1, seconds / 2 do
            mob:addEnmity(player, 30000, 30000)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end
    end

    -- Songs from `singer` on the singer itself (always in its own song range; the master can be a few yalms too far):
    -- list of "effect:tier"
    local function songsFrom(singer)
        local list = {}

        for _, effect in ipairs(singer:getStatusEffects()) do
            local id = effect:getEffectType()

            if id >= xi.effect.REQUIEM and id <= xi.effect.NOCTURNE and effect:getSubType() == singer:getID() % 65536 then
                table.insert(list, id .. ':' .. effect:getTier())
            end
        end

        table.sort(list)

        return list
    end

    local function has(list, effect, tier)
        for _, s in ipairs(list) do
            if s == effect .. ':' .. tier then
                return true
            end
        end

        return false
    end

    local function dump()
        local parts = {}

        for kind, tbl in pairs(used) do
            for id, n in pairs(tbl) do
                table.insert(parts, string.format('%s %d x%d', kind, id, n))
            end
        end

        table.sort(parts)

        return 'used: ' .. (#parts > 0 and table.concat(parts, ', ') or 'nothing')
    end

    before_each(function()
        used = { spell = {}, ability = {}, skill = {} }
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    it('Joachim keeps Victory March and Blade Madrigal up, without recasting them in a loop', function()
        local joachim = summon(xi.magic.spell.JOACHIM)
        fight(50) -- songs take a while to sing

        local mine = songsFrom(joachim)
        local all  = {}
        for _, effect in ipairs(player:getStatusEffects()) do
            table.insert(all, string.format('%d:%d by %d', effect:getEffectType(), effect:getTier(), effect:getSubType()))
        end

        assert(has(mine, xi.effect.MARCH, 2), string.format('no Victory March from Joachim (%d): %s | all: %s | %s | Joachim HP %d%% MP %d%%',
            joachim:getID() % 65536, table.concat(mine, ', '), table.concat(all, ', '), dump(), joachim:getHPP(), joachim:getMPP()))
        assert(has(mine, xi.effect.MADRIGAL, 2), 'no Blade Madrigal from Joachim: ' .. table.concat(mine, ', '))

        fight(40)
        local songCasts = (used.spell[xi.magic.spell.VICTORY_MARCH] or 0) + (used.spell[xi.magic.spell.BLADE_MADRIGAL] or 0)
        assert(songCasts <= 3, 'recast his songs ' .. songCasts .. ' times in 90 s. ' .. dump())
    end)

    it('Ulmia keeps Victory and Advancing March up', function()
        local ulmia = summon(xi.magic.spell.ULMIA)
        fight(30)

        local mine = songsFrom(ulmia)
        assert(has(mine, xi.effect.MARCH, 2) and has(mine, xi.effect.MARCH, 1), 'not both Marches from Ulmia: ' .. table.concat(mine, ', '))
    end)

    it('With Ulmia singing the Marches, Joachim switches to Madrigal and Minuet', function()
        local ulmia = summon(xi.magic.spell.ULMIA)
        fight(40)
        assert(#songsFrom(ulmia) == 2, 'Ulmia did not put up her two songs first')

        local joachim = summon(xi.magic.spell.JOACHIM)
        fight(50)

        local mine = songsFrom(joachim)
        assert(not has(mine, xi.effect.MARCH, 2) and not has(mine, xi.effect.MARCH, 1), 'Joachim sang a March over Ulmia: ' .. table.concat(mine, ', '))
        assert(has(mine, xi.effect.MADRIGAL, 2), 'no Blade Madrigal from Joachim: ' .. table.concat(mine, ', '))
        assert(has(mine, xi.effect.MINUET, 5), 'no Valor Minuet V from Joachim: ' .. table.concat(mine, ', '))
    end)

    it('Ulmia sings a Ballad when the party runs low on MP', function()
        local ulmia = summon(xi.magic.spell.ULMIA)
        fight(40)

        -- Bards have no MP of their own and the master is a WAR: Kupipi is the party's only MP user; under 33% she
        -- needs a Ballad. One of Ulmia's Marches is removed to free a slot, as an expiring song would.
        player:spawnTrust(xi.magic.spell.KUPIPI)
        xi.test.world:skipTime(2)
        local kupipi = trustOf(xi.magic.spell.KUPIPI)
        kupipi:setMP(math.floor(kupipi:getMaxMP() * 0.2))
        ulmia:delStatusEffect(xi.effect.MARCH) -- free a slot (her songs are counted on herself), as an expiring song would

        fight(30)
        assert(has(songsFrom(ulmia), xi.effect.BALLAD, 3) or used.spell[xi.magic.spell.MAGES_BALLAD_III], 'no Ballad III. ' .. dump())
    end)

    it('Ark Angel MR uses Sneak Attack / Trick Attack and Calamity right after', function()
        local mr = summon(xi.magic.spell.AAMR)
        for _ = 1, 6 do
            mr:setTP(1500)
            fight(6)
        end

        assert(used.ability[xi.jobAbility.SNEAK_ATTACK] or used.ability[xi.jobAbility.TRICK_ATTACK], 'no Sneak / Trick Attack. ' .. dump())
        assert(used.skill[3716], 'no Calamity. ' .. dump())
    end)

    it('Ark Angel GK uses Hasso and Jump, and his weapon skills at 3000 TP', function()
        local gk = summon(xi.magic.spell.AAGK)
        fight(20)
        gk:setTP(3000)
        fight(10)

        assert(used.ability[xi.jobAbility.HASSO], 'no Hasso. ' .. dump())
        assert(used.ability[xi.jobAbility.JUMP], 'no Jump. ' .. dump())
        assert(used.skill[3722] or used.skill[3723] or used.skill[3724] or used.skill[3725] or used.skill[3726], 'no weapon skill. ' .. dump())
    end)

    it('Iron Eater uses Berserk and Restraint', function()
        summon(xi.magic.spell.IRON_EATER)
        fight(20)

        assert(used.ability[xi.jobAbility.BERSERK], 'no Berserk. ' .. dump())
        assert(used.ability[xi.jobAbility.RESTRAINT], 'no Restraint. ' .. dump())
    end)

    it('Mildaurion opens a skillchain once the player has 1500 TP', function()
        local mil = summon(xi.magic.spell.MILDAURION)
        fight(6)
        mil:setTP(2000)
        player:setTP(1500)
        fight(8)

        local any = false
        for _ in pairs(used.skill) do
            any = true
        end

        assert(any, 'no weapon skill with the player at 1500 TP. ' .. dump())
    end)

    it('the bards can be released mid-fight', function()
        summon(xi.magic.spell.ULMIA)
        summon(xi.magic.spell.JOACHIM)
        fight(8)
        player:clearTrusts()
        xi.test.world:skipTime(4)
    end)
end)
