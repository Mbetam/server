-----------------------------------
-- Trust: D Shantotto
-- Retail (BG Wiki BGWiki:Trusts): BLM/DRK. Opens fights with tier V nukes, then melees; nukes now and then while she
-- is not at the top of the enmity list and never magic bursts. Only darkness-aligned elements (ice, earth, water),
-- whatever the target is weak to. Weapon skills at 1000 TP: Guillotine, Cross Reaper, Shadow of Death.
-- Left out: Salvation Scythe (trust-unique, no mob skill script).
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Opening nuke: tier V first (ice, earth, water), lower tiers below level 77
local openers =
{
    { xi.magic.spell.BLIZZARD_V, 89 },
    { xi.magic.spell.STONE_V, 77 },
    { xi.magic.spell.WATER_V, 80 },
    { xi.magic.spell.BLIZZARD_IV, 74 },
    { xi.magic.spell.STONE_IV, 68 },
    { xi.magic.spell.WATER_IV, 70 },
    { xi.magic.spell.STONE_III, 51 },
    { xi.magic.spell.STONE_II, 26 },
    { xi.magic.spell.STONE, 1 },
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

    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZARD }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.STONE }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.WATER }, 30)

    kit.onCombatTick(mob, 'D_SHANTOTTO_OPENER', function(mobArg)
        kit.openerTick(mobArg, openers)
    end)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'D_SHANTOTTO_OPENER')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'D_SHANTOTTO_OPENER')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
