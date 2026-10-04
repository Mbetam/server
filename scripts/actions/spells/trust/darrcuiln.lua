-----------------------------------
-- Trust: Darrcuiln
-- Retail (BG Wiki BGWiki:Trusts): WAR/RDM (beast), HP about +42%. Holds TP somewhere between 1500 and 2000, no
-- skillchain attempts (Howling Gust, Starward Yowl, Righteous Rasp, Aurous Charge, Stalking Prey: trust-unique,
-- estimated numbers, see their mob skill scripts). Left out: his special-move auto-attacks.
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

    mob:addMod(xi.mod.HPP, 42)

    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
