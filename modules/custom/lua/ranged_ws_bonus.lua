-----------------------------------
-- Ranged weapon skills +25% damage (Eric's choice, 2026-10-04; not retail). Archery and marksmanship weapon skills all
-- go through xi.weaponskills.doRangedWeaponskill; while it runs, the attacker carries ALL_WSDMG_ALL_HITS +bonus (the
-- engine's own "weapon skill damage +N%" mod, applied to the final damage of every hit), and loses it again right
-- after, so melee and magical weapon skills are untouched.
-- Measured before (Eric's RNG/NIN, level 99 dummy): Empyreal Arrow 2,720 / 8,404 at 1000 / 3000 TP; on a level 125
-- arena boss 1,366 / 4,486 (level correction and DEF), where melee did even less (Decimation 329 / 387).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/weaponskills')
-----------------------------------

local m = Module:new('ranged_ws_bonus')

local rangedWs = {}

rangedWs.bonus = 25 -- percent

m:addOverride('xi.weaponskills.doRangedWeaponskill', function(attacker, target, wsID, wsParams, tp, action, primaryMsg)
    attacker:addMod(xi.mod.ALL_WSDMG_ALL_HITS, rangedWs.bonus)

    local results = { pcall(super, attacker, target, wsID, wsParams, tp, action, primaryMsg) }

    attacker:delMod(xi.mod.ALL_WSDMG_ALL_HITS, rangedWs.bonus)

    if not results[1] then
        error(results[2], 0)
    end

    return unpack(results, 2, table.maxn(results))
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.rangedWs = rangedWs -- for tests

return m
