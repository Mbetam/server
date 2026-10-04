-----------------------------------
-- Trust: Rosulatia
-- Retail (BG Wiki BGWiki:Trusts): BLM/DRK, HP+30%, MP+100%. Casts only earth magic (Stone I-V) and stops casting while
-- she is at the top of the enmity list; no magic bursts.
-- Left out: her TP moves (Baneful Blades, Dryad Kiss, Matriarchal Fiat, Wildwood Indignation: trust-unique, no
-- scripts) and her special melee attacks.
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
    mob:addMod(xi.mod.MPP, 100)

    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.STONE }, 15)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
