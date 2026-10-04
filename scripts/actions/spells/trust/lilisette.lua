-----------------------------------
-- Trust: Lilisette
-- Retail (BG Wiki BGWiki:Trusts): DNC/DNC. Waits until about 1500 TP for a TP move, no skillchain attempts (Whirling
-- Edge, AoE here; Dancer's Fury). Rousing Samba; Vivifying Waltz at 1500 TP when 2+ party members are in yellow HP
-- (under 75%), or from 1000 TP when one is under 50%. Samba and Waltz use Lilisette II's trust versions (3312 / 3313:
-- self-targeted, the Waltz heals the party around her; estimated numbers, see the mob skill scripts).
-- Left out: Sensual Dance and Thorn Dance (no scripts).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local ROUSING_SAMBA   = 3312
local VIVIFYING_WALTZ = 3313

local waltzRange = 10

-- Trusts use mob skills without calling their onMobSkillCheck, so the conditions are kept here as gambits that exist
-- only while they apply: [entity id] = { samba = gambit id or nil, waltz = gambit id or nil }
local gambitIds = {}

local function hurtNearby(mob, hpp)
    local count  = 0
    local master = mob:getMaster()

    for _, member in ipairs(master and master:getPartyWithTrusts() or {}) do
        if member:isAlive() and member:getHPP() < hpp and mob:checkDistance(member) <= waltzRange then
            count = count + 1
        end
    end

    return count
end

-- The Waltz gambit exists while it is wanted: 1500 TP for 2+ party members under 75%, 1000 TP for one under 50%
local function updateWaltz(mob)
    local ids = gambitIds[mob:getID()]

    if not ids then
        return
    end

    local needTP = nil

    if hurtNearby(mob, 50) >= 1 then
        needTP = 1000
    elseif hurtNearby(mob, 75) >= 2 then
        needTP = 1500
    end

    if ids.waltz and ids.waltzTP ~= needTP then
        mob:removeGambit(ids.waltz)
        ids.waltz = nil
    end

    if needTP and not ids.waltz then
        ids.waltz   = mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, needTP }, { ai.r.MS, ai.s.SPECIFIC, VIVIFYING_WALTZ })
        ids.waltzTP = needTP
    end
end

local function cleanup(mob)
    mob:removeListener('LILISETTE_WALTZ')
    mob:removeListener('LILISETTE_SKILLS')
    gambitIds[mob:getID()] = nil
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    gambitIds[mob:getID()] =
    {
        samba = mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 350 }, { ai.r.MS, ai.s.SPECIFIC, ROUSING_SAMBA }),
    }

    -- COMBAT_TICK comes from the trust controller, so changing gambits there is safe (TICK also fires while despawning)
    mob:addListener('COMBAT_TICK', 'LILISETTE_WALTZ', function(mobArg)
        updateWaltz(mobArg)
    end)

    mob:addListener('WEAPONSKILL_USE', 'LILISETTE_SKILLS', function(mobArg, target, skill)
        local id  = type(skill) == 'number' and skill or skill:getID()
        local ids = gambitIds[mobArg:getID()]

        if not ids then
            return
        end

        -- Her samba stays up while she is summoned; a used Waltz is re-added by the next combat tick if still wanted
        if id == ROUSING_SAMBA and ids.samba then
            mobArg:removeGambit(ids.samba)
            ids.samba = nil
        elseif id == VIVIFYING_WALTZ and ids.waltz then
            mobArg:removeGambit(ids.waltz)
            ids.waltz = nil
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 1500)
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
