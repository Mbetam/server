-----------------------------------
-- Trust: Iron Eater
-- Retail (BG Wiki BGWiki:Trusts): WAR/WAR, Double Attack merits and enhanced rate, enhanced Store TP. Provoke only when
-- the player's HP is low; Berserk; Restraint, holding TP well past 3000 under it (here: to 3000); Shield Break, Armor
-- Break, Steel Cyclone.
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
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NAJI] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RESTRAINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })

    mob:addMod(xi.mod.DOUBLE_ATTACK, 15) -- 5/5 Double Attack merits plus an enhanced rate (amount estimated)
    mob:addMod(xi.mod.STORETP, 15)

    -- Under Restraint he waits for many hits before a weapon skill; uses TP as soon as he has it otherwise
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
