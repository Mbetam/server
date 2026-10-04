-----------------------------------
-- Trust: Jakoh Wahcondalo UC
-- Retail (BG Wiki BGWiki:Trusts): THF/WAR. Opens with Feint and uses it on cooldown; Conspirator, Sneak Attack, Trick
-- Attack; weapon skills over 2000 TP (Dancing Edge, Evisceration).
-- Left out: Sarva's Storm (no skill row), waiting for Sneak / Trick Attack positioning, Unity bonuses.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FEINT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.CONSPIRATOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CONSPIRATOR })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.TRICK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRICK_ATTACK })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
