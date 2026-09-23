-----------------------------------
-- Trust: Apururu UC
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local isWearingApururuShirt = function(player)
    local wearingBody = player:getEquipID(xi.slot.BODY) == xi.item.APURURU_UNITY_SHIRT
    return wearingBody
end

-- Retail (BG Wiki): Curaga when 3 or more party members are under 75% HP or asleep
local curagaByLevel =
{
    { level = 91, spell = xi.magic.spell.CURAGA_V   },
    { level = 71, spell = xi.magic.spell.CURAGA_IV  },
    { level = 51, spell = xi.magic.spell.CURAGA_III },
    { level = 31, spell = xi.magic.spell.CURAGA_II  },
    { level = 16, spell = xi.magic.spell.CURAGA     },
}

local curagaCooldown   = 5   -- seconds between her own Curaga checks, so a failed cast is not retried every tick
local abilityRecast    = 600 -- Martyr and Devotion: 10 minutes, as for a player
local abilityRange     = 10.6
local lowMPP           = 10  -- Martyr only at very low MP
local devotionTargetMP = 20

local function isAsleep(member)
    return member:hasStatusEffect(xi.effect.SLEEP_I) or member:hasStatusEffect(xi.effect.SLEEP_II)
end

-- Curaga, Martyr and Devotion depend on the whole party (or on another member's MP), which a single gambit cannot express.
-- A trust's COMBAT_TICK runs right after its gambits, usually while it has just started a cast. castSpell and
-- useJobAbility queue the action, and the engine runs it as soon as that cast ends; the timers below stop repeats.
local function partyCombatTick(mob)
    local master = mob:getMaster()
    if master == nil then
        return
    end

    local now     = os.time()
    local members = {}

    for _, member in ipairs(master:getPartyWithTrusts()) do
        if member:isAlive() and member:getZoneID() == mob:getZoneID() and mob:checkDistance(member) <= 20 then
            table.insert(members, member)
        end
    end

    -- Curaga: 3 or more members in yellow HP or asleep. Aimed at the most hurt one.
    if now >= mob:getLocalVar('[Apururu]nextCuraga') then
        local hurt   = 0
        local target = nil

        for _, member in ipairs(members) do
            if member:getHPP() < 75 or isAsleep(member) then
                hurt = hurt + 1

                if target == nil or member:getHPP() < target:getHPP() then
                    target = member
                end
            end
        end

        if hurt >= 3 then
            for _, entry in ipairs(curagaByLevel) do
                local spell = GetSpell(entry.spell)

                if mob:getMainLvl() >= entry.level and spell and mob:getMP() >= spell:getMPCost() then
                    mob:setLocalVar('[Apururu]nextCuraga', now + curagaCooldown)
                    mob:castSpell(entry.spell, target)

                    return
                end
            end
        end
    end

    -- Martyr: only when her own MP is very low, on the most hurt member in range (not herself)
    if
        mob:getMainLvl() >= 75 and
        mob:getMPP() < lowMPP and
        now >= mob:getLocalVar('[Apururu]nextMartyr')
    then
        local target = nil

        for _, member in ipairs(members) do
            if
                member:getID() ~= mob:getID() and
                member:getHPP() < 50 and
                mob:checkDistance(member) <= abilityRange and
                (target == nil or member:getHPP() < target:getHPP())
            then
                target = member
            end
        end

        if target then
            mob:setLocalVar('[Apururu]nextMartyr', now + abilityRecast)
            mob:useJobAbility(xi.ja.MARTYR, target)

            return
        end
    end

    -- Devotion: on a member with under 20% MP. Members with no MP at all (WAR, MNK...) are skipped.
    if mob:getMainLvl() >= 75 and now >= mob:getLocalVar('[Apururu]nextDevotion') then
        local target = nil

        for _, member in ipairs(members) do
            if
                member:getID() ~= mob:getID() and
                member:getMaxMP() > 0 and
                member:getMPP() < devotionTargetMP and
                mob:checkDistance(member) <= abilityRange and
                (target == nil or member:getMPP() < target:getMPP())
            then
                target = member
            end
        end

        if target then
            mob:setLocalVar('[Apururu]nextDevotion', now + abilityRecast)
            mob:useJobAbility(xi.ja.DEVOTION, target)
        end
    end
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if isWearingApururuShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_2)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Unity ranking high : xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)

    -- TODO: UC trusts are supposed to get bonuses depending on unity ranking. Needs research.
    -- TODO: Custom spawn messages if Unity ranking is higher.
    -- Curaga (3+ hurt), Martyr and Devotion: see partyCombatTick above

    mob:addGambit(ai.t.SELF, { { ai.c.MPP_LT, 51 }, { ai.c.LVL_GTE, 50 }, { ai.c.TP_GTE, 1000 } }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.NOTT })

    -- Retail: Convert only at very low MP (<10%)
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, lowMPP }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CONVERT })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURAGA })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })

    -- Retail: Haste on the player, herself and melee damage dealers
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STONESKIN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONESKIN })

    -- BGwiki states 75/tick regain.  Only used for Nott WS.
    mob:addMod(xi.mod.REGAIN, 75)

    mob:addListener('COMBAT_TICK', 'APURURU_PARTY_CTICK', partyCombatTick)

    mob:setAutoAttackEnabled(false)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
