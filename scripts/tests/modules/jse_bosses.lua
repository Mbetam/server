-----------------------------------
-- The 27 Abyssea NMs of the JSE weapon progression (modules/custom/jse_progression/jse_config.lua drops), end to end:
-- each one pops the way a player would pop it (its ??? with the key items / trade, its timed spawn, or Lachrymater for
-- Myrmecoleon; every ??? of it), has a real level and HP, comes down to fight (Ovni), and drops its JSE material on the
-- kill. (Melee damage is not checked: players' auto-attacks barely land in the test harness.)
-- Every ???'s requirements are written to JSE_BOSSES_REPORT (if set) for checking where they drop.
-----------------------------------

describe('JSE bosses', function()
    local config = require('modules/custom/jse_progression/jse_config')

    local zoneDirs =
    {
        [xi.zone.ABYSSEA_LA_THEINE]  = 'Abyssea-La_Theine',
        [xi.zone.ABYSSEA_TAHRONGI]   = 'Abyssea-Tahrongi',
        [xi.zone.ABYSSEA_KONSCHTAT]  = 'Abyssea-Konschtat',
        [xi.zone.ABYSSEA_VUNKERL]    = 'Abyssea-Vunkerl',
        [xi.zone.ABYSSEA_MISAREAUX]  = 'Abyssea-Misareaux',
        [xi.zone.ABYSSEA_ATTOHWA]    = 'Abyssea-Attohwa',
        [xi.zone.ABYSSEA_ALTEPA]     = 'Abyssea-Altepa',
        [xi.zone.ABYSSEA_ULEGUERAND] = 'Abyssea-Uleguerand',
        [xi.zone.ABYSSEA_GRAUBERG]   = 'Abyssea-Grauberg',
    }

    -- Retail pops that are not a ???: timed spawns, and Myrmecoleon (out of the sand when Lachrymater dies)
    local special = { Ovni = 'timed', Chukwa = 'timed', Turul = 'timed', Fistule = 'timed', Hedjedjet = 'timed', Fuath = 'timed', Empousa = 'timed', Myrmecoleon = 'Lachrymater' }

    local report = {}

    local function note(line)
        table.insert(report, line)

        local path = os.getenv('JSE_BOSSES_REPORT')
        if path then
            local file = io.open(path, 'w')
            file:write(table.concat(report, '\n') .. '\n')
            file:close()
        end
    end

    local function spawn(zoneId)
        local player = xi.test.world:spawnPlayer({ zone = zoneId, job = xi.job.WAR, level = 99 })
        xi.abyssea.afterZoneIn(player)

        return player
    end

    -- Every ??? of the zone: what it pops and what it needs, read by calling its own script with the pop functions
    -- swapped for recorders. { [mob id] = { qm = name, kis = {}, items = {} } ... }
    local function readQms(zoneId)
        local dir   = zoneDirs[zoneId]
        local found = {}
        local list  = io.popen(string.format('ls scripts/zones/%s/npcs/ | grep "^qm"', dir))
        local names = {}

        for file in list:lines() do
            table.insert(names, (file:gsub('%.lua$', '')))
        end

        list:close()

        local onTrigger, onTrade = xi.abyssea.qmOnTrigger, xi.abyssea.qmOnTrade

        for _, name in ipairs(names) do
            local script = xi.zones[dir] and xi.zones[dir].npcs[name]

            if script == nil then
                local ok, loaded = pcall(dofile, string.format('scripts/zones/%s/npcs/%s.lua', dir, name))
                script = ok and loaded or nil
            end

            local npc = GetZone(zoneId):queryEntitiesByName(name)
            npc = npc and npc[1]

            if script and npc then
                local seen = nil

                xi.abyssea.qmOnTrigger = function(player, npcArg, mobId, kis, items)
                    seen = seen or {}
                    if mobId and mobId ~= 0 then
                        seen.mob = mobId
                    end

                    seen.kis   = kis or seen.kis
                    seen.items = items or seen.items
                end

                xi.abyssea.qmOnTrade = function(player, npcArg, trade, mobId, items)
                    seen = seen or {}
                    seen.mob   = mobId
                    seen.items = items

                    return false
                end

                local fake = { getItemCount = function() return 0 end, hasItemQty = function() return false end, getItem = function() return nil end }

                if script.onTrigger then
                    pcall(script.onTrigger, nil, npc)
                end

                if script.onTrade then
                    pcall(script.onTrade, nil, npc, fake)
                end

                if seen and seen.mob then
                    found[seen.mob] = { qm = name, kis = seen.kis or {}, items = seen.items or {} }
                end
            end
        end

        xi.abyssea.qmOnTrigger, xi.abyssea.qmOnTrade = onTrigger, onTrade

        return found
    end

    -- The NM's mob ids in this zone (some have several spawn points)
    local function idsOf(zoneId, name)
        local ids = {}

        for _, mob in ipairs(GetZone(zoneId):queryEntitiesByName(name) or {}) do
            table.insert(ids, mob:getID())
        end

        return ids
    end

    local function popByQm(player, zoneId, name)
        local qms = readQms(zoneId)
        local nm  = {}

        for _, id in ipairs(idsOf(zoneId, name)) do
            nm[id] = true
        end

        local pops = {}

        for mobId, entry in pairs(qms) do
            if nm[mobId] then
                note(string.format('%s %s (%d) <- %s kis=%s items=%s', zoneDirs[zoneId], name, mobId, entry.qm, table.concat(entry.kis, ','), table.concat(entry.items, ',')))
                table.insert(pops, { id = mobId, qm = entry.qm, kis = entry.kis, items = entry.items })
            end
        end

        assert(#pops > 0, name .. ': no ??? pops it')
        table.sort(pops, function(x, y) return x.qm < y.qm end)

        -- Every ??? of the NM must work (LSB's second and third ??? did nothing): pop at each, put it away again,
        -- and keep the last one up for the fight
        local mob = nil

        for index, chosen in ipairs(pops) do
            -- Up already (another test popped it): put it away first, the ??? refuses while it is up
            if GetMobByID(chosen.id):isSpawned() then
                DespawnMob(chosen.id)

                for _ = 1, 3 do
                    xi.test.world:skipTime(1)
                end
            end

            if #chosen.kis > 0 then
                for _, ki in ipairs(chosen.kis) do
                    player:addKeyItem(ki)
                end

                player.entities:gotoAndTrigger(chosen.qm)
                player.events:finish(nil, 1)
            else
                assert(#chosen.items > 0, name .. ': its ??? needs nothing')

                for _, item in ipairs(chosen.items) do
                    player:addItem(item)
                end

                player.entities:moveTo(chosen.qm)
                player.actions:tradeNpc(chosen.qm, chosen.items)
            end

            xi.test.world:skipTime(2)

            mob = GetMobByID(chosen.id)
            assert(mob:isSpawned(), string.format('%s did not pop at %s', name, chosen.qm))

            if index < #pops then
                DespawnMob(chosen.id)
                xi.test.world:skipTime(1)
            end
        end

        return mob
    end

    local function pop(player, zoneId, name)
        local how = special[name]

        if how == 'timed' then
            local ids = idsOf(zoneId, name)
            assert(#ids > 0, name .. ' does not exist')
            note(string.format('%s %s: timed spawn, %d spawn point(s)', zoneDirs[zoneId], name, #ids))

            local mob = GetMobByID(ids[1])
            if not mob:isSpawned() then
                mob:respawn()
            end

            xi.test.world:skipTime(1)
            assert(mob:isSpawned(), name .. ' did not spawn')

            return mob
        elseif how == 'Lachrymater' then
            local lachry = player.entities:moveTo('Lachrymater')
            lachry:respawn()
            lachry:updateClaim(player)
            lachry:takeDamage(lachry:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

            for _ = 1, 3 do
                xi.test.world:skipTime(1)
            end

            local mob = GetMobByID(idsOf(zoneId, name)[1])
            assert(mob and mob:isSpawned(), 'Myrmecoleon did not come out')

            return mob
        end

        -- A ??? NM may already be up from an earlier test: put it away first
        for _, id in ipairs(idsOf(zoneId, name)) do
            if GetMobByID(id):isSpawned() then
                DespawnMob(id)
            end
        end

        xi.test.world:skipTime(1)

        return popByQm(player, zoneId, name)
    end

    for _, zoneId in ipairs({ xi.zone.ABYSSEA_LA_THEINE, xi.zone.ABYSSEA_TAHRONGI, xi.zone.ABYSSEA_KONSCHTAT, xi.zone.ABYSSEA_VUNKERL,
        xi.zone.ABYSSEA_MISAREAUX, xi.zone.ABYSSEA_ATTOHWA, xi.zone.ABYSSEA_ALTEPA, xi.zone.ABYSSEA_ULEGUERAND, xi.zone.ABYSSEA_GRAUBERG }) do
        local names = {}
        for name in pairs(config.drops[zoneId]) do
            table.insert(names, name)
        end

        table.sort(names)

        for _, name in ipairs(names) do
            local material = config.drops[zoneId][name][1]

            it(string.format('%s (%s): pops, comes down, fights, drops its material', name, zoneDirs[zoneId]), function()
                local player = spawn(zoneId)
                local mob    = pop(player, zoneId, name)
                local before = mob:getAnimationSub()

                -- Fight: the NM engages, comes into reach, and the player's swings land
                player:setPos(mob:getXPos(), mob:getYPos(), mob:getZPos())
                mob:updateClaim(player)
                mob:updateEnmity(player)
                player.actions:engage(mob)

                local hp = mob:getHP()
                for _ = 1, 12 do
                    xi.test.world:skipTime(1)
                    player:setHP(player:getMaxHP())
                end

                note(string.format('%s %s: pose %d -> %d in combat, HP %d -> %d, level %d', zoneDirs[zoneId], name, before, mob:getAnimationSub(), hp, mob:getHP(), mob:getMainLvl()))
                assert(mob:isEngaged(), name .. ' did not engage')
                assert(mob:getMainLvl() >= 80, string.format('%s is level %d', name, mob:getMainLvl()))
                assert(mob:getMaxHP() >= 25000, string.format('%s has only %d HP', name, mob:getMaxHP()))

                if name == 'Ovni' then -- yovra: animation 5 = floating high, out of reach
                    assert(mob:getAnimationSub() ~= 5, name .. ' stays up in the air in combat')
                end

                -- Kill: the material drops
                local had = player:getItemCount(material)
                mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

                for _ = 1, 3 do
                    xi.test.world:skipTime(1)
                end

                assert(mob:isDead(), name .. ' did not die')
                assert(player:getItemCount(material) > had, string.format('%s dropped no material %d', name, material))

                -- Timed NMs come back after a minute (Eric), not the data's 15
                if config.timed[name] then
                    for _ = 1, 15 do
                        xi.test.world:skipTime(1)
                    end

                    local left = mob:getRespawnTime()
                    note(string.format('%s %s: respawns in %d s', zoneDirs[zoneId], name, left))
                    assert(left > 0 and left <= config.respawn, string.format('%s respawns in %d s', name, left))
                end
            end)
        end
    end
end)
