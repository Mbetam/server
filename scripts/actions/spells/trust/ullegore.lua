-----------------------------------
-- Trust: Ullegore
-- Retail (BG Wiki BGWiki:Trusts): BLM/DRK, HP+30%, MP+300% (about 5000 MP at i119). Single-target nukes I-V and
-- Comet; casts Stun to interrupt enemy TP moves. TP moves Envoutement, Memento Mori (magic attack boost) and Silence
-- Seal. Nukes go for the target's weakest element (retail: not documented which he picks).
-- Bored to Tears (Slow) too (estimated). Left out: "Memento Mori right before Comet" (Comet is on a 60 s gambit instead).
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

    mob:addMod(xi.mod.HPP, 30)
    mob:addMod(xi.mod.MPP, 300)

    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.COMET }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.STONE_V }, 20)

    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
