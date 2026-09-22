-----------------------------------
-- Trust: Cid
-- Retail behaviour (BG Wiki BGWiki:Trusts): WAR/RNG. Saves up to 2500 TP waiting to close a skillchain; saves Berserk
-- (and Aggressor) until he is about to use a weapon skill.
-- Weapon skills (mob_skill_lists 1052): True Strike, Hexa Strike.
-- Not done: Fiery Tailings and Critical Mass (no mob skill scripts yet), his occasional ranged attacks.
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

    -- "About to weapon skill": once he has the TP for one
    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.BERSERK } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
