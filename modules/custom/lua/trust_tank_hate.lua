-----------------------------------
-- Tank trusts hold hate (Eric's request, 2026-10-04; not retail). Measured with scripts/tests/benchmarks/tank_hate.lua
-- (a WAR with ATT 2200, a tank trust and Kupipi on a Tier 1 arena boss, 3 minutes): every tank trust lost the boss
-- most of the time. Provoke and Flash themselves worked; the enmity maths did not favour them. Both sides sit at the
-- volatile enmity cap (30000), so cumulative enmity decides, and Provoke gives only CE 1 and Flash CE 180, while every
-- hit a tank takes removes CE (1800 x damage / max HP). The player's damage CE kept growing (~15000) while the tank's
-- stayed at 3000-8000.
-- For the trusts listed in `tanks`:
--   - Provoke (also the automaton's) and Flash add cumulative enmity: twice their volatile (Provoke 3600, Flash 2560);
--     Provoke also adds another 1800 volatile, since the ninja tanks have no Flash
--   - enmity loss when hit -50% (ENMITY_LOSS_REDUCTION)
--   - while fighting, a Provoke's worth of hate every 10 s (tankHate.pulse)
--   - steal: a Provoke / Flash / pulse landing while the mob is on someone else strips 25% of that one's enmity
--   - the ones in `addProvoke` (Flash-only paladins, Halver who provokes only when someone is low) also get Provoke on
--     cooldown, like Trion
-- Applied after xi.trust.spawn, like the other trust modules (trust_survival.lua), once per trust.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
require('scripts/globals/gambits')
-----------------------------------

local m = Module:new('trust_tank_hate')

local tankHate = {}

tankHate.config =
{
    lossReduction = 50, -- ENMITY_LOSS_REDUCTION, %
    provokeCE     = 3600,
    provokeVE     = 1800, -- on top of Provoke's own 1800: ninja tanks have no Flash to keep their volatile up
    flashCE       = 2560,
    pulseEvery    = 10,   -- s: while fighting, a Provoke's worth of hate this often (0 = off); see tankHate.pulse
    steal         = 25,   -- % of CE and VE a Provoke / Flash strips from whoever the mob is on, if not the tank (0 = off)
    tanks         =
    {
        'TRION', 'VALAINERAL', 'CURILLA', 'EXCENMILLE', 'RAHAL', 'AMCHUCHU', 'AAEV', 'AUGUST', 'RUGHADJEEN',
        'GESSHO', 'HALVER', 'MNEJING', 'AAHM',
    },
    addProvoke = { 'CURILLA', 'EXCENMILLE', 'RUGHADJEEN', 'AAEV', 'HALVER' },
}

local function idSet(names)
    local set = {}

    for _, name in ipairs(names) do
        set[xi.magic.spell[name]] = true
    end

    return set
end

local function addEnmity(trust, target, ce, ve)
    if not (target and target:isMob() and target:isAlive()) then
        return
    end

    target:addEnmity(trust, ce, ve or 0)

    local steal  = tankHate.config.steal
    local victim = target:getTarget()

    if steal > 0 and victim and victim:getID() ~= trust:getID() then
        target:lowerEnmity(victim, steal)
    end
end

-- Hate pulse: a trust's Provoke recast can't be shortened from Lua (resetRecast is players only), so while a tank is
-- engaged it gets a Provoke's worth of hate (stock 1 CE / 1800 VE plus the bonus above, and the steal) every
-- pulseEvery seconds; its real Provoke still shows every 30 s. Measured against a nuker landing 6000 every 8 s:
-- tanks held the boss 55% without, 81% with a 10 s pulse (tank weapon skill damage +100 / +300% changed nothing).
-- The timer sits on the trust's own action queue, so it goes away with the trust.
tankHate.pulse = function(trust)
    local every = tankHate.config.pulseEvery

    if every <= 0 then
        return
    end

    trust:timer(every * 1000, function(entity)
        if not entity:isAlive() then
            return
        end

        local mob = entity:getTarget()

        if entity:isEngaged() and mob and mob:isMob() and mob:isAlive() then
            addEnmity(entity, mob, 1 + tankHate.config.provokeCE, 1800 + tankHate.config.provokeVE)
            entity:setLocalVar('[custom]TankPulses', entity:getLocalVar('[custom]TankPulses') + 1)
        end

        tankHate.pulse(entity)
    end)
end

tankHate.apply = function(trust)
    local config = tankHate.config

    trust:addMod(xi.mod.ENMITY_LOSS_REDUCTION, config.lossReduction)

    trust:addListener('ABILITY_USE', 'TANK_HATE_JA', function(entity, target, ability)
        if ability:getID() == xi.jobAbility.PROVOKE then
            addEnmity(entity, target, config.provokeCE, config.provokeVE)
        end
    end)

    trust:addListener('MAGIC_USE', 'TANK_HATE_MA', function(entity, target, spell)
        if spell:getID() == xi.magic.spell.FLASH then
            addEnmity(entity, target, config.flashCE)
        end
    end)

    trust:addListener('WEAPONSKILL_USE', 'TANK_HATE_MS', function(entity, target, skill)
        if skill:getID() == xi.mobSkill.PROVOKE_AUTOMATON then
            addEnmity(entity, target, config.provokeCE, config.provokeVE)
        end
    end)

    if idSet(config.addProvoke)[trust:getTrustID()] then
        trust:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    tankHate.pulse(trust)
    trust:setLocalVar('[custom]TankHate', 1)
end

m:addOverride('xi.trust.spawn', function(caster, spell)
    local result = super(caster, spell)
    local tanks  = idSet(tankHate.config.tanks)

    for _, member in ipairs(caster:getPartyWithTrusts()) do
        if
            member:isTrust() and
            member:getMaster() and
            member:getMaster():getID() == caster:getID() and
            tanks[member:getTrustID()] and
            member:getLocalVar('[custom]TankHate') == 0
        then
            tankHate.apply(member)
        end
    end

    return result
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.tankHate = tankHate -- for tests and the benchmark

return m
