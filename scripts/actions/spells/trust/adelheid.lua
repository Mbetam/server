-----------------------------------
-- Trust: Adelheid
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

local helixes =
{
    { xi.magic.spell.GEOHELIX, 18 }, { xi.magic.spell.HYDROHELIX, 20 }, { xi.magic.spell.ANEMOHELIX, 22 },
    { xi.magic.spell.PYROHELIX, 24 }, { xi.magic.spell.CRYOHELIX, 26 }, { xi.magic.spell.IONOHELIX, 28 },
    { xi.magic.spell.NOCTOHELIX, 30 }, { xi.magic.spell.LUMINOHELIX, 32 },
}

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Adelheid
    if caster:getEminenceProgress(936) then
        xi.roe.onRecordTrigger(caster, 936)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.ADDENDUM_BLACK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DARK_ARTS })
    mob:addGambit(ai.t.SELF, { { ai.c.NOT_STATUS, xi.effect.ADDENDUM_BLACK }, { ai.c.LVL_GTE, 30 } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ADDENDUM_BLACK })

    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Storm of the enemy's weakness, else the day's (selector fixed in gambits_container.cpp, 2026-10-04)
    mob:addGambit(ai.t.SELF, { ai.c.NO_STORM, 0 }, { ai.r.MA, ai.s.STORM_MOB_WEAKNESS, 0 }, 0)
    mob:addGambit(ai.t.SELF, { ai.c.NO_STORM, 0 }, { ai.r.MA, ai.s.STORM_DAY, 0 }, 0)

    -- Helix of the enemy's weakness, else the day's
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.HELIX }, { ai.r.MA, ai.s.HELIX_MOB_WEAKNESS, 0 }, 0)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.HELIX }, { ai.r.MA, ai.s.HELIX_DAY, 0 }, 0)

    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 33 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Magic bursts a skillchain with the matching helix (caster kit)
    kit.onCombatTick(mob, 'ADELHEID_BURST', function(mobArg)
        kit.burstTick(mobArg, helixes, 1)
    end)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 75)

    mob:addListener('WEAPONSKILL_USE', 'ADELHEID_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == xi.mobSkill.TWIRLING_DERVISH then
            if math.randomInt(1, 100) <= 33 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- You may want to cover your ears!
            end
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'ADELHEID_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'ADELHEID_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
