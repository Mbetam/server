-----------------------------------
-- Trust: Ingrid II
-- Retail (BG Wiki BGWiki:Trusts): WHM/WAR. Only casts to magic burst, with the Banish line / Holy; Cursna.
-- Spell levels come from her mob_spell_lists rows (they hand Banish III over to Holy II at 95).
-- Holds up to 2500 TP to close skillchains (Merciless Strike, Moonlight, Inexorable Strike, Ruthlessness: trust-unique
-- ones with estimated numbers). Left out: Self-Aggrandizement, Undead Killer.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

local burstSpells =
{
    { xi.magic.spell.HOLY_II, 95 },
    { xi.magic.spell.BANISH_III, 65, 89 },
    { xi.magic.spell.HOLY, 50, 94 },
    { xi.magic.spell.BANISH_II, 30, 64 },
    { xi.magic.spell.BANISH, 5, 29 },
}

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.INGRID)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    kit.onCombatTick(mob, 'INGRID_II_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'INGRID_II_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'INGRID_II_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
