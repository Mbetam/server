-----------------------------------
-- Skill-up rates: with this server's settings every eligible action raises the skill.
-- Each test pins the settings it depends on, then checks the same thing with the game's own defaults as a control, so a
-- passing test really shows the setting is what makes the difference (and that the default behaviour is unchanged).
--   combat, magic, automaton: SKILLUP_CHANCE_MULTIPLIER and SKILLUP_CHANCE_CAP (map)
--   crafting:                 CRAFT_CHANCE_MULTIPLIER (map)
--   digging:                  DIG_SKILLUP_CHANCE (main)
-- Fishing (FISHING_SKILL_MULTIPLIER) needs a whole fishing session and is not covered here.
-----------------------------------

describe('Skill-up rates', function()
    ---@type CClientEntityPair
    local player

    local function pinMaxRates()
        xi.test.world:setSetting('map.SKILLUP_CHANCE_MULTIPLIER', 100)
        xi.test.world:setSetting('map.SKILLUP_CHANCE_CAP', 1.0)
        xi.test.world:setSetting('map.CRAFT_CHANCE_MULTIPLIER', 1000)
        xi.test.world:setSetting('main.DIG_SKILLUP_CHANCE', 100)
    end

    local function pinGameDefaults()
        xi.test.world:setSetting('map.SKILLUP_CHANCE_MULTIPLIER', 1.0)
        xi.test.world:setSetting('map.SKILLUP_CHANCE_CAP', 0.5)
        xi.test.world:setSetting('map.CRAFT_CHANCE_MULTIPLIER', 1.0)
        xi.test.world:setSetting('main.DIG_SKILLUP_CHANCE', 15)
    end

    describe('combat and magic', function()
        local tries = 200

        -- Sets the skill (in tenths), tries a skill-up against a level 99 monster and says whether the skill went up
        local function attempt(skillId, tenths)
            player:setSkillLevel(skillId, tenths)
            player:trySkillUp(skillId, 99)

            return player:getCharSkillLevel(skillId) > tenths
        end

        local function countSkillUps(skillId, tenths)
            local ups = 0

            for _ = 1, tries do
                if attempt(skillId, tenths) then
                    ups = ups + 1
                end
            end

            return ups
        end

        describe('a melee skill', function()
            before_each(function()
                player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
            end)

            it('rises every time at the maximum rate', function()
                pinMaxRates()

                local ups = countSkillUps(xi.skill.GREAT_AXE, 1000)

                assert(ups == tries, string.format('great axe rose %d times in %d tries, it should be every time', ups, tries))
            end)

            it('rises every time even one point below the cap, where the base chance is lowest', function()
                pinMaxRates()

                local cap = player:getMaxSkillLevel(99, xi.job.WAR, xi.skill.GREAT_AXE)
                local ups = countSkillUps(xi.skill.GREAT_AXE, (cap - 1) * 10)

                assert(ups == tries, string.format('great axe one point under its cap (%d) rose %d times in %d tries', cap, ups, tries))
            end)

            it('rises about half the time with the game\'s own cap, so the cap setting is what matters', function()
                xi.test.world:setSetting('map.SKILLUP_CHANCE_MULTIPLIER', 100)
                xi.test.world:setSetting('map.SKILLUP_CHANCE_CAP', 0.5)

                local ups = countSkillUps(xi.skill.GREAT_AXE, 1000)

                -- 200 tries at 50%: mean 100, standard deviation 7. Anything from 60 to 140 is about right; 200 is not.
                assert(ups >= 60 and ups <= 140, string.format('with the 0.5 cap the skill should rise about half the time, it rose %d of %d', ups, tries))
            end)

            it('rises less than every time near the cap with the game\'s own settings', function()
                pinGameDefaults()

                local cap = player:getMaxSkillLevel(99, xi.job.WAR, xi.skill.GREAT_AXE)
                local ups = countSkillUps(xi.skill.GREAT_AXE, (cap - 1) * 10)

                assert(ups < tries, string.format('with the default settings a skill near its cap should not rise every time, but it did %d of %d', ups, tries))
            end)

            it('never rises past what the skill cap allows', function()
                pinMaxRates()

                local cap = player:getMaxSkillLevel(99, xi.job.WAR, xi.skill.GREAT_AXE)

                player:setSkillLevel(xi.skill.GREAT_AXE, cap * 10 - 5)

                for _ = 1, 20 do
                    player:trySkillUp(xi.skill.GREAT_AXE, 99)
                end

                assert(player:getCharSkillLevel(xi.skill.GREAT_AXE) <= cap * 10, 'the skill went past its cap: ' .. player:getCharSkillLevel(xi.skill.GREAT_AXE))
            end)
        end)

        describe('a magic skill', function()
            before_each(function()
                player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 99 })
            end)

            it('rises every time at the maximum rate', function()
                pinMaxRates()

                local ups = countSkillUps(xi.skill.HEALING_MAGIC, 1000)

                assert(ups == tries, string.format('healing magic rose %d times in %d tries, it should be every time', ups, tries))
            end)

            it('rises about half the time with the game\'s own cap', function()
                xi.test.world:setSetting('map.SKILLUP_CHANCE_MULTIPLIER', 100)
                xi.test.world:setSetting('map.SKILLUP_CHANCE_CAP', 0.5)

                local ups = countSkillUps(xi.skill.HEALING_MAGIC, 1000)

                assert(ups >= 60 and ups <= 140, string.format('with the 0.5 cap healing magic should rise about half the time, it rose %d of %d', ups, tries))
            end)
        end)
    end)

    describe('crafting', function()
        local crafts = 30

        -- Woodworking at 12.0 against a recipe of level 13 (Willow Lumber): one level of difference, where the game's own
        -- skill-up chance is only about 42%. (Further below the recipe the game's chance is already over 100%.)
        local skillTenths = 120

        local function countCraftSkillUps()
            player:setSkillRank(xi.skill.WOODWORKING, 9)
            player:setMod(xi.mod.SYNTH_SUCCESS_RATE, 300) -- never breaks, so every synth is eligible
            player:setMod(xi.mod.SYNTH_SPEED_WOODWORKING, 17000)

            local ups = 0

            for _ = 1, crafts do
                player:setSkillLevel(xi.skill.WOODWORKING, skillTenths)
                player:addItem(xi.item.WIND_CRYSTAL)
                player:addItem(xi.item.WILLOW_LOG)

                player.actions:craft(xi.item.WIND_CRYSTAL, { xi.item.WILLOW_LOG })
                xi.test.world:skipTime(15)

                if player:getCharSkillLevel(xi.skill.WOODWORKING) > skillTenths then
                    ups = ups + 1
                end

                player:delContainerItems(xi.inv.INVENTORY)
            end

            return ups
        end

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })
        end)

        it('raises the skill on every eligible synthesis at the maximum rate', function()
            pinMaxRates()

            local ups = countCraftSkillUps()

            assert(ups == crafts, string.format('woodworking rose on %d of %d syntheses, it should be all of them', ups, crafts))
        end)

        it('does not raise it every time with the game\'s own rate', function()
            pinGameDefaults()

            local ups = countCraftSkillUps()

            assert(ups < crafts, string.format('with the default rate woodworking should not rise on every synthesis, but it did %d of %d', ups, crafts))
        end)
    end)

    describe('digging', function()
        local digs = 150

        -- Digs in Bibiki Bay, moving between two spots so the game never calls it a dig in the same place.
        -- Returns how many digs found an item and the Digging skill (in tenths) at the end.
        local function dig()
            player:setSkillRank(xi.skill.DIG, 0)
            player:setSkillLevel(xi.skill.DIG, 0)

            local x, y, z = player:getXPos(), player:getYPos(), player:getZPos()
            local found   = 0
            local free    = player:getFreeSlotsCount(xi.inv.INVENTORY)

            for index = 1, digs do
                player:setLocalVar('ZoneInTime', 0)
                player:setLocalVar('[DIG]LastDigTime', 0)
                player:setPos(x + (index % 2) * 30, y, z, 0)

                xi.chocoboDig.start(player)

                if player:getFreeSlotsCount(xi.inv.INVENTORY) < free then
                    found = found + 1
                    player:delContainerItems(xi.inv.INVENTORY)
                end

                if found >= 12 then
                    break
                end
            end

            return found, player:getCharSkillLevel(xi.skill.DIG)
        end

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.BIBIKI_BAY })
            player:release()
        end)

        it('raises the skill on every dig that finds something at the maximum rate', function()
            pinMaxRates()

            local found, skill = dig()

            assert(found >= 5, 'precondition: not enough digs found anything to judge (' .. found .. ')')
            assert(skill == found, string.format('%d digs found an item, so the skill should be %d tenths, but it is %d', found, found, skill))
        end)

        it('raises the skill on none of them when the chance is set to zero', function()
            xi.test.world:setSetting('main.DIG_SKILLUP_CHANCE', 0)

            local found, skill = dig()

            assert(found >= 5, 'precondition: not enough digs found anything to judge (' .. found .. ')')
            assert(skill == 0, string.format('with a chance of 0 the skill should stay at 0, but it is %d after %d finds', skill, found))
        end)
    end)
end)
