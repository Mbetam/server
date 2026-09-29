-----------------------------------
-- JSE weapon progression: the Splintery Chest in Ru'Lude Gardens sells the base Relic / Mythic / Empyrean weapons for
-- 500,000 gil (jse_config.lua). Family menu, then a paged weapon menu (5 per page), then a confirmation. Its retail job
-- (the free Magian trial starter weapons) stays as the last option of the family menu.
-- Checks: main job 99, no weapon in progress (a lost one can be bought again: the new one replaces it), the family is
-- unlocked (Mythic after a finished Relic, Empyrean after a finished Mythic), enough gil. Every failed check is named.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/npcs/Splintery_Chest')
local config   = require('modules/custom/jse_progression/jse_config')
local progress = require('modules/custom/jse_progression/jse_progress')
-----------------------------------

local m = Module:new('jse_chest')

-- Ru'Lude's DefaultActions gives the chest a flavour line ("significantly shopworn"). With that and a script, the
-- interaction framework alternates between them on every other click, so the menu would only open half the time.
-- DefaultActions is loaded through require (cached), so the entry is removed from the cached table before the
-- framework reads it: no core file edited.
local defaultActions = require('scripts/zones/RuLude_Gardens/DefaultActions')
defaultActions['Splintery_Chest'] = nil

local chest = {}
local perPage = 5

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, 'Splintery Chest')
end

local function defaultSender(player, menu)
    player:timer(50, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

local sendMenu = defaultSender

-- For tests only: a test process that exits with a real menu open crashes
chest.setMenuSender = function(sender)
    sendMenu = sender or defaultSender
end

-- Every reason the player cannot buy from this family now (empty when they can)
chest.problems = function(player, familyKey)
    local family   = config.families[familyKey]
    local problems = {}

    if player:getMainLvl() < config.baseLevel then
        table.insert(problems, string.format('your main job must be level %d', config.baseLevel))
    end

    if progress.getActive(player) ~= 0 and progress.holdsActive(player) then
        local entry = progress.byBase(progress.getActive(player))
        table.insert(problems, string.format('you already have %s in progress; finish it to 119 III first', entry.weapon.name))
    end

    if family.requires and not progress.isDone(player, family.requires) then
        table.insert(problems, string.format('%s weapons unlock after you finish a %s weapon', family.name, config.families[family.requires].name))
    end

    if player:getGil() < config.price then
        table.insert(problems, string.format('it costs %d gil', config.price))
    end

    return problems
end

-- Buys the weapon after checking everything again. Returns true, or false and a reason.
chest.buy = function(player, familyKey, weapon)
    local problems = chest.problems(player, familyKey)

    if #problems > 0 then
        return false, 'You cannot buy it yet: ' .. table.concat(problems, '; ') .. '.'
    end

    if player:hasItem(weapon.base) then
        return false, 'You already have that weapon.'
    end

    if not player:delGil(config.price) then
        return false, 'I could not take the gil.'
    end

    if not player:addItem(weapon.base) then
        player:addGil(config.price)

        return false, 'You have no room for it. Nothing was charged.'
    end

    progress.setActive(player, weapon.base)
    player:messageSpecial(zones[player:getZoneID()].text.ITEM_OBTAINED, weapon.base)

    return true
end

local function confirm(player, familyKey, weapon, page)
    sendMenu(player,
    {
        title   = string.format('Buy %s (%d) for %d gil?', weapon.name, weapon.baseLevel, config.price),
        options =
        {
            {
                'Yes',
                function(playerArg)
                    local ok, reason = chest.buy(playerArg, familyKey, weapon)

                    if ok then
                        say(playerArg, string.format('%s is yours. Take it to the %s Magian Moogle with its materials.', weapon.name, config.families[familyKey].name))
                    else
                        say(playerArg, reason)
                    end
                end,
            },
            { 'No', function(playerArg) chest.showWeapons(playerArg, familyKey, page) end },
        },
    })
end

chest.showWeapons = function(player, familyKey, page)
    local family  = config.families[familyKey]
    local weapons = family.weapons
    local pages   = math.ceil(#weapons / perPage)
    page          = math.max(1, math.min(page or 1, pages))

    local options = {}

    for index = (page - 1) * perPage + 1, math.min(page * perPage, #weapons) do
        local weapon = weapons[index]
        table.insert(options, { weapon.name, function(playerArg) confirm(playerArg, familyKey, weapon, page) end })
    end

    if page < pages then
        table.insert(options, { 'Next', function(playerArg) chest.showWeapons(playerArg, familyKey, page + 1) end })
    end

    if page > 1 then
        table.insert(options, { 'Prev', function(playerArg) chest.showWeapons(playerArg, familyKey, page - 1) end })
    end

    sendMenu(player, { title = string.format('%s weapons (%d/%d)', family.name, page, pages), options = options })
end

local function chooseFamily(player, familyKey)
    local problems = chest.problems(player, familyKey)

    if #problems > 0 then
        say(player, 'You cannot buy a ' .. config.families[familyKey].name .. ' weapon yet: ' .. table.concat(problems, '; ') .. '.')

        return
    end

    chest.showWeapons(player, familyKey, 1)
end

m:addOverride('xi.zones.RuLude_Gardens.npcs.Splintery_Chest.onTrigger', function(player, npc)
    local options = {}

    for _, familyKey in ipairs(config.familyOrder) do
        table.insert(options, { config.families[familyKey].name, function(playerArg) chooseFamily(playerArg, familyKey) end })
    end

    -- Retail: the free Magian trial starter weapons
    table.insert(options, { 'Magian starter', function(playerArg) super(playerArg, npc) end })

    sendMenu(player, { title = string.format('A JSE weapon costs %d gil.', config.price), options = options })
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.jseChest = chest -- for tests

return m
