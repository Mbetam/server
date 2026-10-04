-----------------------------------
-- Boss arenas for Rem's Tales (modules/custom/htbf/): the Battle Archivist in Western Adoulin sends a party straight
-- into a private arena (Maquette Abdhaljs-Legion A) for the tier picked; the Arena Moogle spawns the tier's bosses one
-- at a time, scaled; each player gets their own personal drops and the loot goes to the treasure pool.
-----------------------------------

describe('Boss arenas (Rem\'s Tales)', function()
    ---@type CClientEntityPair
    local player
    local config = require('modules/custom/htbf/htbf_config')
    local arena  = xi.custom.htbfArena
    local menu   = nil
    local menus  = {}
    local queued = {}
    local schedule

    local function pick(label)
        assert(menu ~= nil, 'no menu is open (wanted "' .. label .. '")')

        for _, option in ipairs(menu.options) do
            if option[1] == label then
                local who = menu.player
                menu = nil
                option[2](who)

                return
            end
        end

        local labels = {}
        for _, option in ipairs(menu.options) do
            table.insert(labels, option[1])
        end

        error('no option "' .. label .. '" in the menu "' .. tostring(menu.title) .. '": ' .. table.concat(labels, ' | '))
    end

    local function runQueued()
        local due = queued
        queued    = {}

        for _, job in ipairs(due) do
            job.fn(job.who)
        end
    end

    local function tierLabel(tier)
        return string.format('%s (Lv%d)', config.tiers[tier].name, config.tiers[tier].level)
    end

    -- The test harness only ticks zones whose own player list is not empty, and players in an instance are not on it:
    -- nothing inside an arena gets an AI tick in tests (no death processing, no zoning out). So a kill here is the
    -- damage plus the death hook the server would call next.
    local function kill(mob, killer)
        mob:takeDamage(mob:getHP() + 1, killer, xi.attackType.PHYSICAL, xi.damageType.BLUNT)
        assert(not mob:isAlive(), mob:getName() .. ' survived')
        xi.zones['Maquette_Abdhaljs-Legion_A'].mobs[mob:getName()].onMobDeath(mob, killer, { isKiller = true })
    end

    -- Opens an arena of `tier` at the Archivist for `who`, and `members` (their party) standing next to them
    local function enterArena(who, tier, members)
        if who:getZoneID() ~= xi.zone.WESTERN_ADOULIN then
            who:gotoZone(xi.zone.WESTERN_ADOULIN)
        end

        who.entities:gotoAndTrigger('DE_Battle_Archivist')

        for _, member in ipairs(members or {}) do
            member:setPos(who:getXPos() + 2, who:getYPos(), who:getZPos())
        end

        pick(tierLabel(tier))
        xi.test.world:tick(xi.tick.TIME)
        xi.test.world:skipTime(2)

        assert(who:getZoneID() == config.arena.zoneId, string.format('not in the arena zone (zone %d)', who:getZoneID()))
        local instance = who:getInstance()
        assert(instance and instance:getID() == config.arena.instanceId, 'not in the arena instance')
        assert(instance:getLocalVar('tier') == tier, 'the arena has the wrong tier')

        return instance
    end

    before_each(function()
        menu   = nil
        menus  = {}
        queued = {}
        arena.setMenuSender(function(who, sent)
            sent.player = who
            menu        = sent
            table.insert(menus, sent)
        end)
        schedule       = arena.schedule
        arena.schedule = function(who, ms, fn)
            table.insert(queued, { who = who, fn = fn })
        end
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WESTERN_ADOULIN, job = xi.job.WAR, level = 99 })
    end)

    after_each(function()
        arena.setMenuSender(nil)
        arena.schedule = schedule
    end)

    it('has Eric\'s roster: 6 / 6 / 3 / 5 / 1 bosses, with his personal drops', function()
        local counts = { 6, 6, 3, 5, 1 }

        for tier, count in ipairs(counts) do
            assert(#config.bosses[tier] == count, string.format('tier %d has %d bosses', tier, #config.bosses[tier]))
        end

        -- Chapters: Tier 1 bosses 1-5 give chapters 1-5, Tier 2 bosses 1-5 give 6-10
        for tier = 1, 2 do
            for index = 1, 5 do
                local p = config.bosses[tier][index].personal[1]
                assert(p.chapter == (tier - 1) * 5 + index, string.format('%s gives chapter %s', config.bosses[tier][index].name, tostring(p.chapter)))
            end
        end

        assert(config.bosses[1][6].personal[1].item == 6183, 'Khimaira should give a Pluton Box')
        assert(config.bosses[2][6].personal[1].item == 6184, 'Utkux should give a Beitetsu Box')
        assert(config.bosses[3][3].personal[1].item == 6185, 'Glassy Thinker should give a Boulder Box')
    end)

    it('every menu and reward line fits the 150-byte chat packet', function()
        player.entities:gotoAndTrigger('DE_Battle_Archivist')

        for _, sent in ipairs(menus) do
            assert(arena.menuLength(sent) <= arena.menuLimit, string.format('menu "%s" is %d bytes', sent.title, arena.menuLength(sent)))
        end

        for tier = 1, #config.tiers do
            local options = { { 'Leave' } }
            for _, boss in ipairs(config.bosses[tier]) do
                table.insert(options, { boss.name })
            end

            local moogleMenu = { title = string.format('%s: which boss?', config.tiers[tier].name), options = options }
            assert(arena.menuLength(moogleMenu) <= arena.menuLimit, string.format('tier %d boss menu is %d bytes', tier, arena.menuLength(moogleMenu)))
            assert(#arena.rewardLine(tier) <= arena.menuLimit, string.format('tier %d reward line is %d bytes', tier, #arena.rewardLine(tier)))
        end
    end)

    it('the Archivist stands at Eric\'s spot and takes the party near him straight into their own arena', function()
        local archivist = player.entities:get('DE_Battle_Archivist')
        assert(math.abs(archivist:getXPos() - 12.0314) < 0.01 and math.abs(archivist:getZPos() - 20.3859) < 0.01, 'not at X 12.0314 Z 20.3859')

        local member = xi.test.world:spawnPlayer({ zone = xi.zone.WESTERN_ADOULIN, job = xi.job.WHM, level = 99 })
        player.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        local instance = enterArena(player, 1, { member })
        assert(member:getZoneID() == config.arena.zoneId, 'the party member was not moved in')
        assert(member:getInstance() and member:getInstance():getLocalVar('token') == instance:getLocalVar('token'), 'the party member is not in the same arena')

        local names = {}
        for _, npc in pairs(instance:getNpcs()) do
            names[npc:getName()] = true
        end

        assert(names['DE_' .. config.arena.moogle.name] and names['DE_' .. config.arena.exit.name], 'the arena has no Moogle or no exit')
    end)

    it('the Moogle spawns a scaled boss; one at a time; each player gets their own drops on the kill', function()
        local member = xi.test.world:spawnPlayer({ zone = xi.zone.WESTERN_ADOULIN, job = xi.job.WHM, level = 99 })
        player.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        local instance = enterArena(player, 1, { member })
        assert(member:getInstance() ~= nil, 'the party member is not in the arena')

        arena.onMoogleTrigger(player, nil)
        pick('Behemoth')
        assert(arena.currentBoss(instance) == nil, 'the boss came before the delay')
        runQueued()

        local boss = arena.currentBoss(instance)
        assert(boss ~= nil, 'no boss spawned')
        assert(boss:getMainLvl() == 125, 'the boss is level ' .. boss:getMainLvl())
        assert(boss:getStat(xi.mod.ATT) >= config.floors[1].att, 'the boss is below the Tier 1 attack floor')
        assert(instance:getLocalVar('fightEnd') > 0, 'no fight timer')

        arena.onMoogleTrigger(player, nil)
        pick('Adamantoise')
        assert(#queued == 0, 'a second boss was queued while one is alive')

        kill(boss, player)
        assert(arena.currentBoss(instance) == nil, 'the boss is still alive')

        for _, who in ipairs({ player, member }) do
            local n = who:getItemCount(config.chapter(1))
            assert(n >= 2 and n <= 3, string.format('%s got %d chapter 1', who:getName(), n))
        end

        assert(instance:getLocalVar('fightEnd') == 0, 'the fight timer was not cleared')
    end)

    -- Every boss: its group and script load, it spawns at its tier's level, runs its hooks, stays put, gives each
    -- player their personal drops, and its loot is real items
    for tier = 1, #config.tiers do
        for index, boss in ipairs(config.bosses[tier]) do
            it(string.format('Tier %d %s: level %d, personal %s, loot to roll', tier, boss.name, config.tiers[tier].level, arena.rewardText(boss)), function()
                local instance = enterArena(player, tier)
                local mob      = arena.spawnBoss(instance, index, player)
                assert(mob ~= nil, 'the boss did not spawn')
                assert(mob:getMainLvl() == config.tiers[tier].level, string.format('level %d', mob:getMainLvl()))
                assert(mob:getMaxHP() > 1000, string.format('only %d HP', mob:getMaxHP()))

                if boss.hp then
                    local want = boss.hp * (config.hpScale or 1)
                    assert(math.abs(mob:getMaxHP() - want) <= want / 100, string.format('%s has %d HP, configured %d', boss.name, mob:getMaxHP(), want))
                end
                -- Every combat stat at least its tier's floor (Eric: real defensive stats, iLvl 117 should struggle)
                local floors = config.floors[tier]
                local now    =
                {
                    acc  = mob:getACC(),
                    att  = mob:getStat(xi.mod.ATT),
                    def  = mob:getStat(xi.mod.DEF),
                    eva  = mob:getEVA(),
                    meva = mob:getMod(xi.mod.MEVA),
                    mdb  = mob:getMod(xi.mod.MDEF),
                }

                for key, target in pairs(floors) do
                    assert(now[key] >= target, string.format('%s %s is %d, below the tier %d floor %d', boss.name, key, now[key], tier, target))
                end

                -- The Omen bosses are casters (BG Wiki's spell lists): they need MP
                local casters = { Kin = true, Gin = true, Kei = true, Kyou = true, Fu = true, Ou = true }
                if casters[boss.key] then
                    assert(mob:getMaxMP() > 0, boss.name .. ' has no MP to cast with')
                end

                if config.tiers[tier].regen then
                    assert(mob:getMod(xi.mod.REGEN) >= config.tiers[tier].regen, 'no tier regen')
                end

                -- No AI tick in an arena in tests: run the fight hooks once by hand, so a script that only works in
                -- its own zone fails here rather than on the live server
                local cached = xi.zones['Maquette_Abdhaljs-Legion_A'].mobs[mob:getName()]
                local calls  =
                {
                    onMobRoam           = { mob },
                    onMobEngage         = { mob, player },
                    onMobFight          = { mob, player },
                    onMobMobskillChoose = { mob, player, 0 },
                    onMobSpellChoose    = { mob, player, 0 },
                    onMobDisengage      = { mob },
                }

                for hook, args in pairs(calls) do
                    if cached[hook] then
                        cached[hook](unpack(args))
                    end
                end

                -- Lair guards: the boss must not pull a player standing in the arena (Cerberus sent Eric into the
                -- void) nor root itself. Run onMobFight twice, the second time past any draw-in wait.
                if cached.onMobFight then
                    local x, z = player:getXPos(), player:getZPos()
                    cached.onMobFight(mob, player)
                    player:setLocalVar('[Draw-In]WaitTime', 1)
                    cached.onMobFight(mob, player)
                    assert(math.abs(player:getXPos() - x) < 0.1 and math.abs(player:getZPos() - z) < 0.1, string.format('%s pulled the player from (%.1f, %.1f) to (%.1f, %.1f)', boss.name, x, z, player:getXPos(), player:getZPos()))
                    assert(mob:getMobMod(xi.mobMod.NO_MOVE) == 0, boss.name .. ' rooted itself')
                end

                -- The treasure pool entries: real items, as handed to the drop code
                local added = {}
                local fakeLoot =
                {
                    addItemFixed  = function(self, id, rate)
                        table.insert(added, id)
                    end,
                    addGroupFixed = function(self, rate, items)
                        for _, entry in ipairs(items) do
                            table.insert(added, entry.item)
                        end
                    end,
                }
                arena.addLoot(fakeLoot, boss)

                for _, id in ipairs(added) do
                    assert(GetReadOnlyItem(id) ~= nil, boss.name .. ': loot item ' .. id .. ' does not exist')
                end

                -- Personal drops for everyone inside
                kill(mob, player)

                for _, p in ipairs(boss.personal) do
                    local ids

                    if p.chapter then
                        ids = { config.chapter(p.chapter) }
                    elseif p.jobCard then
                        ids = { config.paragonCard(player:getMainJob()) }
                    elseif p.oneOf then
                        ids = p.oneOf
                    else
                        ids = { p.item }
                    end

                    local got = 0
                    for _, id in ipairs(ids) do
                        got = got + player:getItemCount(id)
                    end

                    local min = p.min or config.dropMin
                    local max = p.max or config.dropMax
                    assert(got >= min and got <= max, string.format('%s: got %d, expected %d-%d', boss.name, got, min, max))
                end
            end)
        end
    end

    it('the 48 custom TP-move scripts (mobskill_kit) all load and describe a move', function()
        local names = {}
        local list  = io.popen('grep -l "mobskill_kit" scripts/actions/mobskills/*.lua')

        for path in list:lines() do
            table.insert(names, path)
        end

        list:close()
        assert(#names == 48, 'expected 48 kit scripts, found ' .. #names)

        for _, path in ipairs(names) do
            local ok, object = pcall(dofile, path)
            assert(ok and type(object) == 'table' and object.onMobWeaponSkill and object.onMobSkillCheck, path .. ' does not load: ' .. tostring(object))
        end
    end)

    it('every boss gets its configured final HP (Ou 2.1M), plus the tier stat floors', function()
        local instance = enterArena(player, 5)
        local ou       = arena.spawnBoss(instance, 1, player)
        -- setMaxHP sets the base; the mob's own HP bonuses add a little (Ou: +180)
        local expected = config.bosses[5][1].hp * (config.hpScale or 1)
        assert(math.abs(ou:getMaxHP() - expected) <= expected / 100, 'Ou has ' .. ou:getMaxHP() .. ' HP, expected ' .. expected)
        assert(ou:getACC() >= config.floors[5].acc and ou:getEVA() >= config.floors[5].eva, 'Ou is below his accuracy / evasion floors')
        assert(ou:getMod(xi.mod.MACC) >= config.tiers[5].macc, 'Ou has no magic accuracy bonus')
    end)

    it('Kin and Kyou get a Holy-only damage bonus (Eric: Holy hit only ~270)', function()
        local instance = enterArena(player, 4)
        local kin      = arena.spawnBoss(instance, 4, player)
        local precast  = xi.zones['Maquette_Abdhaljs-Legion_A'].mobs[kin:getName()].onSpellPrecast

        precast(kin, { getID = function() return xi.magic.spell.HOLY end })
        assert(kin:getMod(xi.mod.MAGIC_DAMAGE) == 600, 'no Holy bonus: ' .. kin:getMod(xi.mod.MAGIC_DAMAGE))

        precast(kin, { getID = function() return xi.magic.spell.COMET end })
        assert(kin:getMod(xi.mod.MAGIC_DAMAGE) == 0, 'the Holy bonus stayed on for Comet')
    end)

    it('Tier 3 job cards are the Paragon card of the job', function()
        assert(config.paragonCard(xi.job.WAR) == 9281, 'the Warrior card is 9281')
        assert(config.paragonCard(xi.job.RUN) == 9302, 'the Rune Fencer card is 9302')
    end)

    it('Ou recovers once, at 10% HP to 25%', function()
        local instance = enterArena(player, 5)
        local mob      = arena.spawnBoss(instance, 1, player)
        local fight    = xi.zones['Maquette_Abdhaljs-Legion_A'].mobs[mob:getName()].onMobFight

        mob:setHP(math.floor(mob:getMaxHP() * 0.09))
        fight(mob, player)
        assert(mob:getHPP() >= 24, 'Ou did not recover (HP ' .. mob:getHPP() .. '%)')

        mob:setHP(math.floor(mob:getMaxHP() * 0.09))
        fight(mob, player)
        assert(mob:getHPP() < 10, 'Ou recovered twice')
    end)

    it('a boss leaves when the 30 minutes are up', function()
        local instance = enterArena(player, 2)
        arena.spawnBoss(instance, 1, player)
        assert(arena.currentBoss(instance) ~= nil, 'no boss')

        -- DespawnMob only asks the AI to despawn (no AI tick in an arena in tests): check that it was asked
        local boss      = arena.currentBoss(instance)
        local despawned = nil
        local despawn   = arena.despawn
        arena.despawn   = function(mob)
            despawned = mob:getID()
        end

        arena.instanceObject.onInstanceTimeUpdate(instance, 0)
        assert(despawned == nil, 'the boss was sent away early')

        instance:setLocalVar('fightEnd', GetSystemTime() - 1) -- the 30 minutes are over (wall clock: skipTime does not move it)
        arena.instanceObject.onInstanceTimeUpdate(instance, 0)
        arena.despawn = despawn

        assert(despawned == boss:getID(), 'the boss was not sent away after the time limit')
        assert(instance:getLocalVar('fightEnd') == 0, 'the fight timer was not cleared')
        assert(player:getItemCount(config.chapter(6)) == 0, 'chapters for a fight that timed out')
    end)

    it('the exit sends you back to the Archivist, and the empty arena closes', function()
        local instance = enterArena(player, 1)

        -- Zoning out of an arena does not happen in tests (no AI tick there): check where the exit sends you
        local sent        = false
        local toArchivist = arena.toArchivist
        arena.toArchivist = function(who)
            sent = true
        end

        arena.onExitTrigger(player, nil)
        pick('Yes')
        arena.toArchivist = toArchivist
        assert(sent, 'the exit does not send you back to the Archivist')

        -- Nobody inside, as the instance's own player list reads once they have left
        local chars = arena.chars
        arena.chars = function() return {} end
        arena.instanceObject.onInstanceTimeUpdate(instance, 0)
        assert(not instance:failed(), 'closed without waiting')
        instance:setLocalVar('emptySince', GetSystemTime() - config.arena.emptySeconds) -- wall clock, as above
        arena.instanceObject.onInstanceTimeUpdate(instance, 0)
        arena.chars = chars
        assert(instance:failed(), 'the empty arena did not close')
    end)

    it('logging back in to an arena that has closed lands you at the Archivist', function()
        player:gotoZone(xi.zone.WEST_RONFAURE)
        xi.zones['Maquette_Abdhaljs-Legion_A'].Zone.onInstanceZoneIn(player, nil)
        xi.test.world:skipTime(2)
        assert(player:getZoneID() == xi.zone.WESTERN_ADOULIN, 'not sent to the Archivist')
    end)
end)
