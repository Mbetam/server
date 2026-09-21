-----------------------------------
-- !status in the real engine: real players, a real monster and a real NPC, and the lines really reach the client as chat.
-----------------------------------
local core   = require('modules/custom/lua/augment_core')
local report = require('modules/custom/lua/status_report')
-----------------------------------

describe('!status in the engine', function()
    ---@type CClientEntityPair
    local player

    -- Ascetic's Ring: see augment_engine.lua for why not the Copper Ring
    local ring = 13440

    -- Every chat line the server sent to the player since the packets were last cleared, one entry per message
    local function said()
        local lines = {}

        for _, pkt in pairs(player.packets:getIncoming()) do
            if pkt.type == 0x017 then
                local text = ''

                for i = 0, pkt.size - 23 - 1 do
                    local byte = pkt.data[23 + i]
                    if byte == nil or byte == 0 then
                        break
                    end

                    text = text .. string.char(byte)
                end

                table.insert(lines, text)
            end
        end

        return lines
    end

    -- Runs !status as the player and returns what came back as one text
    local function run(section, page)
        player.packets:clear()
        xi.commands.status.onTrigger(player, section, page)

        return table.concat(said(), '\n')
    end

    local function joined(lines)
        return table.concat(lines, '\n')
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.GM_HOME, job = xi.job.WAR, level = 99 })
    end)

    describe('on the player themself', function()
        it('shows name, level, job, HP, MP and TP that match the game', function()
            -- Hurt, so that current and maximum HP differ and mixing them up would show
            player:setHP(math.floor(player:getMaxHP() / 2))

            local text = run()

            assert(player:getHP() < player:getMaxHP(), 'precondition: the player should be hurt')

            assert(string.find(text, '== ' .. player:getName() .. ' (Player) ==', 1, true), 'the title is missing:\n' .. text)
            assert(string.find(text, 'Lv 99 WAR', 1, true), 'level and job are missing:\n' .. text)
            assert(string.find(text, string.format('HP %d/%d', player:getHP(), player:getMaxHP()), 1, true), 'HP is wrong:\n' .. text)
            assert(string.find(text, string.format('MP %d/%d', player:getMP(), player:getMaxMP()), 1, true), 'MP is wrong:\n' .. text)
            assert(string.find(text, string.format('(%d%%)', player:getHPP()), 1, true), 'the HP percentage is wrong:\n' .. text)
        end)

        it('shows every attribute exactly as the game reports it', function()
            local text = run()

            for _, name in ipairs({ 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }) do
                local expected = string.format('%s %d', name, player:getStat(xi.mod[name]))

                assert(string.find(text, expected, 1, true), 'expected "' .. expected .. '" in:\n' .. text)
            end
        end)

        it('shows the combat numbers the game reports', function()
            local text = run()

            for _, expected in ipairs({ 'Acc ' .. player:getACC(0), 'Eva ' .. player:getEVA(), 'Ranged Acc ' .. player:getRACC(), 'Ranged Atk ' .. player:getRATT() }) do
                assert(string.find(text, expected, 1, true), 'expected "' .. expected .. '" in:\n' .. text)
            end
        end)

        it('shows a bonus from gear, and it is the bonus that was really given', function()
            assert(not string.find(run(), 'Dual Wield', 1, true), 'precondition: no Dual Wield before the ring')

            local id, value, amount = core.encode('dual_wield', 2)

            player:addItem({ id = ring, exdata = core.buildExdata({ { id = id, value = value }, { id = id, value = value } }) })
            player:equipItem(ring, nil, xi.slot.RING1)

            local text = run()

            assert(string.find(text, 'Dual Wield +' .. amount * 2, 1, true), 'the ring gives Dual Wield +' .. amount * 2 .. ' and the summary should say so:\n' .. text)
        end)

        it('lists a gear bonus among the mods, in raw values', function()
            local id, value, amount = core.encode('dual_wield', 2)

            player:addItem({ id = ring, exdata = core.buildExdata({ { id = id, value = value } }) })
            player:equipItem(ring, nil, xi.slot.RING1)

            local text = run('mods')

            assert(string.find(text, 'DUAL_WIELD +' .. amount, 1, true), '"!status mods" should list DUAL_WIELD +' .. amount .. ':\n' .. text)
            assert(string.find(text, 'Page 1 of', 1, true), 'the page line is missing:\n' .. text)
        end)

        it('lists a skill the player has', function()
            -- setSkillLevel takes tenths of a skill point, so 2000 is skill 200
            player:setSkillLevel(xi.skill.GREAT_AXE, 2000)

            local text     = run('skills')
            local expected = string.format('Great Axe 200/%d', player:getMaxSkillLevel(99, xi.job.WAR, xi.skill.GREAT_AXE))

            assert(string.find(text, expected, 1, true), 'expected "' .. expected .. '" in:\n' .. text)
            assert(not string.find(text, '32767', 1, true), 'the 32767 flag skills (Riding, Digging) must not be listed:\n' .. text)
        end)

        it('lists a status effect with its power', function()
            -- The engine needs an origin for an effect (without one the test process crashes)
            player:addStatusEffect(xi.effect.PROTECT, { power = 20, duration = 300, origin = player })

            local text = run('effects')

            assert(string.find(text, 'Protect (power 20)', 1, true), 'expected the Protect effect in:\n' .. text)
        end)

        it('reads the second page of mods', function()
            local second = run('mods', 2)

            assert(string.find(second, 'Page 2 of', 1, true) or string.find(second, 'Page 1 of 1', 1, true), 'page 2 should be a page (or clamp to the only one):\n' .. second)
        end)

        it('tells the player what is possible when the section is not known', function()
            local text = run('banana')

            assert(string.find(text, '!status mods', 1, true), 'the usage should mention the sections:\n' .. text)
        end)

        it('changes nothing about the player', function()
            local before = { hp = player:getHP(), maxHp = player:getMaxHP(), str = player:getMod(xi.mod.STR), gil = player:getGil() }

            for _, section in ipairs({ 'summary', 'mods', 'skills', 'effects', 'all' }) do
                run(section)
            end

            assert(player:getHP() == before.hp and player:getMaxHP() == before.maxHp and player:getMod(xi.mod.STR) == before.str and player:getGil() == before.gil,
                'reading stats must not change them')
        end)
    end)

    describe('what reaches the client', function()
        it('sends every line as its own chat message, whole', function()
            for _, section in ipairs({ 'summary', 'skills', 'effects', 'all' }) do
                player.packets:clear()

                local lines = report.run(player, section)
                xi.commands.status.onTrigger(player, section)

                local received = said()

                assert(#received == #lines, string.format('section %s: %d lines were made but %d arrived', section, #lines, #received))

                for index, line in ipairs(lines) do
                    assert(received[index] == line, string.format('section %s line %d was changed on the way:\n  sent     "%s"\n  received "%s"', section, index, line, received[index]))
                end
            end
        end)

        it('keeps every mods page whole even with a lot of mods', function()
            -- Give the player a large number of non-zero mods so the pages are full
            local count = 0

            for name, id in pairs(xi.mod) do
                if id > 0 and count < 300 and name ~= 'HP' and name ~= 'MP' then
                    player:setMod(id, 3)
                    count = count + 1
                end
            end

            local lines, _, pages

            player.packets:clear()
            lines = report.run(player, 'mods')
            xi.commands.status.onTrigger(player, 'mods')

            local received = said()

            assert(#received == #lines, string.format('%d lines were made but %d arrived', #lines, #received))

            for index, line in ipairs(lines) do
                assert(received[index] == line, 'a mods line was changed on the way: ' .. line)
            end

            _, _, pages = report.page(report.mods(player), 1)
            assert(pages > 1, 'with 300 mods there should be several pages, got ' .. pages)
        end)
    end)

    describe('on a monster', function()
        local mob

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.IFRITS_CAULDRON, job = xi.job.WAR, level = 99 })
            mob    = player.entities:get('Volcanic_Bomb')

            assert(mob ~= nil, 'precondition: the test monster should exist')
        end)

        it('shows the monster\'s own numbers', function()
            local lines = report.run(mob)
            local text  = joined(lines)

            assert(string.find(text, '(Mob)', 1, true), 'the title should say Mob:\n' .. text)
            assert(string.find(text, string.format('HP %d/%d', mob:getHP(), mob:getMaxHP()), 1, true), 'HP is wrong:\n' .. text)
            assert(string.find(text, string.format('Lv %d', mob:getMainLvl()), 1, true), 'level is wrong:\n' .. text)
            assert(string.find(text, string.format('STR %d', mob:getStat(xi.mod.STR)), 1, true), 'STR is wrong:\n' .. text)
            assert(string.find(text, 'Eva ' .. mob:getEVA(), 1, true), 'Eva is wrong:\n' .. text)
        end)

        it('reads every section without an error', function()
            for _, section in ipairs({ 'summary', 'mods', 'skills', 'effects', 'all' }) do
                local lines, message = report.run(mob, section)

                assert(lines ~= nil and #lines > 0, 'section ' .. section .. ' failed for a monster: ' .. tostring(message))
            end
        end)

        it('does not show player-only facts', function()
            local text = joined(report.run(mob))

            assert(not string.find(text, 'Item Level', 1, true) and not string.find(text, 'Merits', 1, true), 'a monster has neither:\n' .. text)
        end)

        it('shows a monster that has just died', function()
            mob:respawn()
            player.entities:moveTo(mob)
            player:claimAndKillMob(mob)

            local lines, message = report.run(mob)

            assert(lines ~= nil and string.find(joined(lines), 'HP 0/', 1, true), 'a dead monster should show HP 0: ' .. tostring(message))
        end)

        it('shows another player\'s stats too', function()
            local other = xi.test.world:spawnPlayer({ zone = xi.zone.IFRITS_CAULDRON, job = xi.job.WHM, level = 50 })
            local lines = report.run(other)

            assert(lines ~= nil and string.find(joined(lines), 'Lv 50 WHM', 1, true), 'another player should be readable:\n' .. joined(lines or {}))
        end)
    end)

    describe('on an NPC', function()
        it('is refused without touching the NPC\'s stats', function()
            local npc = player.entities:get('DE_Augmenter')

            assert(npc ~= nil, 'precondition: the Augmenter should be in GM Home')

            local lines, message = report.run(npc, 'mods')

            assert(lines == nil and string.find(message, 'no stats', 1, true), 'an NPC should be refused, got: ' .. tostring(message))
        end)
    end)
end)
