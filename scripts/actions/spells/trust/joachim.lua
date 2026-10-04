-----------------------------------
-- Trust: Joachim
-- Retail (BG Wiki BGWiki:Trusts): BRD/WHM. Keeps two songs on the party: Paeon when his HP is under 90%, Ballad when his
-- MP is under 75%, Victory > Advancing March and Blade > Sword Madrigal unless another bard provides them, otherwise
-- Valor Minuet and Knight's Minne; waits for his songs to expire. Cures (higher priority than songs), Erase, -na spells,
-- Elegy; throws at the enemy. Left out: Paeon twice, the "until supports are out of MP" Paeon switch.
-----------------------------------
local songs = require('modules/custom/lua/trust_song_kit')

-- Spell list levels (mob_spell_lists 323, Minuet / Minne added by modules/custom/sql/trust_bards.sql)
local levels =
{
    [xi.magic.spell.ARMYS_PAEON_VI] = 78, [xi.magic.spell.ARMYS_PAEON_V] = 65, [xi.magic.spell.ARMYS_PAEON_IV] = 45,
    [xi.magic.spell.ARMYS_PAEON_III] = 35, [xi.magic.spell.ARMYS_PAEON_II] = 15, [xi.magic.spell.ARMYS_PAEON] = 5,
    [xi.magic.spell.MAGES_BALLAD_III] = 85, [xi.magic.spell.MAGES_BALLAD_II] = 55, [xi.magic.spell.MAGES_BALLAD] = 25,
    [xi.magic.spell.VICTORY_MARCH] = 60, [xi.magic.spell.ADVANCING_MARCH] = 29,
    [xi.magic.spell.BLADE_MADRIGAL] = 51, [xi.magic.spell.SWORD_MADRIGAL] = 11,
    [xi.magic.spell.VALOR_MINUET_V] = 87, [xi.magic.spell.VALOR_MINUET_IV] = 63, [xi.magic.spell.VALOR_MINUET_III] = 43,
    [xi.magic.spell.VALOR_MINUET_II] = 23, [xi.magic.spell.VALOR_MINUET] = 3,
    [xi.magic.spell.KNIGHTS_MINNE_V] = 80, [xi.magic.spell.KNIGHTS_MINNE_IV] = 61, [xi.magic.spell.KNIGHTS_MINNE_III] = 41,
    [xi.magic.spell.KNIGHTS_MINNE_II] = 21, [xi.magic.spell.KNIGHTS_MINNE] = 1,
}

local PAEONS   = { xi.magic.spell.ARMYS_PAEON_VI, xi.magic.spell.ARMYS_PAEON_V, xi.magic.spell.ARMYS_PAEON_IV, xi.magic.spell.ARMYS_PAEON_III, xi.magic.spell.ARMYS_PAEON_II, xi.magic.spell.ARMYS_PAEON }
local BALLADS  = { xi.magic.spell.MAGES_BALLAD_III, xi.magic.spell.MAGES_BALLAD_II, xi.magic.spell.MAGES_BALLAD }
local MARCHES  = { xi.magic.spell.VICTORY_MARCH, xi.magic.spell.ADVANCING_MARCH }
local MADRIGAL = { xi.magic.spell.BLADE_MADRIGAL, xi.magic.spell.SWORD_MADRIGAL }
local MINUETS  = { xi.magic.spell.VALOR_MINUET_V, xi.magic.spell.VALOR_MINUET_IV, xi.magic.spell.VALOR_MINUET_III, xi.magic.spell.VALOR_MINUET_II, xi.magic.spell.VALOR_MINUET }
local MINNES   = { xi.magic.spell.KNIGHTS_MINNE_V, xi.magic.spell.KNIGHTS_MINNE_IV, xi.magic.spell.KNIGHTS_MINNE_III, xi.magic.spell.KNIGHTS_MINNE_II, xi.magic.spell.KNIGHTS_MINNE }

-- Retail priority (BG Wiki): Paeon when his HP is under 90%, Ballad when his MP is under 75%, March and Madrigal
-- unless another bard provides them, then Minuet and Minne to fill his two songs
local function wanted(bard, master)
    local list = {}

    if bard:getHPP() < 90 then
        table.insert(list, songs.best(bard, PAEONS, levels))
    end

    if bard:getMPP() < 75 then
        table.insert(list, songs.best(bard, BALLADS, levels))
    end

    if not songs.othersHave(bard, master, xi.effect.MARCH) then
        table.insert(list, songs.best(bard, MARCHES, levels))
    end

    if not songs.othersHave(bard, master, xi.effect.MADRIGAL) then
        table.insert(list, songs.best(bard, MADRIGAL, levels))
    end

    table.insert(list, songs.best(bard, MINUETS, levels))
    table.insert(list, songs.best(bard, MINNES, levels))

    return list
end

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Joachim
    if caster:getEminenceProgress(937) then
        xi.roe.onRecordTrigger(caster, 937)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ELEGY }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ELEGY }, 60)

    -- Songs: two of his own on the party, by priority, never overwritten early (trust_song_kit)
    mob:addListener('COMBAT_TICK', 'JOACHIM_SONGS', function(mobArg)
        songs.tick(mobArg, wanted, 0)
    end)

    -- Try and ranged attack every 60s
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 60)

    mob:setAutoAttackEnabled(false)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
end

spellObject.onMobDespawn = function(mob)
    mob:removeListener('JOACHIM_SONGS')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    mob:removeListener('JOACHIM_SONGS')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
