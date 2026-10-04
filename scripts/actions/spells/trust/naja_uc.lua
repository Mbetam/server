-----------------------------------
-- Trust: Naja Salaheem UC
-- Retail (BG Wiki BGWiki:Trusts): MNK/WAR (the DB has her THF/WAR). Uses a club weapon skill when another party member
-- has 1000 TP, otherwise holds TP (Peacebreaker, Hexa Strike, Nott, Black Halo).
-- Left out: Justicebreaker (no script), "one weapon skill per summoning", Unity bonuses.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.NAJA_SALAHEEM)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.RANDOM, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
