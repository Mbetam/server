-----------------------------------
-- Trust: Romaa Mihgo
-- Retail (BG Wiki BGWiki:Trusts): THF/WAR. Feint; Sneak Attack and Trick Attack (not combined with weapon skills);
-- weapon skills as soon as she has TP (Fast Blade, Vorpal Blade, Savage Blade).
-- Left out: Aura Steal (no trust ability id), the positioning checks for Sneak / Trick Attack, Cobra Clamp (no script).
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
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.TRICK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRICK_ATTACK })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
