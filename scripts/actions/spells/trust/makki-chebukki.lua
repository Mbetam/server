-----------------------------------
-- Trust: Makki-Chebukki
-- Retail behaviour (BG Wiki BGWiki:Trusts): RNG/BLM, Store TP-40, gains 168 TP per ranged attack. Stays out of melee
-- range. Flashy Shot, Sharpshot, Barrage. Weapon skills at 2000 TP without trying to skillchain
-- (mob_skill_lists 1103): Sidewinder, Empyreal Arrow, Dulling Arrow, Flaming Arrow.
-- Not done: the Lightsday idle behaviour and the Meteor emote with Kukki-Chebukki and Cherukiki.
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

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BARRAGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FLASHY_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FLASHY_SHOT })

    -- Ranged Attack as much as possible (limited by 'weapon' delay)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })

    mob:setAutoAttackEnabled(false)

    -- 168 TP per shot. Scaled from semih_lafihna.lua, where Store TP 86 gives 252 (about 135 base): 168 / 135 = +24.
    mob:addMod(xi.mod.STORETP, 24)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.LONG_RANGE)

    -- At 2000 TP a 20% chance per check, so soon after 2000 and without waiting for a skillchain
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
