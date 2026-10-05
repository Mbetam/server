-----------------------------------
-- Helpers for caster trusts (2026-10-04), required by their scripts in scripts/actions/spells/trust/.
-- Not a module (not in init.txt): a plain library, like modules/custom/htbf/mobskill_kit.lua.
--
-- Why it exists: the engine's magic burst gambit (ai.s.MB_ELEMENT) only looks at single-target damage spells, so a trust
-- whose retail bursts are -ga / -ja spells (Teodor, Robel-Akbel, Mumor II...) or that may burst with only some elements
-- (Kayeel-Payeel) can't be done with gambits. kit.burstTick does it from a COMBAT_TICK listener instead.
-- castSpell (used here) queues the cast and clears that spell's recast first, so every check below looks at recast, MP
-- and level itself before asking for a cast.
-----------------------------------

local kit = {}

-- A spell entry is { id, minLevel[, maxLevel] }, the same ranges as the trust's mob_spell_lists rows.
kit.canCast = function(mob, entry)
    local spell = GetSpell(entry[1])
    local level = mob:getMainLvl()

    return spell ~= nil and
        level >= entry[2] and
        level <= (entry[3] or 255) and
        mob:getMP() >= spell:getMPCost() and
        not mob:hasRecast(xi.recast.MAGIC, entry[1])
end

-- Casting, weapon skill or job ability in progress (lua_base_entity getCurrentAction: 30 magic, 3 weapon skill, 6 ability)
kit.isBusy = function(mob)
    local action = mob:getCurrentAction()

    return action == 30 or action == 3 or action == 6
end

-- The skillchain on the target if a magic burst is possible now (same rule as the engine: a resonance with a tier)
kit.resonance = function(target)
    local effect = target and target:getStatusEffect(xi.effect.SKILLCHAIN)

    if effect and effect:getTier() > 0 then
        return effect
    end
end

kit.burstsElement = function(resonance, element)
    local row = xi.data.element.skillchainElementTable[element]

    return row ~= nil and (row[resonance:getPower()] or 0) > 0
end

-- The first spell of `spells` (ordered by preference) that bursts this resonance and can be cast now
kit.pickBurst = function(mob, resonance, spells)
    for _, entry in ipairs(spells) do
        local spell = GetSpell(entry[1])

        if spell and kit.burstsElement(resonance, spell:getElement()) and kit.canCast(mob, entry) then
            return entry[1]
        end
    end
end

-- Called from COMBAT_TICK: bursts the battle target's skillchain with `spells`, at most `perChain` landed bursts per
-- skillchain (retail: Ark Angel TT and Arciela II often try two). A burst counts only once the spell lands (MAGIC_USE,
-- see kit.onCombatTick), so an interrupted cast is tried again while the window lasts; at most 3 attempts per burst
-- so a refused cast can't be queued every tick. Returns true if a cast was queued.
kit.burstTick = function(mob, spells, perChain)
    local target    = mob:getTarget()
    local resonance = kit.resonance(target)

    if not resonance then
        return false
    end

    -- One skillchain = one resonance start time on one target
    local key = (resonance:getStartTime() % 1000000) * 100 + (target:getTargID() % 100)

    if mob:getLocalVar('[Kit]BurstKey') ~= key then
        mob:setLocalVar('[Kit]BurstKey', key)
        mob:setLocalVar('[Kit]BurstCount', 0)
        mob:setLocalVar('[Kit]BurstTries', 0)
        mob:setLocalVar('[Kit]BurstPending', 0)
    end

    -- Busy (a gambit got this tick first): castSpell still queues the burst right after the current action, but only
    -- one queued burst at a time
    if kit.isBusy(mob) and mob:getLocalVar('[Kit]BurstPending') ~= 0 then
        return false
    end

    if
        mob:getLocalVar('[Kit]BurstCount') >= (perChain or 1) or
        mob:getLocalVar('[Kit]BurstTries') >= 3 * (perChain or 1)
    then
        return false
    end

    local spellId = kit.pickBurst(mob, resonance, spells)

    if spellId then
        mob:setLocalVar('[Kit]BurstTries', mob:getLocalVar('[Kit]BurstTries') + 1)
        mob:setLocalVar('[Kit]BurstPending', spellId)
        mob:castSpell(spellId, target)

        return true
    end

    return false
end

