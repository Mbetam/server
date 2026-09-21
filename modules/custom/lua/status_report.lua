-----------------------------------
-- What !status shows about a player, mob, pet or trust.
-- This is a helper file, not a module: it registers nothing and is only loaded when a command module requires it.
-- Every function takes the entity (the same object a script gets as `player` or `mob`) and returns an array of text lines,
-- each short enough for one chat line. Nothing here changes the entity.
--
-- The game does not expose a finished Attack or Defense number to Lua, so those are shown as their bonuses (the ATT/DEF
-- mods). Everything else is the value the game itself uses in combat.
-----------------------------------

local report = {}

report.maxLineLength = 96
report.perPage       = 14

-----------------------------------
-- Names
-----------------------------------

-- Turns an enum table ({ NAME = id }) into { [id] = 'NAME' }. Every id has exactly one name in the generated enums.
local function invert(enum)
    local byId = {}

    for name, id in pairs(enum) do
        byId[id] = name
    end

    return byId
end

-- Built on first use, so the enums are certainly loaded by then
local names = nil

local function nameTables()
    if names == nil then
        names =
        {
            mod    = invert(xi.mod),
            skill  = invert(xi.skill),
            effect = invert(xi.effect),
            job    = invert(xi.job),
        }
    end

    return names
end

-- 'DUAL_WIELD' -> 'Dual Wield'
report.prettify = function(name)
    local words = {}

    for word in string.gmatch(name, '[^_]+') do
        table.insert(words, string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2)))
    end

    return table.concat(words, ' ')
end

-----------------------------------
-- Layout
-----------------------------------

-- Packs short pieces of text ("STR 120", "DEX 99") into as few lines as fit. A piece is never split.
report.pack = function(entries, indent)
    indent = indent or '  '

    local lines   = {}
    local current = nil

    for _, entry in ipairs(entries) do
        if current == nil then
            current = indent .. entry
        elseif #current + 2 + #entry > report.maxLineLength then
            table.insert(lines, current)
            current = indent .. entry
        else
            current = current .. '  ' .. entry
        end
    end

    if current ~= nil then
        table.insert(lines, current)
    end

    return lines
end

