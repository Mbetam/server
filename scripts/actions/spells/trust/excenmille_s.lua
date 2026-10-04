-----------------------------------
-- Trust: Excenmille S
-- Retail (BG Wiki BGWiki:Trusts): WAR/PLD. Stag's Call (party Haste +15%, Attack +15%, MAB +15 for 3 minutes, every 5
-- minutes); weapon skills at 1000 TP (Songbird Swoop, Gyre Strike, Orcsbane, Stag's Charge: trust-unique, estimated
-- numbers, see their mob skill scripts).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.EXCENMILLE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.MS, ai.s.SPECIFIC, 3291 }, 300) -- Stag's Call

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
