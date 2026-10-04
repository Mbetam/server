-----------------------------------
-- Trust: Kayeel-Payeel
-- Retail (BG Wiki BGWiki:Trusts): BLM/SMN with a very high Fast Cast. Only ice and lightning spells, whatever the target
-- is weak to; tries to magic burst; burns MP fast with Freeze II / Burst II and -aja spells. Does not engage, but hits
-- with his staff if the enemy is close. Weapon skills at 1500 TP, no skillchain attempts (Gate of Tartarus, Tartarus
-- Torpor, Sunburst). Left out: Gate of Tartarus aftermath Refresh, Robel-Akbel's fast cast synergy.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: strongest first (ice and lightning only)
local burstSpells =
{
    { xi.magic.spell.FREEZE_II, 75 },
    { xi.magic.spell.BURST_II, 75 },
    { xi.magic.spell.BLIZZAJA, 93 },
    { xi.magic.spell.THUNDAJA, 87 },
    { xi.magic.spell.BLIZZARD_V, 89 },
    { xi.magic.spell.THUNDER_V, 92 },
    { xi.magic.spell.FREEZE, 50 },
    { xi.magic.spell.BURST, 56 },
    { xi.magic.spell.BLIZZARD_IV, 74 },
    { xi.magic.spell.THUNDER_IV, 75 },
    { xi.magic.spell.BLIZZARD_III, 64 },
    { xi.magic.spell.THUNDER_III, 66 },
    { xi.magic.spell.BLIZZARD_II, 42 },
    { xi.magic.spell.THUNDER_II, 46 },
    { xi.magic.spell.BLIZZARD, 17 },
    { xi.magic.spell.THUNDER, 21 },
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

    mob:addMod(xi.mod.FASTCAST, 50)

    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZARD })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.THUNDER })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FREEZE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BURST }, 60)

    kit.onCombatTick(mob, 'KAYEEL_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 1500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'KAYEEL_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'KAYEEL_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
