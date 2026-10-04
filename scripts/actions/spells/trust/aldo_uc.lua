-----------------------------------
-- Trust: Aldo UC
-- Retail (BG Wiki BGWiki:Trusts): THF/NIN. Bully, then Sneak Attack (not combined with weapon skills).
-- Left out: Sarva's Storm, his only weapon skill (no skill row), Unity bonuses.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ALDO)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BULLY })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
