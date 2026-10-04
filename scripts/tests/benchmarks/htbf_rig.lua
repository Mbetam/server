-----------------------------------
-- Boss arena benchmark rig (not part of the modules suite; run on its own, it takes a while):
--   tools/custom/run_tests.sh --file benchmarks/htbf_rig
-- A duo (a melee and a nuker, at a gear level) with four trusts fights each boss of a tier in the open (arena
-- instances get no AI tick in tests), with the boss's full AI: TP moves, spells, the arena scaling. Reports time to
-- kill, deaths and the boss's HP left, written to log/htbf_rig.txt. Used to tune modules/custom/htbf/htbf_config.lua
-- to Eric's targets (2026-10-05): Tier 1 doable by a duo or solo + trusts in iLvl 117 but difficult, Tier 2 the same
-- in iLvl 119 with a finished relic / REMA; about 6-10 minutes a fight.
--
-- Gear levels are stand-ins: the players' totals are set with mods, since the test characters own no gear.
-- Environment: RIG_TIERS (e.g. "1,2"), RIG_MINUTES (default 15).
-----------------------------------

local profiles =
{
    -- iLvl 117: Eminent weapon, 117-ish armor
    [117] =
    {
        melee = { acc = 1150, att = 1300, def = 1100, eva = 1100, hp = 2400, doubleAttack = 10, wsd = 0 },
        mage  = { macc = 400, matt = 200, int = 100, hp = 1800 },
    },
    -- iLvl 119 + a finished relic / REMA (stronger WS, aftermath-like double attack)
    [119] =
    {
        melee = { acc = 1300, att = 1600, def = 1250, eva = 1200, hp = 2800, doubleAttack = 25, wsd = 30 },
        mage  = { macc = 550, matt = 280, int = 130, hp = 2100 },
    },
}

local tierGear = { [1] = 117, [2] = 119, [3] = 119, [4] = 119, [5] = 119 }

local nukes =
{
    xi.magic.spell.FIRE_V, xi.magic.spell.BLIZZARD_V, xi.magic.spell.AERO_V,
    xi.magic.spell.STONE_V, xi.magic.spell.THUNDER_V, xi.magic.spell.WATER_V,
}

local trusts = { xi.magic.spell.TRION, xi.magic.spell.KUPIPI, xi.magic.spell.ULMIA, xi.magic.spell.JOACHIM }

local out = io.open('log/htbf_rig.txt', 'a')
local rigDealt = nil

local function log(line)
    out:write(line .. '\n')
    out:flush()
end

-- Raises a player's stat to a total with a mod
local function setTotal(player, read, mod, target)
    player:addMod(mod, target - read(player))
end

