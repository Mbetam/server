-----------------------------------
-- Trust: Kukki-Chebukki
-- Retail behaviour (BG Wiki BGWiki:Trusts): BLM/BLM. Stays ~15' away from the monster and never melees. Only uses spells
-- of the current day's element: elemental nukes and that element's debuff (Burn, Frost, ...), lower tiers against a
-- monster with low HP to save MP. On Darksday only Sleepga / Sleepga II; on Lightsday nothing (he has no Light spells).
-- Not done: when he uses the -ga / -ja spells is not documented, so he doesn't use them; the Meteor emote with
-- Makki-Chebukki and Cherukiki.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Per element: the single-target nuke family (the engine picks the highest tier he knows), the tier I spell for low-HP
-- monsters (the engine has no "lowest tier" selector for spells yet), and the element's debuff with its effect.
local dayNukes =
{
    [xi.element.FIRE]    = { family = xi.magic.spellFamily.FIRE,     tierOne = xi.magic.spell.FIRE,     debuff = xi.magic.spell.BURN,  debuffEffect = xi.effect.BURN  },
    [xi.element.ICE]     = { family = xi.magic.spellFamily.BLIZZARD, tierOne = xi.magic.spell.BLIZZARD, debuff = xi.magic.spell.FROST, debuffEffect = xi.effect.FROST },
    [xi.element.WIND]    = { family = xi.magic.spellFamily.AERO,     tierOne = xi.magic.spell.AERO,     debuff = xi.magic.spell.CHOKE, debuffEffect = xi.effect.CHOKE },
    [xi.element.EARTH]   = { family = xi.magic.spellFamily.STONE,    tierOne = xi.magic.spell.STONE,    debuff = xi.magic.spell.RASP,  debuffEffect = xi.effect.RASP  },
    [xi.element.THUNDER] = { family = xi.magic.spellFamily.THUNDER,  tierOne = xi.magic.spell.THUNDER,  debuff = xi.magic.spell.SHOCK, debuffEffect = xi.effect.SHOCK },
    [xi.element.WATER]   = { family = xi.magic.spellFamily.WATER,    tierOne = xi.magic.spell.WATER,    debuff = xi.magic.spell.DROWN, debuffEffect = xi.effect.DROWN },
}

-- The day's gambits of each summoned Kukki-Chebukki: [entity id] = { element = ..., ids = { gambit ids } }
local dayGambits = {}

-- Swaps his gambits for the current day's element. Cheap to call often: does nothing while the day is the same.
local function setDayGambits(mob)
    local element = VanadielDayElement()
    local current = dayGambits[mob:getID()]

    if current and current.element == element then
        return
    end

    if current then
        for _, id in ipairs(current.ids) do
            mob:removeGambit(id)
        end
    end

    local ids   = {}
    local nukes = dayNukes[element]

    if nukes then
        table.insert(ids, mob:addGambit(ai.t.TARGET, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.SPECIFIC, nukes.tierOne }))
        -- No retry delay (see halver.lua): the spell's recast and NOT_STATUS already keep it from being spammed
        table.insert(ids, mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, nukes.debuffEffect }, { ai.r.MA, ai.s.SPECIFIC, nukes.debuff }))
        table.insert(ids, mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, nukes.family }))
    elseif element == xi.element.DARK then
        table.insert(ids, mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLEEPGA }))
    end

    dayGambits[mob:getID()] = { element = element, ids = ids }
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    dayGambits[mob:getID()] = nil
    setDayGambits(mob)

    -- The day can change mid-fight. COMBAT_TICK comes from the trust controller itself, so it is safe to change gambits
    -- there. (TICK fires even while he is despawning, when changing gambits crashes the server.) It fires after that
    -- tick's gambits, so at a day change he can cast one more spell of the old element.
    mob:addListener('COMBAT_TICK', 'KUKKI_CHEBUKKI_DAY', function(mobArg)
        setDayGambits(mobArg)
    end)

    mob:setAutoAttackEnabled(false)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 15)
end

spellObject.onMobDespawn = function(mob)
    mob:removeListener('KUKKI_CHEBUKKI_DAY')
    dayGambits[mob:getID()] = nil
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    mob:removeListener('KUKKI_CHEBUKKI_DAY')
    dayGambits[mob:getID()] = nil
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
