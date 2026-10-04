-----------------------------------
-- Trust: Leonoyne
-- Retail (BG Wiki BGWiki:Trusts): BLM/PLD, MP+25%. Keeps Ice Spikes up and favours Blizzaga III; permanent Enblizzard
-- (30+ damage even at low level); recovers MP when hit; weapon skills at 1000 TP (Freezebite, Herculean Slash,
-- Shockwave). Left out: Spine Chiller (no mob skill row).
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

    mob:addMod(xi.mod.MPP, 25)
    mob:addMod(xi.mod.ABSORB_PHYSDMG_TO_MP, 5)
    mob:addMod(xi.mod.ENSPELL, xi.element.ICE)
    mob:addMod(xi.mod.ENSPELL_DMG, math.max(30, math.floor(mob:getMainLvl() * 0.4)))
    mob:addMod(xi.mod.ENSPELL_CHANCE, 100)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ICE_SPIKES }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ICE_SPIKES })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZAGA })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
