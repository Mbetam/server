-----------------------------------
-- Trust: Chacharoon
-- Retail (BG Wiki BGWiki:Trusts): THF/RNG, HP-10%, MP-10%. Very low delay, low damage; occasionally throws at the enemy;
-- weapon skills at 1000 TP (Sharp Eye: Gravity + Defense Down, Tripe Gripe: Amnesia (and an Attack boost on the
-- enemy), Pocket Sand: dark damage + Blind; trust-unique, estimated numbers, see their mob skill scripts).
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

    mob:addMod(xi.mod.HPP, -10)
    mob:addMod(xi.mod.MPP, -10)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 20)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
