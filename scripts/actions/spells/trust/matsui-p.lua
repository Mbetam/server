-----------------------------------
-- Trust: Matsui-P
-- Retail (BG Wiki BGWiki:Trusts): NIN/BLM. Keeps shadows up first; Innin, Sange; Migawari, Kakka, Myoshu on himself, Burn,
-- Yurin and Aisha on the enemy; Stun on enemy TP moves; prioritises elemental ninjutsu and black magic, and magic
-- bursts with ninjutsu San and tier I nukes boosted by Futae; holds TP to 3000 to open skillchains for the player
-- (Blade: Rin ... Shun). Spell / skill lists: modules/custom/sql/trust_matsui_p.sql (LSB had none).
-- Left out: Elemental Seal, Mana Wall, the party-chat callouts, "only opens Light / Darkness for the player".
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: ninjutsu San, then Ni, then the tier I nuke of the element
local burstSpells =
{
    { xi.magic.spell.KATON_SAN, 75 }, { xi.magic.spell.HYOTON_SAN, 75 }, { xi.magic.spell.HUTON_SAN, 75 },
    { xi.magic.spell.DOTON_SAN, 75 }, { xi.magic.spell.RAITON_SAN, 75 }, { xi.magic.spell.SUITON_SAN, 75 },
    { xi.magic.spell.KATON_NI, 40 }, { xi.magic.spell.HYOTON_NI, 40 }, { xi.magic.spell.HUTON_NI, 40 },
    { xi.magic.spell.DOTON_NI, 40 }, { xi.magic.spell.RAITON_NI, 40 }, { xi.magic.spell.SUITON_NI, 40 },
    { xi.magic.spell.FIRE, 13 }, { xi.magic.spell.BLIZZARD, 17 }, { xi.magic.spell.AERO, 9 },
    { xi.magic.spell.STONE, 1 }, { xi.magic.spell.THUNDER, 21 }, { xi.magic.spell.WATER, 5 },
}

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

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.UTSUSEMI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.INNIN }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.INNIN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TRIGGER_TARGET_ACTION_SELF, { ai.c.MB_AVAILABLE, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FUTAE })
    -- Retail: prioritises elemental ninjutsu (each on its own recast); the self buffs and debuffs fill the gaps
    for _, spell in ipairs({ 'KATON', 'HYOTON', 'HUTON', 'DOTON', 'RAITON', 'SUITON' }) do
        mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell[spell .. '_SAN'] })
    end

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SANGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SANGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MIGAWARI }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MIGAWARI_ICHI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STORE_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.KAKKA_ICHI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SUBTLE_BLOW_PLUS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MYOSHU_ICHI })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BURN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BURN }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.INHIBIT_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.YURIN_ICHI }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ATTACK_DOWN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AISHA_ICHI }, 60)
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, { ai.c.MPP_LT, 30 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ASPIR }, 30)

    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.STONE }, 10)

    kit.onCombatTick(mob, 'MATSUI_P_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'MATSUI_P_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'MATSUI_P_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
