-----------------------------------
-- Trust: Lilisette II
-- Retail behaviour (BG Wiki BGWiki:Trusts): DNC/WAR. Holds up to 2000 TP to close skillchains. Weapon skills made single
-- target for the Alter Ego II version (mob_skill_lists 1128): Whirling Edge, Dancer's Fury. Vivifying Waltz when 3 party
-- members are in yellow HP (under 75%), with at least 1000 TP. Rousing Samba costs 350 TP, so she keeps it up easily.
-- The numbers of all four are estimates, and Rousing Samba only boosts her own critical hit rate (see the mob skill scripts).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local ROUSING_SAMBA   = 3312
local VIVIFYING_WALTZ = 3313

local waltzRange    = 10
local hurtHPP       = 75
local neededHurt    = 3

-- Trusts use mob skills without calling their onMobSkillCheck, so the conditions are kept here as gambits that exist
-- only while they apply: [entity id] = { samba = gambit id or nil, waltz = gambit id or nil }
local gambitIds = {}

local function hurtNearby(mob)
    local count  = 0
    local master = mob:getMaster()

    for _, member in ipairs(master and master:getPartyWithTrusts() or {}) do
        if member:isAlive() and member:getHPP() < hurtHPP and mob:checkDistance(member) <= waltzRange then
            count = count + 1
        end
    end

    return count
end

-- Adds the Waltz gambit while 3 party members nearby are hurt, removes it otherwise
local function updateWaltz(mob)
    local ids = gambitIds[mob:getID()]

    if not ids then
        return
    end

    local wanted = hurtNearby(mob) >= neededHurt

    if wanted and not ids.waltz then
        ids.waltz = mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 1000 }, { ai.r.MS, ai.s.SPECIFIC, VIVIFYING_WALTZ })
    elseif not wanted and ids.waltz then
        mob:removeGambit(ids.waltz)
        ids.waltz = nil
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:setLocalVar('[Lilisette]RousingSamba', 0)

    gambitIds[mob:getID()] =
    {
        samba = mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 350 }, { ai.r.MS, ai.s.SPECIFIC, ROUSING_SAMBA }),
    }

    -- COMBAT_TICK comes from the trust controller, so changing gambits there is safe (TICK also fires while despawning)
    mob:addListener('COMBAT_TICK', 'LILISETTE_II_WALTZ', function(mobArg)
        updateWaltz(mobArg)
    end)

    mob:addListener('WEAPONSKILL_USE', 'LILISETTE_II_SKILLS', function(mobArg, target, skill, tp, action, damage)
        local id  = type(skill) == 'number' and skill or skill:getID()
        local ids = gambitIds[mobArg:getID()]

        if not ids then
            return
        end

        -- Her samba stays up for as long as she is summoned: no need to use it again
        if id == ROUSING_SAMBA and ids.samba then
            mobArg:removeGambit(ids.samba)
            ids.samba = nil
        elseif id == VIVIFYING_WALTZ and ids.waltz then
            mobArg:removeGambit(ids.waltz)
            ids.waltz = nil
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

local function cleanup(mob)
    mob:removeListener('LILISETTE_II_WALTZ')
    mob:removeListener('LILISETTE_II_SKILLS')
    gambitIds[mob:getID()] = nil
end

spellObject.onMobDespawn = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