-- One page of a list of lines. Returns the lines, the page actually used (out-of-range pages are clamped) and the page count.
report.page = function(lines, page, perPage)
    perPage = perPage or report.perPage

    local pages = math.max(1, math.ceil(#lines / perPage))
    page        = math.max(1, math.min(math.floor(tonumber(page) or 1), pages))

    local slice = {}

    for index = (page - 1) * perPage + 1, math.min(page * perPage, #lines) do
        table.insert(slice, lines[index])
    end

    return slice, page, pages
end

local function signed(value)
    if value > 0 then
        return '+' .. value
    end

    return tostring(value)
end

-----------------------------------
-- What kind of thing this is
-----------------------------------

report.kindOf = function(entity)
    if entity:isPC() then
        return 'Player'
    elseif entity:isTrust() then
        return 'Trust'
    elseif entity:isPet() then
        return 'Pet'
    elseif entity:isMob() then
        return 'Mob'
    end

    return nil
end

-- Why this entity cannot be shown, or nil when it can. NPCs have no stats.
report.refusal = function(entity)
    if entity:isNPC() or report.kindOf(entity) == nil then
        return 'That has no stats to show. Target a player or a monster, or nothing to see your own.'
    end

    return nil
end

-----------------------------------
-- The summary
-----------------------------------

local attributes = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }

local elements = { 'FIRE', 'ICE', 'WIND', 'EARTH', 'THUNDER', 'WATER', 'LIGHT', 'DARK' }

-- Shown only when they are not zero: { mod name, label, divisor }.
-- Gear Haste is stored in hundredths of a percent, so it is divided by 100.
local bonuses =
{
    { 'DUAL_WIELD',        'Dual Wield',   1 },
    { 'DOUBLE_ATTACK',     'Double Att %', 1 },
    { 'TRIPLE_ATTACK',     'Triple Att %', 1 },
    { 'QUAD_ATTACK',       'Quad Att %',   1 },
    { 'CRITHITRATE',       'Crit Rate %',  1 },
    { 'CRIT_DMG_INCREASE', 'Crit Dmg %',   1 },
    { 'STORETP',           'Store TP',     1 },
    { 'TP_BONUS',          'TP Bonus',     1 },
    { 'WSACC',             'WS Acc',       1 },
    { 'HASTE_GEAR',        'Gear Haste %', 100 },
    { 'FASTCAST',          'Fast Cast',    1 },
    { 'CURE_POTENCY',      'Cure Pot %',   1 },
    { 'REFRESH',           'Refresh',      1 },
    { 'REGEN',             'Regen',        1 },
    { 'REGAIN',            'Regain',       1 },
    { 'ENMITY',            'Enmity',       1 },
    { 'COUNTER',           'Counter',      1 },
    { 'SUBTLE_BLOW',       'Subtle Blow',  1 },
    { 'ZANSHIN',           'Zanshin',      1 },
    { 'MARTIAL_ARTS',      'Martial Arts', 1 },
    { 'SHIELDBLOCKRATE',   'Shield Block', 1 },
    { 'DMG',               'Dmg Taken %',  1 },
    { 'DMGPHYS',           'Phys Dmg %',   1 },
    { 'DMGMAGIC',          'Magic Dmg %',  1 },
    { 'DMGRANGE',          'Range Dmg %',  1 },
    { 'DMGBREATH',         'Breath Dmg %', 1 },
}

-- Every mod name the summary reads, so a test can check none has been mistyped
report.summaryModNames = function()
    local list = {}

    for _, name in ipairs(attributes) do
        table.insert(list, name)
    end

    for _, name in ipairs({ 'ATT', 'ATTP', 'DEF', 'DEFP', 'MACC', 'MATT', 'MEVA', 'MDEF' }) do
        table.insert(list, name)
    end

    for _, element in ipairs(elements) do
        table.insert(list, element .. '_MEVA')
    end

    for _, row in ipairs(bonuses) do
        table.insert(list, row[1])
    end

    return list
end

local function mod(entity, name)
    return entity:getMod(xi.mod[name])
end

report.title = function(entity)
    return string.format('== %s (%s) ==', entity:getName(), report.kindOf(entity))
end

report.summary = function(entity)
    local jobs  = nameTables().job
    local lines = { report.title(entity) }

    local level = string.format('Lv %d %s', entity:getMainLvl(), jobs[entity:getMainJob()] or '?')

    if entity:getSubLvl() > 0 then
        level = level .. string.format(' / Lv %d %s', entity:getSubLvl(), jobs[entity:getSubJob()] or '?')
    end

    table.insert(lines, level)

    table.insert(lines, string.format('HP %d/%d (%d%%)  MP %d/%d  TP %d',
        entity:getHP(), entity:getMaxHP(), entity:getHPP(), entity:getMP(), entity:getMaxMP(), math.floor(entity:getTP())))

    -- Attributes: the total the game uses, then the part that comes from gear and effects
    local attributeEntries = {}

    for _, name in ipairs(attributes) do
        local bonus = mod(entity, name)
        local text  = string.format('%s %d', name, entity:getStat(xi.mod[name]))

        if bonus ~= 0 then
            text = text .. ' (' .. signed(bonus) .. ')'
        end

        table.insert(attributeEntries, text)
    end

    table.insert(lines, 'Attributes (total, gear/effects in brackets):')

    for _, line in ipairs(report.pack(attributeEntries)) do
        table.insert(lines, line)
    end

    -- Offense
    table.insert(lines, 'Offense:')

    for _, line in ipairs(report.pack(
    {
        'Acc ' .. entity:getACC(0),
        'Ranged Acc ' .. entity:getRACC(),
        'Ranged Atk ' .. entity:getRATT(),
        'Atk bonus ' .. signed(mod(entity, 'ATT')) .. ' (' .. signed(mod(entity, 'ATTP')) .. '%)',
        'Weapon Dmg ' .. entity:getWeaponDmg(),
        'Delay ' .. entity:getBaseDelay(),
        'M.Acc ' .. mod(entity, 'MACC'),
        'M.Atk ' .. mod(entity, 'MATT'),
    })) do
        table.insert(lines, line)
    end

    -- Defense
    table.insert(lines, 'Defense:')

    for _, line in ipairs(report.pack(
    {
        'Eva ' .. entity:getEVA(),
        'Def bonus ' .. signed(mod(entity, 'DEF')) .. ' (' .. signed(mod(entity, 'DEFP')) .. '%)',
        'M.Eva ' .. mod(entity, 'MEVA'),
        'M.Def ' .. mod(entity, 'MDEF'),
    })) do
        table.insert(lines, line)
    end

    -- Elemental magic evasion
    local elementEntries = {}

    for _, element in ipairs(elements) do
        table.insert(elementEntries, report.prettify(element) .. ' ' .. mod(entity, element .. '_MEVA'))
    end

    table.insert(lines, 'Elemental M.Eva:')

    for _, line in ipairs(report.pack(elementEntries)) do
        table.insert(lines, line)
    end

    -- Everything else that is not zero
    local bonusEntries = {}

    for _, row in ipairs(bonuses) do
        local value = mod(entity, row[1])

        if value ~= 0 then
            table.insert(bonusEntries, string.format('%s %s', row[2], signed(value / row[3])))
        end
    end

    if #bonusEntries > 0 then
        table.insert(lines, 'Bonuses:')

        for _, line in ipairs(report.pack(bonusEntries)) do
            table.insert(lines, line)
        end
    end

    -- Other facts
    local other = { 'Speed ' .. entity:getSpeed() }

    if entity:isPC() then
        table.insert(other, 'Item Level ' .. entity:getAverageItemLevel())
        table.insert(other, 'Merits ' .. entity:getMeritCount())
        table.insert(other, 'Zone ' .. entity:getZoneName())
    end

    for _, line in ipairs(report.pack(other, '')) do
        table.insert(lines, line)
    end

    table.insert(lines, 'More: !status mods | skills | effects | all')

    return lines
end

-----------------------------------
-- Every mod, every skill, every effect
-----------------------------------

-- Every mod that is not zero, alphabetical. The values are the game's raw numbers (gear Haste is in hundredths of a percent).
report.mods = function(entity)
    local byId    = nameTables().mod
    local ids     = {}
    local entries = {}

    for id in pairs(byId) do
        if id ~= xi.mod.NONE then
            table.insert(ids, id)
        end
    end

    table.sort(ids, function(a, b) return byId[a] < byId[b] end)

    for _, id in ipairs(ids) do
        local value = entity:getMod(id)

        if value ~= 0 then
            table.insert(entries, string.format('%s %s', byId[id], signed(value)))
        end
    end

    local lines = { report.title(entity), string.format('All modifiers that are not zero (%d), raw values:', #entries) }

    for _, line in ipairs(report.pack(entries)) do
        table.insert(lines, line)
    end

    return lines
end

local skillFlag = 0x7FFF

-- Every skill above zero. A player also sees the cap their main job gives at their level, where there is one.
report.skills = function(entity)
    local byId    = nameTables().skill
    local ids     = {}
    local entries = {}

    for id in pairs(byId) do
        if id ~= xi.skill.NONE then
            table.insert(ids, id)
        end
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        local value = entity:getSkillLevel(id)

        -- Riding and Digging are stored as 32767 for everyone: a flag, not a skill level
        if value > 0 and value < skillFlag then
            local text = string.format('%s %d', report.prettify(byId[id]), value)

            if entity:isPC() then
                local cap = entity:getMaxSkillLevel(entity:getMainLvl(), entity:getMainJob(), id)

                if cap > 0 then
                    text = text .. '/' .. cap
                end
            end

            table.insert(entries, text)
        end
    end

    local lines = { report.title(entity) }

    if #entries == 0 then
        table.insert(lines, 'No skills above zero.')
    else
        table.insert(lines, string.format('Skills (%d)%s:', #entries, entity:isPC() and ', with the main job cap' or ''))

        for _, line in ipairs(report.pack(entries)) do
            table.insert(lines, line)
        end
    end

    return lines
end

local function timeLeft(milliseconds)
    local seconds = math.floor(milliseconds / 1000)

    if seconds >= 3600 then
        return string.format('%dh%02dm', math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end

    return string.format('%d:%02d', math.floor(seconds / 60), seconds % 60)
end

-- Every status effect on the entity, with power and time left.
report.effects = function(entity)
    local byId    = nameTables().effect
    local entries = {}

    for _, effect in ipairs(entity:getStatusEffects() or {}) do
        local id   = effect:getEffectType()
        local text = string.format('%s (power %d)', report.prettify(byId[id] or ('effect ' .. id)), effect:getPower())

        if effect:getDuration() > 0 then
            text = text .. ' ' .. timeLeft(effect:getTimeRemaining())
        end

        table.insert(entries, text)
    end

    table.sort(entries)

    local lines = { report.title(entity) }

    if #entries == 0 then
        table.insert(lines, 'No status effects.')
    else
        table.insert(lines, string.format('Status effects (%d):', #entries))

        for _, entry in ipairs(entries) do
            table.insert(lines, '  ' .. entry)
        end
    end

    return lines
end

-----------------------------------
-- Choosing what to show
-----------------------------------

report.sections = { 'summary', 'mods', 'skills', 'effects', 'all' }

report.usage = 'Try !status, !status mods [page], !status skills, !status effects or !status all.'

-- What !status prints. `section` is one of report.sections (nil means summary), `page` only matters for mods.
-- Returns the lines, or nil and a message for the player.
report.run = function(entity, section, page)
    section = section and string.lower(tostring(section)) or 'summary'

    -- "!status 2" is a shortcut for the second page of mods
    if tonumber(section) ~= nil then
        page    = section
        section = 'mods'
    end

    local known = false

    for _, name in ipairs(report.sections) do
        known = known or name == section
    end

    if not known then
        return nil, report.usage
    end

    local refusal = report.refusal(entity)
    if refusal then
        return nil, refusal
    end

    -- A stat that cannot be read must never take the command down, so report the failure and move on
    local ok, result = pcall(function()
        if section == 'summary' then
            return report.summary(entity)
        elseif section == 'skills' then
            return report.skills(entity)
        elseif section == 'effects' then
            return report.effects(entity)
        elseif section == 'mods' then
            local lines              = report.mods(entity)
            local header             = table.remove(lines, 1)
            local subheader          = table.remove(lines, 1)
            local slice, used, pages = report.page(lines, page)

            table.insert(slice, 1, subheader)
            table.insert(slice, 1, header)
            table.insert(slice, string.format('Page %d of %d%s', used, pages, used < pages and (' - next: !status mods ' .. (used + 1)) or ''))

            return slice
        end

        local everything = {}

        for _, list in ipairs({ report.summary(entity), report.skills(entity), report.effects(entity), report.mods(entity) }) do
            for _, line in ipairs(list) do
                table.insert(everything, line)
            end
        end

        return everything
    end)

    if not ok then
        print(string.format('[status] could not read %s: %s', entity:getName(), tostring(result)))

        return nil, 'Could not read that target\'s stats.'
    end

    return result
end

return report
