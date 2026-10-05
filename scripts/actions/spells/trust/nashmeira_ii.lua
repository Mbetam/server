-----------------------------------
-- Trust: Nashmeira II
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.NASHMEIRA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.LILISETTE_II] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ARCIELA_II] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.IROHA_II] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.LION_II] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.PRISHE_II] = xi.trust.messageOffset.TEAMWORK_5,
    })

    -- Curaga when 3+ party members are under 75% HP or one is asleep (retail), ahead of single Cures (caster kit)
    -- Cure / Curaga by how many are hurt (retail: Curaga for 3+ under 75% or one asleep): both are managed here so a
    -- single Cure can't jump in first when three members drop at once
    kit.gambitWhen(mob, 'NASHMEIRA_II_CURAGA', ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA }, 0, function(mobArg)
        local hurt, asleep = kit.partyHurt(mobArg, 75)

        return hurt >= 3 or asleep
    end)
    kit.gambitWhen(mob, 'NASHMEIRA_II_CURE', ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE }, 0, function(mobArg)
        local hurt, asleep = kit.partyHurt(mobArg, 75)

        return hurt >= 1 and hurt < 3 and not asleep
    end)

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addListener('WEAPONSKILL_USE', 'NASHMEIRA_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 3243 then -- Imperial Authority
            -- No! Stand back!
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'NASHMEIRA_II_CURAGA')
    kit.cleanup(mob, 'NASHMEIRA_II_CURE')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'NASHMEIRA_II_CURAGA')
    kit.cleanup(mob, 'NASHMEIRA_II_CURE')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
