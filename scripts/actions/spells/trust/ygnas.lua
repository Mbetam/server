-----------------------------------
-- Trust: Ygnas
-- Retail (BG Wiki BGWiki:Trusts): WHM/PLD, HP+10%, MP+10%, Cure Potency +50%, Fast Cast +50%. Cure VI on anyone under
-- 45% HP; Cure III (his most MP-efficient cure) on the tank under 75% and anyone else under 66%; Protectra / Shellra,
-- -na spells, Erase, Haste; does not engage and stays out of range.
-- Regain 30; holds TP to 3000 (Deific Gambol, Sacred Caper: trust-unique, estimated numbers). Left out: Phototropic
-- Blessing / Wrath (no skill rows), the Cure-to-MP conversion, the Arciela synergy.
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

    mob:addMod(xi.mod.HPP, 10)
    mob:addMod(xi.mod.MPP, 10)
    mob:addMod(xi.mod.CURE_POTENCY, 50)
    mob:addMod(xi.mod.FASTCAST, 50)
    mob:addMod(xi.mod.REGAIN, 30)

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 45 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE_III })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 66 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE_III })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 66 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE }) -- below level 21
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA }, 60)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA }, 60)
    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