describe('Boss arena rig', function()
    local config = require('modules/custom/htbf/htbf_config')
    local arena  = xi.custom.htbfArena
    local minutes = tonumber(os.getenv('RIG_MINUTES') or '15')
    local tiers   = {}

    for t in string.gmatch(os.getenv('RIG_TIERS') or '1,2', '%d+') do
        table.insert(tiers, tonumber(t))
    end

    it('runs the duo + trusts against every boss of the chosen tiers', function()
        log(string.format('==== %s  tiers %s, cap %d min', os.date('%Y-%m-%d %H:%M'), table.concat(tiers, ','), minutes))

        for _, tier in ipairs(tiers) do
            local gear = profiles[tierGear[tier]]

            for bossIndex, boss in ipairs(config.bosses[tier]) do
                if os.getenv('RIG_ONLY') and tonumber(os.getenv('RIG_ONLY')) ~= bossIndex then goto continue end
                -- The duo
                local melee = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
                local mage  = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLM, level = 99 })

                melee:setSkillLevel(xi.skill.AXE, 5000)
                melee:setSkillLevel(xi.skill.EVASION, 5000)
                melee:addLearnedWeaponskill(xi.wsUnlock.DECIMATION)
                melee:addItem(20817) -- Eminent Axe (iLvl 117)
                melee:equipItem(20817, nil, xi.slot.MAIN)

                local m = gear.melee
                setTotal(melee, function(p) return p:getACC() end, xi.mod.ACC, m.acc)
                setTotal(melee, function(p) return p:getStat(xi.mod.ATT) end, xi.mod.ATT, m.att)
                setTotal(melee, function(p) return p:getStat(xi.mod.DEF) end, xi.mod.DEF, m.def)
                setTotal(melee, function(p) return p:getEVA() end, xi.mod.EVA, m.eva)
                melee:addMod(xi.mod.HP, m.hp - melee:getMaxHP())
                melee:addMod(xi.mod.DOUBLE_ATTACK, m.doubleAttack)
                melee:addMod(xi.mod.ALL_WSDMG_ALL_HITS, m.wsd)
                melee:updateHealth()
                melee:setHP(melee:getMaxHP())

                local g = gear.mage
                mage:setSkillLevel(xi.skill.ELEMENTAL_MAGIC, 5000)
                mage:addMod(xi.mod.MACC, g.macc)
                mage:addMod(xi.mod.MATT, g.matt)
                mage:addMod(xi.mod.INT, g.int)
                mage:addMod(xi.mod.MP, 20000)
                mage:addMod(xi.mod.HP, g.hp - mage:getMaxHP())
                mage:updateHealth()
                mage:setHP(mage:getMaxHP())
                mage:setMP(mage:getMaxMP())

                for _, spell in ipairs(nukes) do
                    mage:addSpell(spell)
                end

                -- Trusts join once their master engages (the !trustengage option), as in the trust tests
                melee:setCharVar('TrustEngageType', 1)

                melee.actions:inviteToParty(mage)
                mage.actions:acceptPartyInvite()
                xi.test.world:skipTime(1)

                for _, spell in ipairs(trusts) do
                    xi.trust.spawn(melee, GetSpell(spell))
                    xi.test.world:skipTime(1)
                end

                -- The boss, a few yalms off, with its arena hooks and scaling
                local s   = arena.bossScript(boss)
                local def =
                {
                    objtype = xi.objType.MOB, name = 'RIG_' .. boss.key,
                    x = melee:getXPos() + 4, y = melee:getYPos(), z = melee:getZPos(), rotation = 0,
                    groupId = boss.group[1], groupZoneId = boss.group[2],
                    minLevel = config.tiers[tier].level, maxLevel = config.tiers[tier].level,
                    releaseIdOnDisappear = true, mixins = s.mixins, skillList = boss.skillList,
                }

                for name, fn in pairs(s.hooks) do
                    def[name] = fn
                end

                local mob = melee:getZone():insertDynamicEntity(def)
                mob:setSpawn(melee:getXPos() + 4, melee:getYPos(), melee:getZPos(), 0)
                mob:spawn()
                arena.scale(mob, tier, boss)

                local maxHP = mob:getMaxHP()

                if os.getenv('RIG_DEBUG') then
                    local names = {}
                    for _, member in ipairs(melee:getPartyWithTrusts()) do
                        table.insert(names, member:getName())
                    end
                    log('  party: ' .. table.concat(names, ', ') .. string.format('  | melee HP %d ACC %d ATT %d | mage HP %d MP %d', melee:getMaxHP(), melee:getACC(), melee:getStat(xi.mod.ATT), mage:getMaxHP(), mage:getMaxMP()))
                    local dealt = { melee = 0, mage = 0 }
                    mob:addListener('TAKE_DAMAGE', 'RIG_DMG', function(mobArg, amount, attacker)
                        if attacker and attacker:getID() == melee:getID() then dealt.melee = dealt.melee + amount
                        elseif attacker and attacker:getID() == mage:getID() then dealt.mage = dealt.mage + amount end
                    end)
                    rigDealt = dealt
                    for _, who in ipairs({ melee, mage }) do
                        who:addListener('TAKE_DAMAGE', 'RIG_TAKEN', function(target, amount, attacker, attackType)
                            if os.getenv('RIG_TRACE') then
                                log(string.format('    %s took %d (attackType %s) from %s', target:getName(), amount, tostring(attackType), attacker and attacker:getName() or '?'))
                            end
                        end)
                    end
                end

                -- As in a real duo: the tank trust takes the boss first, then enmity plays out on its own
                local tank = nil
                for _, member in ipairs(melee:getPartyWithTrusts()) do
                    if member:isTrust() and member:getTrustID() == xi.magic.spell.TRION then
                        tank = member
                    end
                end

                mob:updateEnmity(tank or melee)
                xi.test.world:skipTime(3)
                melee.actions:engage(mob)

                local deaths   = { melee = 0, mage = 0, trusts = 0 }
                local wasAlive = { melee = true, mage = true }
                local seconds  = 0
                local nuke     = 0

                while mob:isAlive() and seconds < minutes * 60 do
                    -- Weapon skill at 1000 TP; a nuke every 7 s through the six elements
                    if melee:isAlive() and melee:getTP() >= 1000 then
                        melee.actions:useWeaponskill(mob, xi.weaponskill.DECIMATION)
                    end

                    if mage:isAlive() and seconds % 7 == 0 then
                        nuke = nuke % #nukes + 1
                        mage:setMP(mage:getMaxMP())
                        mage.actions:useSpell(mob, nukes[nuke])
                    end

                    xi.test.world:tickEntity(melee)
                    xi.test.world:tickEntity(mage)
                    xi.test.world:skipTime(1)
                    seconds = seconds + 1

                    if os.getenv('RIG_TRACE') and seconds <= 40 then
                        local target = mob:getTarget()
                        local hps = {}
                        for _, member in ipairs(melee:getPartyWithTrusts()) do
                            table.insert(hps, string.format('%s %d/%d%s', member:getName(), member:getHP(), member:getMaxHP(), member:isEngaged() and '*' or ''))
                        end
                        log(string.format('  t=%2d boss HP %d%% target %s dist %.1f | %s', seconds, mob:getHPP(), target and target:getName() or '-', target and mob:checkDistance(target) or -1, table.concat(hps, ', ')))
                    end

                    for name, who in pairs({ melee = melee, mage = mage }) do
                        if wasAlive[name] and not who:isAlive() then
                            deaths[name] = deaths[name] + 1
                        end

                        wasAlive[name] = who:isAlive()
                    end

                    if not melee:isAlive() and not mage:isAlive() then
                        break -- wipe
                    end
                end

                for _, member in ipairs(melee:getPartyWithTrusts()) do
                    if member:isTrust() and not member:isAlive() then
                        deaths.trusts = deaths.trusts + 1
                    end
                end

                local result = mob:isAlive() and string.format('NOT killed, %d%% HP left', mob:getHPP()) or 'killed'
                if not melee:isAlive() and not mage:isAlive() then
                    result = result .. ' (WIPE)'
                end

                if rigDealt then
                    log(string.format('  dealt: melee %d, mage %d; melee TP now %d; mage MP %d', rigDealt.melee, rigDealt.mage, melee:getTP(), mage:getMP()))
                    rigDealt = nil
                end

                log(string.format('T%d %-15s HP %8d  %-26s in %2d:%02d   deaths: melee %d, mage %d, trusts %d',
                    tier, boss.name, maxHP, result, math.floor(seconds / 60), seconds % 60, deaths.melee, deaths.mage, deaths.trusts))

                if mob:isAlive() then
                    DespawnMob(mob:getID())
                end

                melee:clearTrusts()
                xi.test.world:skipTime(2)

                ::continue::
            end
        end
    end)
end)
