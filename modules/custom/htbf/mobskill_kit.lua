-----------------------------------
-- Mob skill kit (custom): builds a mob skill script from a short description, for the TP moves LSB has rows and
-- animations for (sql/mob_skills.sql) but no scripts: the Caturae (Omen, Provenance), and the Adoulin Delve / Unity
-- families (Gabbrath, Yggdreant, Bztavian, Waktza, Rockfin, Cehuetzi). Effects follow BG Wiki's family pages
-- (2026-09-30); damage is tuned for the boss arenas (modules/custom/htbf/). Target shape (single / AoE / conal) and
-- range come from each skill's mob_skills row, not from here.
--
-- A script in scripts/actions/mobskills/<name>.lua is then one call:
--     return require('modules/custom/htbf/mobskill_kit').move({ ... })
--
-- Description fields:
--   kind       'physical' | 'magical' | 'breath' | 'none' (effects only) | 'self' (buffs / heal on the user)
--   element    xi.element.X (magical / breath)
--   hits, ftp  physical: number of hits, fTP at 1000 / 2000 / 3000 TP
--   power      magical / breath: multiplier on the user's level (default 4)
--   damageType xi.damageType.X (physical; default SLASHING)
--   effects    { { effect, power, tick, duration }, ... } on the target, if the move landed (or always for 'none')
--   dispel     number of buffs dispelled from the target
--   resetHate  true: the user's enmity on the target is reset
--   gaze       true: effects only land if the target faces the user
--   buffs      { { effect, power, tick, duration }, ... } on the user
--   heal       HP the user recovers ('self'); erase = true also removes its enfeebles
--   hpBelow    only usable at or below this HP% (e.g. Incinerating Lahar: 50)
-----------------------------------
local kit = {}

local function applyEffects(mob, target, def)
    local landed = nil

    for _, e in ipairs(def.effects or {}) do
        local result

        if def.gaze then
            result = xi.mobskills.mobGazeMove(mob, target, e[1], e[2], e[3] or 0, e[4] or 60)
        else
            result = xi.mobskills.mobStatusEffectMove(mob, target, e[1], e[2], e[3] or 0, e[4] or 60)
        end

        landed = landed or result
    end

    for _ = 1, def.dispel or 0 do
        target:dispelStatusEffect()
    end

    if def.resetHate then
        mob:resetEnmity(target)
    end

    return landed
end

local function applyBuffs(mob, def)
    for _, b in ipairs(def.buffs or {}) do
        xi.mobskills.mobBuffMove(mob, b[1], b[2], b[3] or 0, b[4] or 60)
    end
end

kit.move = function(def)
    local object = {}

    object.onMobSkillCheck = function(target, mob, skill)
        if def.hpBelow and mob:getHPP() > def.hpBelow then
            return 1
        end

        return 0
    end

    object.onMobWeaponSkill = function(mob, target, skill, action)
        -- Buffs on the user happen once per use, not once per target hit by an area move
        local firstTarget = skill:getPrimaryTargetID() == target:getID()

        if def.kind == 'self' then
            applyBuffs(mob, def)

            if def.erase then
                for _ = 1, 10 do
                    mob:eraseStatusEffect()
                end
            end

            if def.heal then
                local healed = math.min(def.heal, mob:getMaxHP() - mob:getHP())
                mob:addHP(healed)
                skill:setMsg(xi.msg.basic.SELF_HEAL)

                return healed
            end

            skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)

            return def.buffs and def.buffs[1] and def.buffs[1][1] or 0
        end

        if firstTarget then
            applyBuffs(mob, def)
        end

        if def.kind == 'none' then
            local landed = applyEffects(mob, target, def)
            skill:setMsg(landed or xi.msg.basic.SKILL_NO_EFFECT)

            return def.effects and def.effects[1] and def.effects[1][1] or 0
        end

        local info

        if def.kind == 'physical' then
            info = xi.mobskills.mobPhysicalMove(mob, target, skill, action,
            {
                baseDamage     = mob:getWeaponDmg(),
                numHits        = def.hits or 1,
                fTP            = def.ftp or { 2, 2.5, 3 },
                attackType     = xi.attackType.PHYSICAL,
                damageType     = def.damageType or xi.damageType.SLASHING,
                shadowBehavior = def.hits or 1,
            })
        else
            local power = def.power or 4

            info = xi.mobskills.mobMagicalMove(mob, target, skill, action,
            {
                baseDamage     = mob:getMainLvl(),
                fTP            = { power, power, power },
                element        = def.element or xi.element.DARK,
                attackType     = def.kind == 'breath' and xi.attackType.BREATH or xi.attackType.MAGICAL,
                damageType     = xi.damageType.ELEMENTAL + (def.element or xi.element.DARK),
                shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
            })
        end

        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
            applyEffects(mob, target, def)
        end

        return info.damage
    end

    return object
end

return kit
