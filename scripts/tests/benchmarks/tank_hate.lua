-----------------------------------
-- Tank trust hate benchmark (not part of the modules suite; run on its own):
--   tools/custom/run_tests.sh --file benchmarks/tank_hate
-- A WAR (iLvl 117 stand-in totals) with one tank trust and Kupipi fights an arena boss. Reports, per tank, how much of
-- the fight the boss spent on the tank, how often the tank used Provoke / Flash / other hate tools, and the final
-- cumulative/volatile enmity of tank and player. Written to log/tank_hate.txt.
-- Environment: HATE_SECONDS (default 180), HATE_TIER (default 1), HATE_BOSS (index in the tier, default 1),
-- HATE_ONLY (trust spell id), HATE_RUNS (repeats per tank, default 1), HATE_ATT (player attack total, default 1300), HATE_PASSIVE=1 (player does not attack: checks the tank holds a boss with no competition).
-----------------------------------

local tanks =
{
    'TRION', 'VALAINERAL', 'CURILLA', 'EXCENMILLE', 'RAHAL', 'AMCHUCHU', 'AAEV', 'AUGUST', 'RUGHADJEEN', 'GESSHO',
    'HALVER', 'VOLKER', 'IRON_EATER', 'MNEJING', 'AAHM',
}

local out = io.open('log/tank_hate.txt', 'a')

local function log(line)
    out:write(line .. '\n')
    out:flush()
end

local function setTotal(player, read, mod, target)
    player:addMod(mod, target - read(player))
end

