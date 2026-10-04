-----------------------------------
-- Trust: Mumor II
-- Retail (BG Wiki BGWiki:Trusts): BLM/DNC, HP+15%. Uses her highest-tier single-target nukes, avoiding elements the
-- target resists (here: its weakest element); runs out of MP quickly; casts Stun to interrupt enemy TP moves; stays
-- in melee range and attacks with her wands.
-- Left out: Firesday Night Fever (and the -ja bursts she only does under it) and all her TP moves (no mob skill rows).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.MUMOR)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 15)

    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.STONE_V }, 15)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
