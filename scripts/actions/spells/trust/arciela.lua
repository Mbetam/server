-----------------------------------
-- Trust: Arciela
-- Retail (BG Wiki BGWiki:Trusts): RDM/PLD, MP+20%, the support Arciela. Haste and Refresh only on the player and
-- herself (player first; Haste II from level 96); Protect / Shell; Slow and Paralyze; stays in place after engaging.
-- Regain 25; Guiding Light and Dynastic Gravitas at random, Illustrious Aid when 2+ party members are under 75% HP
-- (trust-unique, estimated numbers). Left out: Bellatrix of Light / Shadows stances, Addle and Dispel (not in her list).
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ARCIELA_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.MPP, 20)
    mob:addMod(xi.mod.REGAIN, 25)

    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.MASTER, {
        { ai.c.NOT_STATUS, xi.effect.REFRESH },
        { ai.c.NOT_STATUS, xi.effect.SUBLIMATION_ACTIVATED },
        { ai.c.NOT_STATUS, xi.effect.SUBLIMATION_COMPLETE },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.REFRESH }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)


    -- Illustrious Aid when 2+ party members are under 75% HP (30 s cooldown)
    kit.skillWhen(mob, 'ARCIELA_AID', 3452, 30, function(mobArg)
        return (kit.partyHurt(mobArg, 75)) >= 2
    end)
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'ARCIELA_AID')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'ARCIELA_AID')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
