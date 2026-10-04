-----------------------------------
-- Trust: Ulmia
-- Retail (BG Wiki BGWiki:Trusts): BRD/BRD. Does not engage. Keeps two songs on the party, refreshed shortly before they
-- wear off: Ballad for the party member lowest on MP (under 75% with 3+ MP users in the party, under 33% otherwise),
-- Victory and Advancing March unless another bard provides them, then Blade and Sword Madrigal, then the highest
-- Valor Minuets. Left out: Pianissimo single-target songs (Scherzo, Prelude, player Ballad), MP-usage-rate tracking.
-----------------------------------
local songs = require('modules/custom/lua/trust_song_kit')

-- Spell list levels (mob_spell_lists 326)
local levels =
{
    [xi.magic.spell.MAGES_BALLAD_III] = 85, [xi.magic.spell.MAGES_BALLAD_II] = 55, [xi.magic.spell.MAGES_BALLAD] = 25,
    [xi.magic.spell.VICTORY_MARCH] = 60, [xi.magic.spell.ADVANCING_MARCH] = 29,
    [xi.magic.spell.BLADE_MADRIGAL] = 51, [xi.magic.spell.SWORD_MADRIGAL] = 11,
    [xi.magic.spell.VALOR_MINUET_V] = 87, [xi.magic.spell.VALOR_MINUET_IV] = 63, [xi.magic.spell.VALOR_MINUET_III] = 43,
    [xi.magic.spell.VALOR_MINUET_II] = 23, [xi.magic.spell.VALOR_MINUET] = 3,
}

local BALLADS = { xi.magic.spell.MAGES_BALLAD_III, xi.magic.spell.MAGES_BALLAD_II, xi.magic.spell.MAGES_BALLAD }
local MINUETS = { xi.magic.spell.VALOR_MINUET_V, xi.magic.spell.VALOR_MINUET_IV, xi.magic.spell.VALOR_MINUET_III, xi.magic.spell.VALOR_MINUET_II, xi.magic.spell.VALOR_MINUET }

-- Ballad when the party member using the most MP is low: under 75% if 3+ party members have MP, under 33% otherwise
local function needsBallad(bard, master)
    local withMP, lowest = 0, 100

    for _, member in ipairs(master:getPartyWithTrusts()) do
        if member:isAlive() and member:getMaxMP() > 0 then
            withMP = withMP + 1
            lowest = math.min(lowest, member:getMPP())
        end
    end

    return lowest < (withMP >= 3 and 75 or 33)
end

-- Retail priority (BG Wiki): Ballad when needed, then both Marches unless another bard provides them, then both
-- Madrigals unless provided, then the two highest Minuets
local function wanted(bard, master)
    local list = {}

    if needsBallad(bard, master) then
        table.insert(list, songs.best(bard, BALLADS, levels))
    end

    if not songs.othersHave(bard, master, xi.effect.MARCH) then
        table.insert(list, bard:getMainLvl() >= levels[xi.magic.spell.VICTORY_MARCH] and xi.magic.spell.VICTORY_MARCH or nil)
        table.insert(list, bard:getMainLvl() >= levels[xi.magic.spell.ADVANCING_MARCH] and xi.magic.spell.ADVANCING_MARCH or nil)
    elseif not songs.othersHave(bard, master, xi.effect.MADRIGAL) then
        table.insert(list, bard:getMainLvl() >= levels[xi.magic.spell.BLADE_MADRIGAL] and xi.magic.spell.BLADE_MADRIGAL or nil)
        table.insert(list, bard:getMainLvl() >= levels[xi.magic.spell.SWORD_MADRIGAL] and xi.magic.spell.SWORD_MADRIGAL or nil)
    end

    for _, spellId in ipairs(MINUETS) do
        if bard:getMainLvl() >= levels[spellId] then
            table.insert(list, spellId)
        end
    end

    return list
end

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
        [xi.magic.spell.PRISHE] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.MILDAURION] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Songs: two of her own on the party, by priority, refreshed 20 s before they wear off (trust_song_kit)
    mob:addListener('COMBAT_TICK', 'ULMIA_SONGS', function(mobArg)
        songs.tick(mobArg, wanted, 20)
    end)

    mob:setAutoAttackEnabled(false)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
end

spellObject.onMobDespawn = function(mob)
    mob:removeListener('ULMIA_SONGS')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    mob:removeListener('ULMIA_SONGS')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
