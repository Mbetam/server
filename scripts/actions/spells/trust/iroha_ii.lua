-----------------------------------
-- Trust: Iroha II
-- Retail (BG Wiki BGWiki:Trusts): SAM/WHM, HP-5%, MP+250%. Protectra V / Shellra V; Hasso, Meditate, Third Eye;
-- magic bursts fire-based skillchains with a near-instant Flare II.
-- Holds TP to close skillchains (Amatsu: Kyori, Hanadoki, Suien, Gachirin); Rise From Ashes when 3+ party members are
-- under 75% HP or one is asleep (trust-unique moves, estimated numbers). Left out: the 4-step Light self-skillchain.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

local burstSpells =
{
    { xi.magic.spell.FLARE_II, 75 },
}

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.IROHA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, -5)
    mob:addMod(xi.mod.MPP, 250)
    mob:addMod(xi.mod.FASTCAST, 80) -- "near instant" Flare II

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA }, 60)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA }, 60)

    kit.onCombatTick(mob, 'IROHA_II_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)


    -- Rise From Ashes when 3+ party members are under 75% HP or one is asleep (30 s cooldown)
    kit.skillWhen(mob, 'IROHA_II_RISE', 3738, 30, function(mobArg)
        local hurt, asleep = kit.partyHurt(mobArg, 75)

        return hurt >= 3 or asleep
    end)
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'IROHA_II_BURST')
    kit.cleanup(mob, 'IROHA_II_RISE')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'IROHA_II_BURST')
    kit.cleanup(mob, 'IROHA_II_RISE')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
