-----------------------------------
-- Trust: Zeid
-- Retail (BG Wiki BGWiki:Trusts): DRK/DRK. Last Resort; Stun on enemy TP moves; Absorb-TP once the enemy has TP; at
-- low HP Nether Void and Drain II; Absorb spells; weapon skills as soon as he has TP (Freezebite, Ground Strike,
-- Abyssal Drain, Abyssal Strike).
-- Left out: Souleater (retail only with a healer in the party: no gambit condition for that), Endark and Absorb-Attri
-- (not in his spell list), the Aldo / Lion synergy.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ZEID_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.LAST_RESORT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.LAST_RESORT })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.TP_GTE, 1000 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_TP })
    mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.NETHER_VOID })
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.DRAIN })
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, { ai.c.MPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ASPIR }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_ACC }, 90)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ABSORB_STR }, 90)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
