-----------------------------------
-- Trust: Morimar
-- Retail behaviour (BG Wiki BGWiki:Trusts): WAR/BST, HP+10%. Saves up to 2000 TP waiting to close a skillchain.
-- Vehement Resolution (3 minute cooldown) consumes his TP, fully heals him, erases his debuffs and makes him glow; while
-- glowing he does not try to close skillchains and his next weapon skill is 12 Blades of Remorse at 2000 TP.
-- Weapon skills: Camaraderie of the Crevasse, Into the Light, Arduous Decision (Silence) from mob_skill_lists 1105, and
-- 12 Blades of Remorse through a gambit. Their damage numbers are estimates (see the mob skill scripts).
-- Not done: when he uses Vehement Resolution is not documented; here it is as soon as he holds 1000 TP and it is ready.
-- His synergy with Darrcuiln, and the glow's visual.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local VEHEMENT_RESOLUTION  = 3676
local BLADES_OF_REMORSE_12 = 3680

-- Trusts use mob skills without calling their onMobSkillCheck, so the glow is enforced here, not in the skills:
-- while he glows no TP threshold can be reached (3001) and a gambit fires 12 Blades of Remorse at 2000 TP instead.
local bladesGambit = {} -- [entity id] = gambit id while glowing

local function startGlow(mob)
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 3001)
    bladesGambit[mob:getID()] = mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.MS, ai.s.SPECIFIC, BLADES_OF_REMORSE_12 })
end

local function endGlow(mob)
    local id = bladesGambit[mob:getID()]

    if id then
        mob:removeGambit(id)
        bladesGambit[mob:getID()] = nil
    end

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 10)
    mob:setLocalVar('[Morimar]Resolve', 0)
    bladesGambit[mob:getID()] = nil

    -- 3 minute cooldown as the gambit's retry delay. While he holds 1000+ TP the engine is not using weapon skills
    -- (it holds for a skillchain up to 2000), so the gambit gets its turn.
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 1000 }, { ai.r.MS, ai.s.SPECIFIC, VEHEMENT_RESOLUTION }, 180)

    -- Changing gambits is safe here: the event comes from his own skill use, never while he despawns
    mob:addListener('WEAPONSKILL_USE', 'MORIMAR_RESOLVE', function(mobArg, target, skill, tp, action, damage)
        local id = type(skill) == 'number' and skill or skill:getID()

        if id == VEHEMENT_RESOLUTION then
            startGlow(mobArg)
        elseif id == BLADES_OF_REMORSE_12 then
            endGlow(mobArg)
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
    mob:removeListener('MORIMAR_RESOLVE')
    bladesGambit[mob:getID()] = nil
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    mob:removeListener('MORIMAR_RESOLVE')
    bladesGambit[mob:getID()] = nil
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