-- Called from COMBAT_TICK: once per battle target, opens with the first castable spell of `spells` (retail:
-- D. Shantotto starts every fight with a tier V nuke before meleeing). Done once the spell lands; an interrupted
-- opener is tried again, at most 3 times per target. Returns true if a cast was queued.
kit.openerTick = function(mob, spells)
    local target = mob:getTarget()

    if not target or kit.isBusy(mob) or mob:getLocalVar('[Kit]OpenedOn') == target:getID() then
        return false
    end

    if mob:getLocalVar('[Kit]OpenerTarget') ~= target:getID() then
        mob:setLocalVar('[Kit]OpenerTarget', target:getID())
        mob:setLocalVar('[Kit]OpenerTries', 0)
    end

    if mob:getLocalVar('[Kit]OpenerTries') >= 3 then
        return false
    end

    for _, entry in ipairs(spells) do
        if kit.canCast(mob, entry) then
            mob:setLocalVar('[Kit]OpenerTries', mob:getLocalVar('[Kit]OpenerTries') + 1)
            mob:setLocalVar('[Kit]OpenerPending', entry[1])
            mob:castSpell(entry[1], target)

            return true
        end
    end

    return false
end

-- A conditional TP move: while `condition(mob)` holds, the trust has a gambit for mob skill `skillId`, ahead of its other
-- gambits (addGambit's custom `first` argument, gambits_container.cpp) (retry `retry` s,
-- which is its cooldown); otherwise the gambit is removed. From COMBAT_TICK only (changing gambits there is safe, see
-- the trust notes). Needed because useMobAbility is dropped when the trust is mid-cast, and a caster almost always is
-- when its COMBAT_TICK runs (right after its gambits started the next cast); a gambit fires when the trust is free.
local skillGambits = {} -- [entity id .. name] = gambit id

kit.skillWhen = function(mob, name, skillId, retry, condition)
    kit.onCombatTick(mob, name, function(mobArg)
        local key    = mobArg:getID() .. name
        local wanted = condition(mobArg)

        if wanted and not skillGambits[key] then
            skillGambits[key] = mobArg:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.MS, ai.s.SPECIFIC, skillId }, retry, true)
        elseif not wanted and skillGambits[key] then
            mobArg:removeGambit(skillGambits[key])
            skillGambits[key] = nil
        end
    end)
end

-- Like kit.skillWhen, for any gambit: while `condition(mob)` holds, the trust has gambit (target, predicates, reaction,
-- retry) ahead of its others; removed otherwise. E.g. Nashmeira II's Curaga only when 3+ party members are hurt.
kit.gambitWhen = function(mob, name, target, predicates, reaction, retry, condition)
    kit.onCombatTick(mob, name, function(mobArg)
        local key    = mobArg:getID() .. name
        local wanted = condition(mobArg)

        if wanted and not skillGambits[key] then
            skillGambits[key] = mobArg:addGambit(target, predicates, reaction, retry, true)
        elseif not wanted and skillGambits[key] then
            mobArg:removeGambit(skillGambits[key])
            skillGambits[key] = nil
        end
    end)
end

-- Party members within `range` of the trust: how many are under `hpp` % HP, and whether one is asleep
kit.partyHurt = function(mob, hpp, range)
    local hurt, asleep = 0, false
    local master       = mob:getMaster()

    for _, member in ipairs(master and master:getPartyWithTrusts() or {}) do
        if member:isAlive() and mob:checkDistance(member) <= (range or 15) then
            if member:getHPP() < hpp then
                hurt = hurt + 1
            end

            if member:hasStatusEffect(xi.effect.SLEEP_I) or member:hasStatusEffect(xi.effect.SLEEP_II) then
                asleep = true
            end
        end
    end

    return hurt, asleep
end

-- Adds a COMBAT_TICK listener under `name`, removed again when the trust despawns or dies (the trust scripts call
-- kit.cleanup from onMobDespawn / onMobDeath). COMBAT_TICK only comes from the trust controller (see the trust notes on
-- TICK listeners crashing the server).
kit.onCombatTick = function(mob, name, fn)
    mob:addListener('COMBAT_TICK', name, fn)

    -- A queued burst or opener counts once it lands
    mob:addListener('MAGIC_USE', name .. '_LANDED', function(mobArg, target, spell)
        if spell:getID() == mobArg:getLocalVar('[Kit]BurstPending') then
            mobArg:setLocalVar('[Kit]BurstPending', 0)
            mobArg:setLocalVar('[Kit]BurstCount', mobArg:getLocalVar('[Kit]BurstCount') + 1)
        end

        if spell:getID() == mobArg:getLocalVar('[Kit]OpenerPending') and target then
            mobArg:setLocalVar('[Kit]OpenerPending', 0)
            mobArg:setLocalVar('[Kit]OpenedOn', target:getID())
        end
    end)

    mob:setLocalVar('[Kit]HasTick', 1)
end

kit.cleanup = function(mob, name)
    if mob:getLocalVar('[Kit]HasTick') == 1 then
        mob:removeListener(name)
        mob:removeListener(name .. '_LANDED')
    end

    skillGambits[mob:getID() .. name] = nil
end

return kit
