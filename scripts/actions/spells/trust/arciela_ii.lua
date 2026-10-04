-----------------------------------
-- Trust: Arciela II
-- Retail (BG Wiki BGWiki:Trusts): RDM/BLM, MP+50%, extremely potent Fast Cast; the offensive Arciela. Haste II on
-- melee jobs, Flurry II on RNG / COR, Refresh II on mages and herself; Slow, Paralyze, Addle, Dispel; often double
-- magic bursts with tier V / IV nukes and nukes otherwise (here: the target's weakest element).
-- Left out: Ascension / Descension (light / dark modes that limit her elements), Protect / Shell (not in her spell
-- list), her TP moves (Expunge Magic ... Naakual's Vengeance: no scripts).
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: strongest single-target spell of the element; up to two bursts per skillchain
local burstSpells =
{
    { xi.magic.spell.FIRE_V, 99 },
    { xi.magic.spell.BLIZZARD_V, 99 },
    { xi.magic.spell.AERO_V, 99 },
    { xi.magic.spell.STONE_V, 99 },
    { xi.magic.spell.THUNDER_V, 99 },
    { xi.magic.spell.WATER_V, 99 },
    { xi.magic.spell.FIRE_IV, 72 },
    { xi.magic.spell.BLIZZARD_IV, 89 },
    { xi.magic.spell.AERO_IV, 72 },
    { xi.magic.spell.STONE_IV, 68 },
    { xi.magic.spell.THUNDER_IV, 75 },
    { xi.magic.spell.WATER_IV, 70 },
    { xi.magic.spell.FIRE_III, 59 },
    { xi.magic.spell.BLIZZARD_III, 73 },
    { xi.magic.spell.AERO_III, 59 },
    { xi.magic.spell.STONE_III, 51 },
    { xi.magic.spell.THUNDER_III, 66 },
    { xi.magic.spell.WATER_III, 55 },
    { xi.magic.spell.FIRE_II, 34 },
    { xi.magic.spell.BLIZZARD_II, 56 },
    { xi.magic.spell.AERO_II, 34 },
    { xi.magic.spell.STONE_II, 26 },
    { xi.magic.spell.THUNDER_II, 46 },
    { xi.magic.spell.WATER_II, 30 },
    { xi.magic.spell.FIRE, 9 },
    { xi.magic.spell.BLIZZARD, 24 },
    { xi.magic.spell.AERO, 9 },
    { xi.magic.spell.STONE, 1 },
    { xi.magic.spell.THUNDER, 21 },
    { xi.magic.spell.WATER, 5 },
}

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ARCIELA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.MPP, 50)
    mob:addMod(xi.mod.FASTCAST, 80)

    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.RANGED, {
        { ai.c.NOT_STATUS, xi.effect.FLURRY_II }, -- xi.effect.FLURRY_II is not a typo
        { ai.c.NOT_STATUS, xi.effect.HASTE },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FLURRY })
    mob:addGambit(ai.t.CASTER, {
        { ai.c.NOT_STATUS, xi.effect.REFRESH },
        { ai.c.NOT_STATUS, xi.effect.SUBLIMATION_ACTIVATED },
        { ai.c.NOT_STATUS, xi.effect.SUBLIMATION_COMPLETE },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.REFRESH }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ADDLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ADDLE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.STONE_V }, 15)

    kit.onCombatTick(mob, 'ARCIELA_II_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 2)
    end)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'ARCIELA_II_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'ARCIELA_II_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
