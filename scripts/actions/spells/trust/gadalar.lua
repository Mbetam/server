-----------------------------------
-- Trust: Gadalar
-- Retail (BG Wiki BGWiki:Trusts): BLM/BLM, MP+25%, Magic Attack Bonus+25. Keeps Blaze Spikes up and favours
-- Firaga III; recovers MP when hit; weapon skills as soon as he has TP (Spinning Scythe, Spiral Hell, Vorpal Scythe).
-- Left out: Salamander Flame (trust-unique, no mob skill script), Rughadjeen's +25 MAB synergy.
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

    mob:addMod(xi.mod.MPP, 25)
    mob:addMod(xi.mod.MATT, 25)
    mob:addMod(xi.mod.ABSORB_PHYSDMG_TO_MP, 5)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BLAZE_SPIKES }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLAZE_SPIKES })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FIRAGA })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
