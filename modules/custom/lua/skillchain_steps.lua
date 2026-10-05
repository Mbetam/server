-----------------------------------
-- Multi-step skillchains pay more (Eric, 2026-10-05; not retail): skillchain damage +20% for each step after the first
-- (step 2 x1.2, step 3 x1.4 ... step 6 x2.0), on top of retail's own per-step multipliers (scripts/combat/skillchain.lua
-- chainMultipliers). Light / Darkness: step 3 x1.75 -> x2.45, step 4 x2.00 -> x3.20.
-- The step count is the SKILLCHAIN effect's sub power (battleutils.cpp; the cap was raised from 5 to 6 the same day).
-- calculateSkillchainDamage applies the damage itself, so the bonus goes in through the actor's SKILLCHAINDMG mod
-- (1/100 %, one of its multipliers) while it runs, and is taken off again right after.
-----------------------------------
require('modules/module_utils')
require('scripts/combat/skillchain')
-----------------------------------

local m = Module:new('skillchain_steps')

local steps = {}

steps.perStep = 20 -- percent per step after the first

-- Extra SKILLCHAINDMG (1/100 %) for a chain at this step
steps.bonusFor = function(count)
    return math.max(0, (count or 1) - 1) * steps.perStep * 100
end

m:addOverride('xi.combat.skillchain.calculateSkillchainDamage', function(actor, target, baseDamage)
    local effect = target and target:getStatusEffect(xi.effect.SKILLCHAIN)
    local bonus  = (effect and actor) and steps.bonusFor(effect:getSubPower()) or 0

    if bonus == 0 then
        return super(actor, target, baseDamage)
    end

    actor:addMod(xi.mod.SKILLCHAINDMG, bonus)

    local results = { pcall(super, actor, target, baseDamage) }

    actor:delMod(xi.mod.SKILLCHAINDMG, bonus)

    if not results[1] then
        error(results[2], 0)
    end

    return unpack(results, 2, table.maxn(results))
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.skillchainSteps = steps -- for tests

return m
