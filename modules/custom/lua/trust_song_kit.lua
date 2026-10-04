-----------------------------------
-- Song logic for the bard trusts (Joachim, Ulmia), 2026-10-04. Required by their scripts; not a module.
--
-- Why: gambits can't do retail bard behaviour. A bard keeps two of its own songs on the party, picks them by priority,
-- leaves out songs another bard already provides, and either waits for its songs to expire (Joachim) or refreshes them
-- shortly before they do (Ulmia). "NOT_STATUS MARCH" style gambits would recast over their own songs in a loop.
-- Songs store their singer: addBardSong puts the bard's id (low 16 bits) in the effect's sub type, the engine
-- keeps two songs per singer per target and drops the oldest (ApplyBardEffect). The master stands in for the party.
-----------------------------------

local songs = {}

-- spell id -> effect, tier (as in scripts/globals/spells/enhancing_song.lua)
songs.info =
{
    [xi.magic.spell.ARMYS_PAEON]       = { xi.effect.PAEON, 1 },
    [xi.magic.spell.ARMYS_PAEON_II]    = { xi.effect.PAEON, 2 },
    [xi.magic.spell.ARMYS_PAEON_III]   = { xi.effect.PAEON, 3 },
    [xi.magic.spell.ARMYS_PAEON_IV]    = { xi.effect.PAEON, 4 },
    [xi.magic.spell.ARMYS_PAEON_V]     = { xi.effect.PAEON, 5 },
    [xi.magic.spell.ARMYS_PAEON_VI]    = { xi.effect.PAEON, 6 },
    [xi.magic.spell.MAGES_BALLAD]      = { xi.effect.BALLAD, 1 },
    [xi.magic.spell.MAGES_BALLAD_II]   = { xi.effect.BALLAD, 2 },
    [xi.magic.spell.MAGES_BALLAD_III]  = { xi.effect.BALLAD, 3 },
    [xi.magic.spell.KNIGHTS_MINNE]     = { xi.effect.MINNE, 1 },
    [xi.magic.spell.KNIGHTS_MINNE_II]  = { xi.effect.MINNE, 2 },
    [xi.magic.spell.KNIGHTS_MINNE_III] = { xi.effect.MINNE, 3 },
    [xi.magic.spell.KNIGHTS_MINNE_IV]  = { xi.effect.MINNE, 4 },
    [xi.magic.spell.KNIGHTS_MINNE_V]   = { xi.effect.MINNE, 5 },
    [xi.magic.spell.VALOR_MINUET]      = { xi.effect.MINUET, 1 },
    [xi.magic.spell.VALOR_MINUET_II]   = { xi.effect.MINUET, 2 },
    [xi.magic.spell.VALOR_MINUET_III]  = { xi.effect.MINUET, 3 },
    [xi.magic.spell.VALOR_MINUET_IV]   = { xi.effect.MINUET, 4 },
    [xi.magic.spell.VALOR_MINUET_V]    = { xi.effect.MINUET, 5 },
    [xi.magic.spell.SWORD_MADRIGAL]    = { xi.effect.MADRIGAL, 1 },
    [xi.magic.spell.BLADE_MADRIGAL]    = { xi.effect.MADRIGAL, 2 },
    [xi.magic.spell.ADVANCING_MARCH]   = { xi.effect.MARCH, 1 },
    [xi.magic.spell.VICTORY_MARCH]     = { xi.effect.MARCH, 2 },
}

-- addBardSong stores the singer's id in a uint16 sub type (lua_base_entity.cpp), so only its low 16 bits survive
-- (17188864 -> 18432). Trust ids differ in those bits, so this still tells the singers apart.
songs.singer = function(entity)
    return entity:getID() % 65536
end

local function isSong(effectId)
    return effectId >= xi.effect.REQUIEM and effectId <= xi.effect.NOCTURNE
end

-- Songs on `member`: { effect, tier, singer id, ms remaining }
songs.on = function(member)
    local list = {}

    for _, effect in ipairs(member and member:getStatusEffects() or {}) do
        local id = effect:getEffectType()

        if isSong(id) then
            table.insert(list, { id, effect:getTier(), effect:getSubType(), effect:getTimeRemaining() })
        end
    end

    return list
end

-- Does someone other than `bard` provide a song of this effect on `member`?
songs.othersHave = function(bard, member, effectId)
    for _, s in ipairs(songs.on(member)) do
        if s[1] == effectId and s[3] ~= songs.singer(bard) then
            return true
        end
    end

    return false
end

-- The best spell of `spellIds` (ordered strongest first) the bard knows at its level. levels: [spell id] = min level
songs.best = function(bard, spellIds, levels)
    for _, spellId in ipairs(spellIds) do
        if bard:getMainLvl() >= (levels[spellId] or 255) then
            return spellId
        end
    end
end

-- Called from COMBAT_TICK. wanted(bard, master) returns spell ids in priority order (nil entries are skipped). The
-- bard keeps two of its own songs up; it sings the first wanted song it doesn't have. recastBefore: seconds before
-- expiry at which a song counts as gone (0: wait until it expires). Returns the spell queued, if any.
songs.tick = function(bard, wanted, recastBefore)
    local master = bard:getMaster()
    local action = bard:getCurrentAction()

    if not master or not master:isAlive() or action == 30 or action == 3 or action == 34 or action == 6 then
        return nil
    end

    local mine = {}
    local count = 0

    for _, s in ipairs(songs.on(master)) do
        if s[3] == songs.singer(bard) and s[4] > (recastBefore or 0) * 1000 then
            mine[s[1] * 100 + s[2]] = true
            count = count + 1
        end
    end

    if count >= 2 then
        return nil
    end

    for _, spellId in ipairs(wanted(bard, master)) do
        local info = spellId and songs.info[spellId]

        if info and not mine[info[1] * 100 + info[2]] and not bard:hasRecast(xi.recast.MAGIC, spellId) then
            bard:castSpell(spellId, bard) -- queued: it starts on the next tick, before the next COMBAT_TICK

            return spellId
        end
    end

    return nil
end

return songs
