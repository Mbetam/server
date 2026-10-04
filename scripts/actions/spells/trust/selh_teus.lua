-----------------------------------
-- Trust: Selh'teus
-- Retail (BG Wiki BGWiki:Trusts): PLD/SAM, Regain 50, MP+100% (unused). Rejuvenation (restores HP, MP and TP to the
-- party) when the player drops to yellow HP or is asleep, every 30 s at most; otherwise holds TP to 3000 for
-- skillchains (Luminous Lance, Revelation). Does not move into range on his own.
-- Left out: nothing scripted beyond that (he uses no Paladin abilities in retail either).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local REJUVENATION = 3622

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.REGAIN, 50)
    mob:addMod(xi.mod.MPP, 100)

    -- Rejuvenation: the condition is on the master, the skill is self-targeted (it restores the party), so it runs from
    -- COMBAT_TICK. At most every 30 s (GetSystemTime: a cooldown measured in real time).
    mob:addListener('COMBAT_TICK', 'SELHTEUS_REJUVENATION', function(mobArg)
        local master = mobArg:getMaster()
        local now    = GetSystemTime()

        if
            master and
            master:isAlive() and
            (master:getHPP() < 75 or master:hasStatusEffect(xi.effect.SLEEP_I) or master:hasStatusEffect(xi.effect.SLEEP_II)) and
            now >= mobArg:getLocalVar('[Selhteus]NextRejuvenation')
        then
            mobArg:setLocalVar('[Selhteus]NextRejuvenation', now + 30)
            mobArg:useMobAbility(REJUVENATION)
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    mob:removeListener('SELHTEUS_REJUVENATION')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    mob:removeListener('SELHTEUS_REJUVENATION')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
