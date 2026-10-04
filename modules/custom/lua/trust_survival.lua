-----------------------------------
-- Tougher trusts (Eric's choice, 2026-10-04; not retail). Measured before this: against the boss arenas' Tier 1 and
-- Tier 4 bosses (melee only, no healing) Trion lasted 10-13 s, Kupipi 5-8 s and Shantotto 2-5 s.
-- Every trust gets, on top of what its own script sets:
--   - max HP x2 (a flat HP bonus equal to its max HP at summon; HPP would only double the base part)
--   - damage taken -25% (DMG -2500: physical, magic, ranged and breath)
--   - Regen of 1% of its (doubled) max HP per tick
-- Applied after xi.trust.spawn, like the trust Refresh bonus (trust_refresh.lua), once per trust.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
-----------------------------------

local m = Module:new('trust_survival')

local survival = {}

survival.config =
{
    hpMultiplier = 2,   -- max HP x2
    damage       = -2500, -- DMG, in 1/100 %: -25% damage taken
    regenShare   = 0.01,  -- Regen per tick, as a share of max HP
}

survival.apply = function(trust)
    local config = survival.config

    trust:addMod(xi.mod.HP, math.floor(trust:getMaxHP() * (config.hpMultiplier - 1)))
    trust:updateHealth()
    trust:setHP(trust:getMaxHP())
    trust:addMod(xi.mod.DMG, config.damage)
    trust:addMod(xi.mod.REGEN, math.max(1, math.floor(trust:getMaxHP() * config.regenShare)))
    trust:setLocalVar('[custom]TrustSurvival', 1)
end

m:addOverride('xi.trust.spawn', function(caster, spell)
    local result = super(caster, spell)

    for _, member in ipairs(caster:getPartyWithTrusts()) do
        if
            member:isTrust() and
            member:getMaster() and
            member:getMaster():getID() == caster:getID() and
            member:getLocalVar('[custom]TrustSurvival') == 0
        then
            survival.apply(member)
        end
    end

    return result
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.trustSurvival = survival -- for tests

return m
