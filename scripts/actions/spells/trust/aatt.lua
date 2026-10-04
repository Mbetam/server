-----------------------------------
-- Trust: AATT
-- Retail (BG Wiki BGWiki:Trusts): BLM/DRK, HP+20%, MP+50%. Last Resort and Souleater whenever ready; keeps Poison and
-- Bio on the enemy; only uses elemental magic to magic burst, often trying two bursts on one skillchain; Aspir when
-- under 50% MP; Stun on enemy TP moves. Weapon skills at 2000 TP, no skillchain attempts (Guillotine, Amon Drive).
-- Left out: Sleepga / Sleep (retail opens with Sleepga and after every Amon Drive), Elemental Seal, the
-- "enemy has MP" check before Aspir.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: strongest single-target spell of the element
local burstSpells =
{
    { xi.magic.spell.FIRE_V, 86 },
    { xi.magic.spell.BLIZZARD_V, 89 },
    { xi.magic.spell.AERO_V, 83 },
    { xi.magic.spell.STONE_V, 77 },
    { xi.magic.spell.THUNDER_V, 92 },
    { xi.magic.spell.WATER_V, 80 },
    { xi.magic.spell.FIRE_IV, 73 },
    { xi.magic.spell.BLIZZARD_IV, 74 },
    { xi.magic.spell.AERO_IV, 72, 82 },
    { xi.magic.spell.STONE_IV, 68 },
    { xi.magic.spell.THUNDER_IV, 75 },
    { xi.magic.spell.WATER_IV, 70 },
    { xi.magic.spell.FIRE_III, 62 },
    { xi.magic.spell.BLIZZARD_III, 64 },
    { xi.magic.spell.AERO_III, 59 },
    { xi.magic.spell.STONE_III, 51 },
    { xi.magic.spell.THUNDER_III, 66 },
    { xi.magic.spell.WATER_III, 55 },
    { xi.magic.spell.FIRE_II, 38 },
    { xi.magic.spell.BLIZZARD_II, 42 },
    { xi.magic.spell.AERO_II, 34 },
    { xi.magic.spell.STONE_II, 26 },
    { xi.magic.spell.THUNDER_II, 46 },
    { xi.magic.spell.WATER_II, 30 },
    { xi.magic.spell.FIRE, 13 },
    { xi.magic.spell.BLIZZARD, 17 },
    { xi.magic.spell.AERO, 9 },
    { xi.magic.spell.STONE, 1 },
    { xi.magic.spell.THUNDER, 21 },
    { xi.magic.spell.WATER, 5 },
}

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

    mob:addMod(xi.mod.HPP, 20)
    mob:addMod(xi.mod.MPP, 50)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.LAST_RESORT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.LAST_RESORT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SOULEATER }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SOULEATER })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.POISON }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BIO }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BIO }, 30)
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, { ai.c.MPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ASPIR }, 30)

    kit.onCombatTick(mob, 'AATT_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 2)
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'AATT_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'AATT_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
