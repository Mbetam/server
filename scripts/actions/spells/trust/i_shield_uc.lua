-----------------------------------
-- Trust: Invincible Shield UC
-- Retail (BG Wiki BGWiki:Trusts): WAR/COR, Damage Taken -20%. A damage dealer who Provokes: Provoke, Aggressor,
-- Restraint, Retaliation, Warcry, then Blood Rage once Warcry ends; holds up to 1500 TP for skillchains (Raging Rush,
-- Steel Cyclone). Left out: Soturi's Fury (no skill row), Tomahawk, Savagery. Unity HP bonus at its maximum.
-- Note: his mob_pools spell list (367) is a white mage list; he casts nothing in retail, so it is not used.
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

    mob:addMod(xi.mod.DMG, -2000)
    mob:addMod(xi.mod.HPP, 30) -- BG Wiki: HP+20% to +30% by Unity rank; the maximum (no ranking system yet)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RESTRAINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RETALIATION }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RETALIATION })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    mob:addGambit(ai.t.SELF, { { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.c.JA_ON_COOLDOWN, xi.ja.WARCRY }, { ai.c.NOT_STATUS, xi.effect.BLOOD_RAGE } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BLOOD_RAGE })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
