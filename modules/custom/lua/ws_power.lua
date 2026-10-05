-----------------------------------
-- Melee and magic weapon skills x1.45 (Eric, 2026-10-05; not retail). Roddy on a level 99 dummy: tier VI nukes 23k+,
-- tier V 16k+, melee weapon skills about 16k; Eric wants melee weapon skills on par with tier VI magic (23k / 16k ~ 1.45)
-- and magic weapon skills up too. Magic (spells) stays as it is.
-- Every weapon skill path multiplies its final damage by xi.settings.main.WEAPON_SKILL_POWER (weaponskills.lua); while
-- a physical (melee, hybrid included) or magical weapon skill runs, that setting is multiplied by the factor below and
-- put back right after. A true multiplier: it does not share the gear "weapon skill damage +%" bucket.
-- Ranged weapon skills are left out: they have their own +25% (ranged_ws_bonus.lua).
-- Trusts that use player weapon skills go through the same code, so theirs rise too; monsters' TP moves don't.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/weaponskills')
-----------------------------------

local m = Module:new('ws_power')

local wsPower = {}

wsPower.physical = 1.45
wsPower.magical  = 1.45

-- Runs fn with WEAPON_SKILL_POWER multiplied by factor, and always puts it back (also if fn errors)
local function withPower(factor, fn, ...)
    local base = xi.settings.main.WEAPON_SKILL_POWER

    xi.settings.main.WEAPON_SKILL_POWER = base * factor

    local results = { pcall(fn, ...) }

    xi.settings.main.WEAPON_SKILL_POWER = base

    if not results[1] then
        error(results[2], 0)
    end

    return unpack(results, 2, table.maxn(results))
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill', function(attacker, target, wsID, wsParams, tp, action, primaryMsg, taChar)
    return withPower(wsPower.physical, super, attacker, target, wsID, wsParams, tp, action, primaryMsg, taChar)
end)

m:addOverride('xi.weaponskills.doMagicWeaponskill', function(attacker, target, wsID, wsParams, tp, action, primaryMsg)
    return withPower(wsPower.magical, super, attacker, target, wsID, wsParams, tp, action, primaryMsg)
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.wsPower = wsPower -- for tests

return m
