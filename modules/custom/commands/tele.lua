-----------------------------------
-- func: tele, telelist
-- desc: Player-set teleport points.
--       !tele set <name>   saves where you are standing
--       !tele <name>       teleports you to a saved point
--       !tele del <name>   forgets a saved point
--       !telelist          lists your saved points
--       Not usable in battle, in events, or inside battlefields and instances. Points cannot be saved in a Mog House.
-----------------------------------
require('modules/module_utils')
local qol = require('modules/custom/lua/qol_common')
-----------------------------------

local maxPoints     = 10
local maxNameLength = 12
local reservedNames = { set = true, del = true }

-- A point is stored as char vars named tele_<name>_<field>. Char vars are integers, and setting one to 0 DELETES it,
-- but coordinates and rotations are often exactly 0. So every field is scaled by 100 and shifted by a fixed offset,
-- which means a stored value is never 0. A field that reads back as 0 is a deleted (or missing) field.
local storageOffset = 100000000
local fields        = { 'zone', 'x', 'y', 'z', 'rot' }

local function encode(value)
    return math.floor(value * 100 + 0.5) + storageOffset
end

local function decode(stored)
    return (stored - storageOffset) / 100
end

local function varName(name, field)
    return string.format('tele_%s_%s', name, field)
end

-- Lowercases and validates a point name. Returns the name, or nil and the reason it is not allowed.
local function normalizeName(text)
    if text == nil or text == '' then
        return nil, 'Give the point a name.'
    end

    local name = text:lower()

    if not name:match('^[a-z0-9]+$') then
        return nil, 'Point names may only use letters and numbers.'
    end

    if #name > maxNameLength then
        return nil, string.format('Point names can be at most %d characters.', maxNameLength)
    end

    if reservedNames[name] then
        return nil, string.format('"%s" is a reserved word; pick another name.', name)
    end

    return name
end

-- All complete points the player has saved: { [name] = { zone, x, y, z, rot } }
local function readPoints(player)
    local points = {}

    for key, stored in pairs(player:getCharVarsWithPrefix('tele_')) do
        local name, field = key:match('^tele_(%w+)_(%a+)$')

        if name and stored ~= 0 then
            points[name]        = points[name] or {}
            points[name][field] = decode(stored)
        end
    end

    -- Ignore half-written or half-deleted points
    for name, point in pairs(points) do
        for _, field in ipairs(fields) do
            if point[field] == nil then
                points[name] = nil
                break
            end
        end
    end

    return points
end

local function sortedNames(points)
    local names = {}

    for name in pairs(points) do
        table.insert(names, name)
    end

    table.sort(names)

    return names
end

local zoneNames = nil

-- "WEST_RONFAURE" -> "West Ronfaure"
local function zoneName(zoneId)
    if zoneNames == nil then
        zoneNames = {}

        for key, id in pairs(xi.zone) do
            if zoneNames[id] == nil then
                zoneNames[id] = key:lower():gsub('_', ' '):gsub('(%a)(%a*)', function(first, rest) return first:upper() .. rest end)
            end
        end
    end

    return zoneNames[math.floor(zoneId + 0.5)] or 'an unknown zone'
end

local function usage(player)
    qol.say(player, 'Teleport points:')
    qol.say(player, '  !tele set <name>   save where you are standing')
    qol.say(player, '  !tele <name>       teleport to a saved point')
    qol.say(player, '  !tele del <name>   forget a saved point')
    qol.say(player, '  !telelist          list your saved points')
end

local function savePoint(player, name)
    local reason = qol.blockedReason(player)
    if reason then
        qol.say(player, reason)
        return
    end

    if player:inMogHouse() then
        qol.say(player, 'You cannot save a teleport point in a Mog House.')
        return
    end

    local points = readPoints(player)
    local count  = #sortedNames(points)

    -- Replacing a point you already have never counts against the limit
    if points[name] == nil and count >= maxPoints then
        qol.say(player, string.format('You already have %d teleport points. Delete one with !tele del <name>.', maxPoints))
        return
    end

    local values =
    {
        zone = player:getZoneID(),
        x    = player:getXPos(),
        y    = player:getYPos(),
        z    = player:getZPos(),
        rot  = player:getRotPos(),
    }

    for _, field in ipairs(fields) do
        player:setCharVar(varName(name, field), encode(values[field]))
    end

    qol.say(player, string.format('Teleport point "%s" saved in %s.', name, zoneName(values.zone)))
end

local function deletePoint(player, name)
    if readPoints(player)[name] == nil then
        qol.say(player, string.format('You have no teleport point named "%s".', name))
        return
    end

    for _, field in ipairs(fields) do
        player:setCharVar(varName(name, field), 0)
    end

    qol.say(player, string.format('Teleport point "%s" deleted.', name))
end

local function goToPoint(player, name)
    local reason = qol.blockedReason(player)
    if reason then
        qol.say(player, reason)
        return
    end

    local point = readPoints(player)[name]
    if point == nil then
        qol.say(player, string.format('You have no teleport point named "%s". Try !telelist.', name))
        return
    end

    local zoneId = math.floor(point.zone + 0.5)
    local rot    = math.floor(point.rot + 0.5)

    qol.say(player, string.format('Teleporting to "%s" (%s)...', name, zoneName(zoneId)))

    if zoneId == player:getZoneID() then
        player:setPos(point.x, point.y, point.z, rot)
    else
        player:setPos(point.x, point.y, point.z, rot, zoneId)
    end
end

-----------------------------------
-- !tele
-----------------------------------
---@type TCommand
local teleCommand = {}

teleCommand.cmdprops =
{
    permission = 0, -- everyone
    parameters = 'ss',
}

teleCommand.onTrigger = function(player, arg1, arg2)
    if arg1 == nil then
        usage(player)
        return
    end

    local subcommand = arg1:lower()

    if subcommand == 'set' or subcommand == 'del' then
        local name, problem = normalizeName(arg2)
        if name == nil then
            qol.say(player, problem)
            return
        end

        if subcommand == 'set' then
            savePoint(player, name)
        else
            deletePoint(player, name)
        end

        return
    end

    local name = normalizeName(arg1)
    if name == nil then
        qol.say(player, string.format('You have no teleport point named "%s". Try !telelist.', arg1))
        return
    end

    goToPoint(player, name)
end

xi.module.registerCommand('tele', teleCommand)

-----------------------------------
-- !telelist
-----------------------------------
---@type TCommand
local teleListCommand = {}

teleListCommand.cmdprops =
{
    permission = 0, -- everyone
    parameters = '',
}

teleListCommand.onTrigger = function(player)
    local points = readPoints(player)
    local names  = sortedNames(points)

    if #names == 0 then
        qol.say(player, 'You have no teleport points. Save one with !tele set <name>.')
        return
    end

    qol.say(player, string.format('Teleport points (%d/%d):', #names, maxPoints))

    for _, name in ipairs(names) do
        local point = points[name]

        qol.say(player, string.format('  %s: %s (%.0f, %.0f)', name, zoneName(point.zone), point.x, point.z))
    end
end

xi.module.registerCommand('telelist', teleListCommand)
