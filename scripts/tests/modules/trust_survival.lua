-----------------------------------
-- modules/custom/lua/trust_survival.lua: every trust summoned through xi.trust.spawn gets x2 max HP, -25% damage taken
-- and Regen of 1% of its max HP, once.
-----------------------------------

describe('Trust survival', function()
    local survival = xi.custom.trustSurvival

    local function trustOf(player, spellId)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                return member
            end
        end
    end

    -- Control: the trust summoned directly (not through xi.trust.spawn) has no bonus
    local function control(player, spellId)
        player:spawnTrust(spellId)
        xi.test.world:skipTime(2)

        local plain = trustOf(player, spellId)
        assert(plain, 'control trust did not spawn')

        local stats = { hp = plain:getMaxHP(), dmg = plain:getMod(xi.mod.DMG), regen = plain:getMod(xi.mod.REGEN) }
        player:clearTrusts()
        xi.test.world:skipTime(2)

        return stats
    end

    it('doubles max HP, cuts damage taken by 25% and adds Regen, once per trust', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 99 })
        local base   = control(player, xi.magic.spell.TRION)

        xi.trust.spawn(player, GetSpell(xi.magic.spell.TRION))
        xi.test.world:skipTime(2)

        local trion = trustOf(player, xi.magic.spell.TRION)
        assert(trion, 'Trion did not spawn')
        -- About double: the flat bonus is also scaled by any HP% the trust already has (Trion: x2.1)
        assert(math.abs(trion:getMaxHP() - 2 * base.hp) <= 0.1 * 2 * base.hp, string.format('max HP %d, expected about %d', trion:getMaxHP(), 2 * base.hp))
        assert(trion:getHP() == trion:getMaxHP(), 'Trion should start at full (doubled) HP')
        assert(trion:getMod(xi.mod.DMG) == base.dmg + survival.config.damage, 'damage taken bonus missing')
        assert(trion:getMod(xi.mod.REGEN) >= base.regen + math.floor(trion:getMaxHP() * 0.01), 'regen missing')

        local hp = trion:getMaxHP()
        xi.trust.spawn(player, GetSpell(xi.magic.spell.KUPIPI))
        xi.test.world:skipTime(2)
        assert(trion:getMaxHP() == hp, 'a second summon must not double Trion again')
        assert(trustOf(player, xi.magic.spell.KUPIPI):getLocalVar('[custom]TrustSurvival') == 1, 'Kupipi should have the bonus too')
    end)

    it('Trion survives a Tier 1 arena boss far longer than before (melee only, no healing)', function()
        local config = require('modules/custom/htbf/htbf_config')
        local arena  = xi.custom.htbfArena
        local boss   = config.bosses[1][1] -- Behemoth

        local function secondsAlive(summon)
            local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RNG, level = 99 })
            summon(player)
            xi.test.world:skipTime(2)

            local trion = trustOf(player, xi.magic.spell.TRION)
            local mob   = player:getZone():insertDynamicEntity(
            {
                objtype = xi.objType.MOB, name = 'TS_' .. boss.key, x = trion:getXPos() + 2, y = trion:getYPos(), z = trion:getZPos(), rotation = 0,
                groupId = boss.group[1], groupZoneId = boss.group[2], minLevel = config.tiers[1].level, maxLevel = config.tiers[1].level,
                releaseIdOnDisappear = true,
            })
            mob:setSpawn(trion:getXPos() + 2, trion:getYPos(), trion:getZPos(), 0)
            mob:spawn()
            arena.scale(mob, 1, boss)
            mob:setMobAbilityEnabled(false)
            mob:setMagicCastingEnabled(false)
            mob:updateEnmity(trion)

            local seconds = 0
            while trion:isAlive() and seconds < 120 do
                xi.test.world:skipTime(1)
                seconds = seconds + 1
            end

            DespawnMob(mob:getID())
            player:clearTrusts()
            xi.test.world:skipTime(2)

            return seconds
        end

        local before = secondsAlive(function(player) player:spawnTrust(xi.magic.spell.TRION) end)
        local after  = secondsAlive(function(player) xi.trust.spawn(player, GetSpell(xi.magic.spell.TRION)) end)

        assert(after >= 2 * before, string.format('Trion lasted %d s without the bonus and %d s with it', before, after))
    end)
end)
