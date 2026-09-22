-----------------------------------
-- Trust: Gilgamesh
-- Retail behaviour (BG Wiki BGWiki:Trusts): SAM/WAR. Hasso, Third Eye, Sekkanoki, Hagakure. Holds up to 2000 TP to close
-- skillchains; with 2000 TP and Sekkanoki ready he skillchains with himself.
-- Weapon skills (mob_skill_lists 1053): Tachi: Goten, Tachi: Kasha.
-- Not done: Iainuki and Tachi: Kamai (no mob skill scripts yet). When he uses Hagakure is not documented;
-- here it is right before a weapon skill, like Sekkanoki.
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

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Sekkanoki while he holds TP (1000+): his weapon skill at 2000 then costs only 1000, leaving enough for a second one
    -- to close his own skillchain. Not at 2000: the engine tries weapon skills before gambits, so a gambit at 2000 TP
    -- would never get its turn.
    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.SEKKANOKI } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SEKKANOKI })
    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.HAGAKURE } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
