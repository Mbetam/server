-----------------------------------
-- Trust: Aldo
-- Retail (BG Wiki BGWiki:Trusts): THF/NIN. Bully, then Sneak Attack (not combined with weapon skills); holds up to 2000
-- TP to close skillchains, using Assassin's Charge with the weapon skill when he can't (Lock and Load, Shockstorm Edge,
-- Iniquitous Stab, Choreographed Carnage: trust-unique, estimated numbers, see their mob skill scripts).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ALDO_UC)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BULLY })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ASSASSINS_CHARGE })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
