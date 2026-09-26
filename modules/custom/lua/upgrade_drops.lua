-----------------------------------
-- Upgrade material drops: adds the Armor Upgrader's materials whose retail content is not in LSB to the loot of the
-- monsters listed in upgrade_drops_config.lua. On only where the Armor Upgrader is (ENABLE_ARMOR_UPGRADER).
-- The game calls xi.mob.onMobDeathEx for each alliance member BEFORE it rolls the drops, so the killer's call adds an
-- ITEM_DROPS listener to the mob; the listener then adds the items to the normal loot roll (same treasure pool, same
-- drop multiplier). A listener with the same name replaces the old one, so a respawned mob never stacks them.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
local config = require('modules/custom/lua/upgrade_drops_config')
-----------------------------------

local m = Module:new('upgrade_drops')

local upgradeDrops = {}

-- The tiers a mob drops from: its zone's tier (notorious monsters only) and its named tiers
upgradeDrops.tiersFor = function(mob)
    local tiers  = {}
    local zoneId = mob:getZoneID()

    if config.zones[zoneId] and mob:isNM() then
        for _, tier in ipairs(config.zones[zoneId]) do
            table.insert(tiers, tier)
        end
    end

    local named = config.named[zoneId] and config.named[zoneId][mob:getName()]
    if named then
        for _, tier in ipairs(named) do
            table.insert(tiers, tier)
        end
    end

    return tiers
end

local function addDrop(loot, what, rate, quantity, job)
    local base = config.jobBase[what]

    if what == 'card' then
        loot:addItem(base + job, rate, quantity or 1)
    elseif what == 'shard' or what == 'void' then
        -- One job item of a random slot per roll
        local items = {}

        for slot = 1, 5 do
            table.insert(items, { item = base[slot] + job })
        end

        for _ = 1, quantity or 1 do
            loot:addGroup(rate, items)
        end
    elseif config.groups[what] then
        local items = {}

        for _, itemId in ipairs(config.groups[what]) do
            table.insert(items, { item = itemId })
        end

        loot:addGroup(rate, items)
    elseif config.item[what] then
        loot:addItem(config.item[what], rate, quantity or 1)
    end
end

-- Adds every drop of the given tiers to a loot container; job is the killer's main job
upgradeDrops.addLoot = function(loot, tiers, job)
    for _, tier in ipairs(tiers) do
        for _, drop in ipairs(config.tiers[tier] or {}) do
            addDrop(loot, drop[1], drop[2], drop[3], job)
        end
    end
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    if isKiller and player and xi.settings.main.ENABLE_ARMOR_UPGRADER then
        local tiers = upgradeDrops.tiersFor(mob)

        if #tiers > 0 then
            local job = player:getMainJob()

            mob:addListener('ITEM_DROPS', 'CUSTOM_UPGRADE_DROPS', function(mobArg, loot)
                upgradeDrops.addLoot(loot, tiers, job)
            end)
        end
    end

    return super(mob, player, isKiller, isWeaponSkillKill)
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.upgradeDrops = upgradeDrops -- for tests

return m
