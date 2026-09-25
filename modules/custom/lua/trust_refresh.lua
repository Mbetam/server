-----------------------------------
-- Every trust gets Refresh +50 (MP per tick) so casters never run dry (Eric's choice, 2026-09-25; not retail).
-- All trust spells call xi.trust.spawn; after it, each of the caster's trusts that has not had the bonus yet gets it.
-- Trust scripts set their own mods in onMobSpawn, which runs inside spawnTrust, so this is added on top of those.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
-----------------------------------

local refresh = 50

local m = Module:new('trust_refresh')

m:addOverride('xi.trust.spawn', function(caster, spell)
    local result = super(caster, spell)

    for _, member in ipairs(caster:getPartyWithTrusts()) do
        if
            member:isTrust() and
            member:getMaster() and
            member:getMaster():getID() == caster:getID() and
            member:getLocalVar('[custom]TrustRefresh') == 0
        then
            member:addMod(xi.mod.REFRESH, refresh)
            member:setLocalVar('[custom]TrustRefresh', 1)
        end
    end

    return result
end)

return m
