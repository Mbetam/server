-----------------------------------
-- Trust: Halver
-- Retail behaviour (BG Wiki BGWiki:Trusts): PLD/WAR, MP+30%. Uses Berserk as often as possible. When a party member's
-- HP is low (under 40%) he acts like a tank: Provoke, Sentinel and Rampart, and more magic (Cure I-IV, Flash).
-- Weapon skills at 1000 TP, low priority (mob_skill_lists 1087): Penta Thrust, Impulse Drive, Raiden Thrust.
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

    mob:addMod(xi.mod.MPP, 30)

    -- Tank mode: a party member under 40% HP. Job abilities that are not self-only land on the battle target,
    -- self-only ones (Sentinel, Rampart) on Halver himself, whoever triggered the gambit.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 40 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 40 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 40 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RAMPART })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 40 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })

    -- No retry delay: the engine starts a gambit's retry delay even when the cast did not start (e.g. still out of range),
    -- which kept Flash locked for a minute. Flash's own recast and the NOT_STATUS check already prevent spamming it.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
