-----------------------------------
-- Trust: Balamor
-- Retail (BG Wiki BGWiki:Trusts): DRK/BLM, HP+40%, MP+100%. Casts the Absorb-STAT spells.
-- TP moves at random (Feast of Arrows, Last Laugh, Regurgitated Swarm, Setting the Stage: trust-unique, estimated
-- numbers). Left out: his dark-magic melee and the undead traits (cure damage, drain immunity).
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

    mob:addMod(xi.mod.HPP, 40)
    mob:addMod(xi.mod.MPP, 100)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_STR }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_DEX }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_VIT }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_AGI }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_INT }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_MND }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_CHR }, 60)

    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