describe('Tank trust hate', function()
    local config  = require('modules/custom/htbf/htbf_config')
    local arena   = xi.custom.htbfArena
    local seconds = tonumber(os.getenv('HATE_SECONDS') or '180')
    local tier    = tonumber(os.getenv('HATE_TIER') or '1')
    local boss    = config.bosses[tier][tonumber(os.getenv('HATE_BOSS') or '1')]
    local passive = os.getenv('HATE_PASSIVE') == '1'
    local nuke    = tonumber(os.getenv('HATE_NUKE') or '0')

    if os.getenv('HATE_STEAL') and xi.custom.tankHate then
        xi.custom.tankHate.config.steal = tonumber(os.getenv('HATE_STEAL'))
    end

    it('measures how well each tank trust holds the boss', function()
        log(string.format('==== %s  T%d %s, %d s, player ATT %s, tank module %s%s', os.date('%Y-%m-%d %H:%M'), tier, boss.name, seconds, os.getenv('HATE_ATT') or '1300', xi.custom.tankHate and 'on' or 'off', (passive and ', player passive' or '') .. (nuke > 0 and (', nuke ' .. nuke .. ' every 8 s') or '') .. ', player enmity ' .. (os.getenv('HATE_PLAYER_ENMITY') or '0') .. ', tank WSD +' .. (os.getenv('HATE_TANKWSD') or '0') .. ', extra provoke every ' .. (os.getenv('HATE_PROVOKE_EVERY') or '-') .. ', steal ' .. (xi.custom.tankHate and xi.custom.tankHate.config.steal or '-')))

        local runs = tonumber(os.getenv('HATE_RUNS') or '1')
        local order = {}
        for _, name in ipairs(tanks) do
            for _ = 1, runs do
                table.insert(order, name)
            end
        end

        for _, name in ipairs(order) do
            local spellId = xi.magic.spell[name]
            if os.getenv('HATE_ONLY') and tonumber(os.getenv('HATE_ONLY')) ~= spellId then goto continue end

            local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
            player:setSkillLevel(xi.skill.AXE, 5000)
            player:setSkillLevel(xi.skill.EVASION, 5000)
            player:addLearnedWeaponskill(xi.wsUnlock.DECIMATION)
            player:addItem(20817) -- Eminent Axe (iLvl 117)
            player:equipItem(20817, nil, xi.slot.MAIN)
            setTotal(player, function(p) return p:getACC() end, xi.mod.ACC, 1150)
            setTotal(player, function(p) return p:getStat(xi.mod.ATT) end, xi.mod.ATT, tonumber(os.getenv('HATE_ATT') or '1300'))
            setTotal(player, function(p) return p:getStat(xi.mod.DEF) end, xi.mod.DEF, 1100)
            setTotal(player, function(p) return p:getEVA() end, xi.mod.EVA, 1100)
            player:addMod(xi.mod.HP, 6000) -- refilled below 30%: this measures hate, not survival
            player:addMod(xi.mod.DOUBLE_ATTACK, 10)
            player:updateHealth()
            player:setHP(player:getMaxHP())
            player:addMod(xi.mod.ENMITY, tonumber(os.getenv('HATE_PLAYER_ENMITY') or '0'))
            player:setCharVar('TrustEngageType', 1)

            xi.trust.spawn(player, GetSpell(spellId))
            xi.test.world:skipTime(1)
            xi.trust.spawn(player, GetSpell(xi.magic.spell.KUPIPI))
            xi.test.world:skipTime(1)

            local tank = nil
            for _, member in ipairs(player:getPartyWithTrusts()) do
                if member:isTrust() and member:getTrustID() == spellId then
                    tank = member
                end
            end

            if not tank then
                log(string.format('%-11s did not spawn', name))
                player:clearTrusts()
                goto continue
            end

            tank:addMod(xi.mod.ALL_WSDMG_ALL_HITS, tonumber(os.getenv('HATE_TANKWSD') or '0'))
            local provokeEvery = tonumber(os.getenv('HATE_PROVOKE_EVERY') or '0')

            local uses = {}
            if os.getenv('HATE_NOMODULE') == '1' and xi.custom.tankHate then
                -- Undo the module on this tank, to compare against stock behaviour
                tank:delMod(xi.mod.ENMITY_LOSS_REDUCTION, xi.custom.tankHate.config.lossReduction)
                tank:removeListener('TANK_HATE_JA')
                tank:removeListener('TANK_HATE_MA')
                tank:removeListener('TANK_HATE_MS')
            end

            tank:addListener('ABILITY_USE', 'HATE_JA', function(entity, target, ability)
                local key = 'JA ' .. ability:getID()
                uses[key] = (uses[key] or 0) + 1
            end)
            tank:addListener('MAGIC_USE', 'HATE_MA', function(entity, target, spell)
                local key = 'MA ' .. spell:getID()
                uses[key] = (uses[key] or 0) + 1
            end)
            tank:addListener('WEAPONSKILL_USE', 'HATE_WS', function(entity, target, skill)
                local key = 'WS ' .. (type(skill) == 'userdata' and skill:getID() or tostring(skill))
                uses[key] = (uses[key] or 0) + 1
            end)

            local s   = arena.bossScript(boss)
            local def =
            {
                objtype = xi.objType.MOB, name = 'HATE_' .. boss.key,
                x = player:getXPos() + 4, y = player:getYPos(), z = player:getZPos(), rotation = 0,
                groupId = boss.group[1], groupZoneId = boss.group[2],
                minLevel = config.tiers[tier].level, maxLevel = config.tiers[tier].level,
                releaseIdOnDisappear = true, mixins = s.mixins, skillList = boss.skillList,
            }

            for hook, fn in pairs(s.hooks) do
                def[hook] = fn
            end

            local mob = player:getZone():insertDynamicEntity(def)
            mob:setSpawn(player:getXPos() + 4, player:getYPos(), player:getZPos(), 0)
            mob:spawn()
            arena.scale(mob, tier, boss)
            mob:setUnkillable(true)

            -- The tank pulls, as a player would wait for it to; then the player joins in
            mob:updateEnmity(tank)
            xi.test.world:skipTime(3)
            if passive then
                player:addMod(xi.mod.ACC, -5000) -- engaged so the trusts fight, but its swings miss
            end

            player.actions:engage(mob)

            local onTank, onPlayer, other, tankDead = 0, 0, 0, 0
            local firstLost = nil
            local others = {}

            for t = 1, seconds do
                if player:getTP() >= 1000 then
                    player.actions:useWeaponskill(mob, xi.weaponskill.DECIMATION)
                end

                if provokeEvery > 0 and t % provokeEvery == 0 and tank:isAlive() and xi.custom.tankHate then
                    -- An extra Provoke's worth of hate: stock 1 CE / 1800 VE plus the module's, and its steal
                    local cfg    = xi.custom.tankHate.config
                    local victim = mob:getTarget()
                    mob:addEnmity(tank, 1 + cfg.provokeCE, 1800 + cfg.provokeVE)
                    if cfg.steal > 0 and victim and victim:getID() ~= tank:getID() then
                        mob:lowerEnmity(victim, cfg.steal)
                    end
                    uses.extraProvoke = (uses.extraProvoke or 0) + 1
                end

                if nuke > 0 and t % 8 == 0 then
                    mob:updateEnmityFromDamage(player, nuke) -- the damage enmity of one nuke of that size
                end

                if player:getHPP() < 30 then
                    player:setHP(player:getMaxHP()) -- keep the sample going; above 30% the healers' cures play out
                end
                xi.test.world:tickEntity(player)
                xi.test.world:skipTime(1)

                local target = mob:getTarget()
                if target and target:getID() == tank:getID() then
                    onTank = onTank + 1
                elseif target and target:getID() == player:getID() then
                    onPlayer = onPlayer + 1
                    firstLost = firstLost or t
                else
                    other = other + 1
                    local who = target and target:getName() or 'none'
                    others[who] = (others[who] or 0) + 1
                end

                if not tank:isAlive() then
                    tankDead = 1
                    break
                end

                if os.getenv('HATE_TRACE') and t <= 60 then
                    log(string.format('   t=%3d target %-10s tank CE %5d VE %5d | player CE %5d VE %5d | tank HP %d/%d',
                        t, target and target:getName() or '-', mob:getCE(tank), mob:getVE(tank), mob:getCE(player), mob:getVE(player), tank:getHP(), tank:getMaxHP()))
                end
            end

            local parts = {}
            for key, count in pairs(uses) do
                table.insert(parts, key .. 'x' .. count)
            end
            table.sort(parts)
            for who, count in pairs(others) do
                table.insert(parts, 'other:' .. who .. '=' .. count)
            end

            log(string.format('%-11s on tank %3d%%  player %3d%%  other %3d%%  first lost %4s  tank %s | tank CE %5d VE %5d, player CE %5d VE %5d | %s',
                name, math.floor(100 * onTank / seconds), math.floor(100 * onPlayer / seconds), math.floor(100 * other / seconds),
                firstLost and (firstLost .. 's') or '-', tankDead == 1 and 'DIED' or 'alive',
                tank:isAlive() and mob:getCE(tank) or 0, tank:isAlive() and mob:getVE(tank) or 0, mob:getCE(player), mob:getVE(player),
                table.concat(parts, ' ')))

            DespawnMob(mob:getID())
            player:clearTrusts()
            xi.test.world:skipTime(2)

            ::continue::
        end
    end)
end)
