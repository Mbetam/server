-----------------------------------
-- Trust: AAGK
-- Retail (BG Wiki BGWiki:Trusts): SAM/DRG, HP+20%. Hasso; Jump at low TP (big TP return); High Jump when he has the hate;
-- Konzen-ittai when the player has 1000 TP and he doesn't; Hagakure, Meditate and Sekkanoki for his self-skillchain at
-- 2000 TP; holds up to 3000 TP to close skillchains (Tachi: Yukikaze, Gekko, Kasha, Fudo, Dragonfall).
-- Left out: weapon skills without TP, the exact self-skillchain order.
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

    mob:addMod(xi.mod.HPP, 20)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.JUMP })
    mob:addGambit(ai.t.TARGET, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HIGH_JUMP })
    mob:addGambit(ai.t.MASTER, { ai.c.TP_GTE, 1000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.KONZEN_ITTAI })
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SEKKANOKI })
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })
    mob:addGambit(ai.t.SELF, { ai.c.TP_LT, 1000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
