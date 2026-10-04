-----------------------------------
-- Trust: Robel-Akbel
-- Retail (BG Wiki BGWiki:Trusts): BLM/SMN. Avoids elements the target resists (here: the target's weakest element);
-- magic bursts skillchains with -aja spells; casts Stun in response to enemy TP moves; stands in place after
-- engaging. Weapon skills at 2000 TP, no skillchain attempts (Spirit Taker).
-- Null Blast too (estimated numbers). Left out: Quietus Sphere (no skill row), the "just enough tier to kill" choice, the Kayeel-Payeel and
-- Karaha-Baruha synergies.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: -aja first, then the strongest single-target spell of the element
local burstSpells =
{
    { xi.magic.spell.FIRAJA, 90 },
    { xi.magic.spell.BLIZZAJA, 93 },
    { xi.magic.spell.AEROJA, 87 },
    { xi.magic.spell.STONEJA, 81 },
    { xi.magic.spell.THUNDAJA, 87 },
    { xi.magic.spell.WATERJA, 84 },
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

    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.STONE_V }, 20)

    kit.onCombatTick(mob, 'ROBEL_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'ROBEL_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'ROBEL_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
