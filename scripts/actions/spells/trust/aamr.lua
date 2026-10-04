-----------------------------------
-- Trust: AAMR
-- Retail (BG Wiki BGWiki:Trusts): BST/THF, HP+20%. Sneak Attack and Trick Attack, then a weapon skill as soon as one is up
-- with 1000+ TP, favouring Calamity (Cloudsplitter in front of the target); otherwise holds TP up to 3000, no skillchain
-- attempts (Rampage, Calamity, Havoc Spiral, Cloudsplitter). Left out: the positioning checks (behind the target /
-- behind a party member).
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

local CALAMITY = 3716

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

    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.SNEAK_ATTACK } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SNEAK_ATTACK })
    mob:addGambit(ai.t.SELF, { { ai.c.TP_GTE, 1000 }, { ai.c.NOT_STATUS, xi.effect.TRICK_ATTACK } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRICK_ATTACK })

    -- Calamity right after Sneak / Trick Attack (TP moves are tried before gambits, so this can't be a plain TP setting)
    kit.skillWhen(mob, 'AAMR_CALAMITY', CALAMITY, 0, function(mobArg)
        return mobArg:getTP() >= 1000 and
            (mobArg:hasStatusEffect(xi.effect.SNEAK_ATTACK) or mobArg:hasStatusEffect(xi.effect.TRICK_ATTACK))
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'AAMR_CALAMITY')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'AAMR_CALAMITY')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
