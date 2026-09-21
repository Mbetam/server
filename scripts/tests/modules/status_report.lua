-----------------------------------
-- The !status report (modules/custom/lua/status_report.lua). Pure logic with a stand-in entity;
-- the real players and monsters are in status_engine.lua.
-----------------------------------
local report = require('modules/custom/lua/status_report')
-----------------------------------

describe('!status report', function()
    -- A stand-in entity. `mods` is by mod id, `skills` by skill id, `effects` is a list of { id, power, duration, remaining }.
    local function makeEntity(spec)
        spec = spec or {}

        local entity =
        {
            kind    = spec.kind or 'pc',
            name    = spec.name or 'Tester',
            mods    = spec.mods or {},
            skills  = spec.skills or {},
            effects = spec.effects or {},
            broken  = spec.broken,
        }

        entity.isPC       = function(self) return self.kind == 'pc' end
        entity.isMob      = function(self) return self.kind == 'mob' end
        entity.isPet      = function(self) return self.kind == 'pet' end
        entity.isTrust    = function(self) return self.kind == 'trust' end
        entity.isNPC      = function(self) return self.kind == 'npc' end
        entity.getName    = function(self) return self.name end
        entity.getMainLvl = function() return 99 end
        entity.getSubLvl  = function() return 49 end
        entity.getMainJob = function() return xi.job.WAR end
        entity.getSubJob  = function() return xi.job.NIN end
        entity.getHP      = function() return 1500 end
        entity.getMaxHP   = function() return 2000 end
        entity.getHPP     = function() return 75 end
        entity.getMP      = function() return 100 end
        entity.getMaxMP   = function() return 400 end
        entity.getTP      = function() return 1250.0 end
        entity.getStat    = function(self, id) return 100 + id end
        entity.getACC     = function() return 500 end
        entity.getRACC    = function() return 400 end
        entity.getRATT    = function() return 300 end
        entity.getEVA     = function() return 350 end
        entity.getWeaponDmg = function() return 42 end
        entity.getBaseDelay = function() return 480 end
        entity.getSpeed   = function() return 75 end
        entity.getAverageItemLevel = function() return 99 end
        entity.getMeritCount = function() return 10 end
        entity.getZoneName = function() return 'Lower_Jeuno' end
        entity.getMaxSkillLevel = function(self, level, job, skill) return skill == xi.skill.GREAT_AXE and 300 or 0 end

        entity.getMod = function(self, id)
            if self.broken then
                error('the game refused')
            end

            return self.mods[id] or 0
        end

        entity.getSkillLevel = function(self, id) return self.skills[id] or 0 end

        entity.getStatusEffects = function(self)
            local list = {}

            for _, spec in ipairs(self.effects) do
                table.insert(list,
                {
                    getEffectType    = function() return spec.id end,
                    getPower         = function() return spec.power end,
                    getDuration      = function() return spec.duration end,
                    getTimeRemaining = function() return spec.remaining or 0 end,
                })
            end

            return list
        end

        return entity
    end

    local function joined(lines)
        return table.concat(lines, '\n')
    end

    describe('layout', function()
        it('packs entries into lines that never exceed the limit and never split an entry', function()
            local entries = {}

            for index = 1, 40 do
                table.insert(entries, 'ENTRY_NUMBER_' .. index .. ' +' .. index)
            end

            local lines = report.pack(entries)

            for _, line in ipairs(lines) do
                assert(#line <= report.maxLineLength, 'a line is too long: ' .. #line)
            end

            local text = joined(lines)

            for _, entry in ipairs(entries) do
                assert(string.find(text, entry, 1, true), 'the entry "' .. entry .. '" was lost or split')
            end

            assert(#lines > 1, 'forty entries cannot fit on one line')
        end)

        it('keeps the order of the entries', function()
            local lines = report.pack({ 'a 1', 'b 2', 'c 3' })

            assert(lines[1] == '  a 1  b 2  c 3', 'unexpected packing: ' .. tostring(lines[1]))
        end)

        it('gives nothing back for nothing', function()
            assert(#report.pack({}) == 0)
        end)

        it('puts an entry that is too long on a line of its own instead of dropping it', function()
            local long  = string.rep('x', report.maxLineLength + 20)
            local lines = report.pack({ 'a 1', long, 'b 2' })

            assert(#lines == 3 and string.find(lines[2], long, 1, true), 'the long entry should have its own line')
        end)

        it('cuts pages, clamps the page number and counts pages', function()
            local lines = {}

            for index = 1, 30 do
                table.insert(lines, 'line ' .. index)
            end

            local slice, page, pages = report.page(lines, 1, 14)
            assert(#slice == 14 and page == 1 and pages == 3 and slice[1] == 'line 1')

            slice, page = report.page(lines, 3, 14)
            assert(#slice == 2 and page == 3 and slice[1] == 'line 29', 'the last page holds the remainder')

            slice, page = report.page(lines, 99, 14)
            assert(page == 3 and slice[1] == 'line 29', 'a page past the end should show the last page')

            slice, page = report.page(lines, 0, 14)
            assert(page == 1 and slice[1] == 'line 1', 'page 0 should show the first page')

            slice, page = report.page(lines, 'junk', 14)
            assert(page == 1, 'a page that is not a number should show the first page')

            slice, page, pages = report.page({}, 1, 14)
            assert(#slice == 0 and page == 1 and pages == 1, 'no lines is still one (empty) page')
        end)

        it('turns enum names into readable ones', function()
            assert(report.prettify('DUAL_WIELD') == 'Dual Wield')
            assert(report.prettify('GREAT_AXE') == 'Great Axe')
            assert(report.prettify('DEDICATION') == 'Dedication')
        end)
    end)

    describe('the summary', function()
        it('only reads mods that exist', function()
            for _, name in ipairs(report.summaryModNames()) do
                assert(xi.mod[name] ~= nil, 'the summary reads a mod that does not exist: ' .. name)
            end
        end)

        it('shows the name, kind, level, jobs, HP, MP and TP', function()
            local text = joined(report.summary(makeEntity({ name = 'Eric' })))

            assert(string.find(text, '== Eric (Player) ==', 1, true), 'the title is missing')
            assert(string.find(text, 'Lv 99 WAR / Lv 49 NIN', 1, true), 'levels and jobs are wrong')
            assert(string.find(text, 'HP 1500/2000 (75%)', 1, true), 'HP is wrong')
            assert(string.find(text, 'MP 100/400', 1, true) and string.find(text, 'TP 1250', 1, true), 'MP or TP is wrong')
        end)

        it('shows each attribute total, with the gear part only when there is one', function()
            local text = joined(report.summary(makeEntity({ mods = { [xi.mod.STR] = 12, [xi.mod.DEX] = -3 } })))

            assert(string.find(text, 'STR ' .. (100 + xi.mod.STR) .. ' (+12)', 1, true), 'a positive bonus should show as (+12)')
            assert(string.find(text, 'DEX ' .. (100 + xi.mod.DEX) .. ' (-3)', 1, true), 'a negative bonus should show as (-3)')
            assert(string.find(text, 'VIT ' .. (100 + xi.mod.VIT) .. '  ', 1, true) or string.find(text, 'VIT ' .. (100 + xi.mod.VIT) .. '\n', 1, true),
                'an attribute with no bonus should show no brackets')
        end)

        it('shows the combat numbers the game reports', function()
            local text = joined(report.summary(makeEntity()))

            for _, expected in ipairs({ 'Acc 500', 'Ranged Acc 400', 'Ranged Atk 300', 'Eva 350', 'Weapon Dmg 42', 'Delay 480', 'Speed 75' }) do
                assert(string.find(text, expected, 1, true), 'the summary should contain "' .. expected .. '"')
            end
        end)

        it('shows bonuses only when they are not zero, and gear Haste in whole percent', function()
            local text = joined(report.summary(makeEntity({ mods = { [xi.mod.DUAL_WIELD] = 8, [xi.mod.HASTE_GEAR] = 2500 } })))

            assert(string.find(text, 'Dual Wield +8', 1, true), 'Dual Wield should be listed')
            assert(string.find(text, 'Gear Haste % +25', 1, true) and not string.find(text, 'Gear Haste % +250', 1, true), 'gear Haste of 2500 is 25 percent: ' .. text)
            assert(not string.find(text, 'Triple Att', 1, true), 'a bonus of zero should not be listed')
            assert(string.find(text, 'Bonuses:', 1, true), 'the Bonuses heading should be there')
        end)

        it('leaves out the Bonuses heading when there are none', function()
            assert(not string.find(joined(report.summary(makeEntity())), 'Bonuses:', 1, true))
        end)

        it('shows all eight elements', function()
            local text = joined(report.summary(makeEntity({ mods = { [xi.mod.FIRE_MEVA] = 30 } })))

            for _, element in ipairs({ 'Fire 30', 'Ice 0', 'Wind 0', 'Earth 0', 'Thunder 0', 'Water 0', 'Light 0', 'Dark 0' }) do
                assert(string.find(text, element, 1, true), 'the elements should contain "' .. element .. '"')
            end
        end)

        it('shows player-only facts for a player and not for a monster', function()
            local player = joined(report.summary(makeEntity({ kind = 'pc' })))
            local mob    = joined(report.summary(makeEntity({ kind = 'mob' })))

            assert(string.find(player, 'Item Level 99', 1, true) and string.find(player, 'Merits 10', 1, true))
            assert(not string.find(mob, 'Item Level', 1, true) and not string.find(mob, 'Merits', 1, true), 'a monster has no item level or merits')
            assert(string.find(mob, '(Mob)', 1, true), 'a monster should be titled as a Mob')
        end)

        it('keeps every line short enough for one chat line', function()
            local mods = {}

            for _, name in ipairs(report.summaryModNames()) do
                mods[xi.mod[name]] = 123
            end

            for _, line in ipairs(report.summary(makeEntity({ mods = mods }))) do
                assert(#line <= report.maxLineLength, 'a summary line is ' .. #line .. ' characters: ' .. line)
            end
        end)
    end)

    describe('every mod', function()
        it('lists only the mods that are not zero, alphabetically, with raw values', function()
            local lines = report.mods(makeEntity({ mods = { [xi.mod.STR] = 5, [xi.mod.DUAL_WIELD] = 8, [xi.mod.HASTE_GEAR] = 2500, [xi.mod.DEX] = -2 } }))
            local text  = joined(lines)

            assert(string.find(text, 'DUAL_WIELD +8', 1, true) and string.find(text, 'HASTE_GEAR +2500', 1, true) and string.find(text, 'DEX -2', 1, true))
            assert(not string.find(text, 'VIT', 1, true), 'a mod of zero should not be listed')
            assert(string.find(lines[2], '(4)', 1, true), 'the header should count the mods: ' .. lines[2])

            local dex, dual, haste, str = string.find(text, 'DEX -2', 1, true), string.find(text, 'DUAL_WIELD', 1, true), string.find(text, 'HASTE_GEAR', 1, true), string.find(text, 'STR +5', 1, true)
            assert(dex < dual and dual < haste and haste < str, 'the mods should be in alphabetical order')
        end)

        it('never lists the placeholder mod NONE', function()
            assert(not string.find(joined(report.mods(makeEntity({ mods = { [xi.mod.NONE] = 9 } }))), 'NONE', 1, true))
        end)

        it('can list a great many mods on lines that stay short', function()
            local mods = {}

            for _, id in pairs(xi.mod) do
                mods[id] = 7
            end

            for _, line in ipairs(report.mods(makeEntity({ mods = mods }))) do
                assert(#line <= report.maxLineLength, 'a mod line is ' .. #line .. ' characters: ' .. line)
            end
        end)
    end)

    describe('skills and effects', function()
        it('lists only skills above zero, with the main job cap for a player', function()
            local text = joined(report.skills(makeEntity({ skills = { [xi.skill.GREAT_AXE] = 250, [xi.skill.SWORD] = 100 } })))

            assert(string.find(text, 'Great Axe 250/300', 1, true), 'a skill with a cap should show value/cap: ' .. text)
            assert(string.find(text, 'Sword 100', 1, true) and not string.find(text, 'Sword 100/', 1, true), 'a skill with no cap should show only its value')
            assert(not string.find(text, 'Dagger', 1, true), 'a skill of zero should not be listed')
        end)

        it('leaves out the 32767 flag the game stores for skills that are not levels', function()
            local text = joined(report.skills(makeEntity({ skills = { [xi.skill.RID] = 32767, [xi.skill.DIG] = 32767, [xi.skill.SWORD] = 10 } })))

            assert(not string.find(text, '32767', 1, true) and not string.find(text, 'Rid', 1, true) and not string.find(text, 'Dig', 1, true), 'the flag value must not be shown as a skill: ' .. text)
            assert(string.find(text, 'Sword 10', 1, true), 'real skills should still be listed')
        end)

        it('shows no caps for a monster', function()
            local text = joined(report.skills(makeEntity({ kind = 'mob', skills = { [xi.skill.GREAT_AXE] = 250 } })))

            assert(string.find(text, 'Great Axe 250', 1, true) and not string.find(text, '/300', 1, true))
        end)

        it('says so when there are no skills', function()
            assert(string.find(joined(report.skills(makeEntity())), 'No skills above zero.', 1, true))
        end)

        it('lists effects with power and time left, and says when there is no timer', function()
            local text = joined(report.effects(makeEntity({ effects =
            {
                { id = xi.effect.PROTECT, power = 20, duration = 300000, remaining = 125000 },
                { id = xi.effect.DEDICATION, power = 200, duration = 0 },
            } })))

            assert(string.find(text, 'Protect (power 20) 2:05', 1, true), 'a timed effect should show its time left: ' .. text)
            assert(string.find(text, 'Dedication (power 200)', 1, true) and not string.find(text, 'Dedication (power 200) ', 1, true), 'an effect with no timer should show none')
        end)

        it('shows long times in hours', function()
            local text = joined(report.effects(makeEntity({ effects = { { id = xi.effect.DEDICATION, power = 1, duration = 36000000, remaining = 35999000 } } })))

            assert(string.find(text, '9h59m', 1, true), 'ten hours minus a second should read 9h59m: ' .. text)
        end)

        it('says so when there are no effects', function()
            assert(string.find(joined(report.effects(makeEntity())), 'No status effects.', 1, true))
        end)
    end)

    describe('choosing what to show', function()
        it('shows the summary by default', function()
            local lines = report.run(makeEntity())

            assert(lines ~= nil and string.find(joined(lines), 'HP 1500/2000', 1, true))
        end)

        it('understands every section, in any letter case', function()
            for _, name in ipairs({ 'summary', 'MODS', 'Skills', 'effects', 'all' }) do
                local lines, message = report.run(makeEntity(), name)

                assert(lines ~= nil and #lines > 0, 'section ' .. name .. ' gave nothing: ' .. tostring(message))
            end
        end)

        it('shows everything for "all"', function()
            local text = joined(report.run(makeEntity({ mods = { [xi.mod.DUAL_WIELD] = 8 }, skills = { [xi.skill.SWORD] = 1 } }), 'all'))

            for _, expected in ipairs({ 'HP 1500/2000', 'Sword 1', 'No status effects.', 'DUAL_WIELD +8' }) do
                assert(string.find(text, expected, 1, true), '"all" should contain "' .. expected .. '"')
            end
        end)

        it('explains itself for a section it does not know', function()
            local lines, message = report.run(makeEntity(), 'banana')

            assert(lines == nil and message == report.usage, 'an unknown section should give the usage')
        end)

        it('refuses an NPC without touching its stats', function()
            local npc = makeEntity({ kind = 'npc', broken = true })
            local lines, message = report.run(npc, 'mods')

            assert(lines == nil and string.find(message, 'no stats', 1, true), 'an NPC should be refused: ' .. tostring(message))
        end)

        it('pages the mods and tells the player how to reach the next page', function()
            local mods = {}

            for _, id in pairs(xi.mod) do
                mods[id] = 7
            end

            local first, message = report.run(makeEntity({ mods = mods }), 'mods')
            assert(first ~= nil, tostring(message))
            assert(string.find(first[#first], 'Page 1 of', 1, true) and string.find(first[#first], '!status mods 2', 1, true), 'the last line should point to page 2: ' .. first[#first])

            local second = report.run(makeEntity({ mods = mods }), 'mods', 2)
            assert(string.find(second[#second], 'Page 2 of', 1, true))
            assert(first[3] ~= second[3], 'page 2 should show different mods than page 1')
        end)

        it('treats a bare number as a page of mods', function()
            local lines = report.run(makeEntity({ mods = { [xi.mod.STR] = 5 } }), '1')

            assert(lines ~= nil and string.find(joined(lines), 'STR +5', 1, true) and string.find(joined(lines), 'Page 1 of 1', 1, true))
        end)

        it('does not print a next-page hint on the last page', function()
            local lines = report.run(makeEntity({ mods = { [xi.mod.STR] = 5 } }), 'mods')

            assert(not string.find(lines[#lines], 'next', 1, true), 'the only page should not point to another: ' .. lines[#lines])
        end)

        it('turns a failure while reading into a message instead of an error', function()
            local lines, message = report.run(makeEntity({ broken = true }), 'summary')

            assert(lines == nil and string.find(message, 'Could not read', 1, true), 'a failed read should give a message: ' .. tostring(message))
        end)
    end)
end)
