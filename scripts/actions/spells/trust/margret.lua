-----------------------------------
-- Trust: Margret
-- Retail behaviour (BG Wiki BGWiki:Trusts): RNG/THF, Store TP+40, gains 252 TP per ranged attack. Stays out of melee
-- range and backs her attacks with as many job abilities as possible (Decoy Shot, Double Shot, Barrage, Sharpshot).
-- Weapon skills at 2000 TP without trying to skillchain (mob_skill_lists 1077): Sidewinder, Arching Arrow,
-- Refulgent Arrow, Piercing Arrow.
-- Not done: Stealth Shot (not implemented for trusts, see semih_lafihna.lua), Treasure Hunter, and holding back
-- weapon skills when the enemy is under ~10-15% HP.
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
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DECOY_SHOT })

    -- Ranged Attack as much as possible (limited by 'weapon' delay)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })

    mob:setAutoAttackEnabled(false)

    -- 252 TP per shot, the same as Semih Lafihna: same Store TP hack as semih_lafihna.lua
    mob:addMod(xi.mod.STORETP, 86)

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
