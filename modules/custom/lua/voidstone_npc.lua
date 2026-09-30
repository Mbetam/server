-----------------------------------
-- Voidstone Keeper (Eric, 2026-09-30): a Mithra in Western Adoulin who hands out Voidwatch voidstones.
-- One voidstone accrues per Vana'diel day (57.6 real minutes), not per Earth day. Unclaimed stones stack up with no
-- limit and are all there the next time you come.
-- Holding: no limit (Eric, 2026-09-30). Key items cannot stack (the game has six, VOIDSTONE1..6, each held or not), so
-- the real count is char var VOIDSTONE_COUNT; the key item list mirrors it up to 6 as a visual. Anything that spends
-- stones later (Voidwatch) must use keeper.spend, not delete the key items.
-- Stored per character: VOIDSTONE_DAY = the Vana'diel day (VanadielUniqueDay) your claims have reached.
-- Note: LSB has no Voidwatch system yet (docs/custom/CONTENT_STATUS.md), so the stones are not used by anything so far.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Western_Adoulin/Zone')
-----------------------------------

local m = Module:new('voidstone_npc')

local keeper = {}

keeper.dayVar   = 'VOIDSTONE_DAY'
keeper.countVar = 'VOIDSTONE_COUNT'

-- Next to the Augmenter (Eric's spot X 29.4549 Z 18.2979); Claude's pick, move with a !pos from Eric
keeper.place = { zoneId = xi.zone.WESTERN_ADOULIN, x = 32.45, y = 0.0, z = 18.30, rotation = 77 }

-- A Mithra (race 7, face 1) in plain clothes, the look of Tih Pikeh in Windurst Woods: 10 byte-swapped uint16s
-- (size, face/race, head, body, hands, legs, feet, main, sub, ranged)
keeper.look = '0x010001070F101020103010401050006000700080'

keeper.stones =
{
    xi.keyItem.VOIDSTONE1,
    xi.keyItem.VOIDSTONE2,
    xi.keyItem.VOIDSTONE3,
    xi.keyItem.VOIDSTONE4,
    xi.keyItem.VOIDSTONE5,
    xi.keyItem.VOIDSTONE6,
}

local function say(player, message)
    player:printToPlayer(message, xi.msg.channel.NS_SAY, 'Voidstone Keeper')
end

local function keyItemsHeld(player)
    local n = 0

    for _, ki in ipairs(keeper.stones) do
        if player:hasKeyItem(ki) then
            n = n + 1
        end
    end

    return n
end

-- How many voidstones the player holds. Stones given while the cap was 6 exist only as key items: they count too.
keeper.held = function(player)
    return math.max(player:getCharVar(keeper.countVar), keyItemsHeld(player))
end

-- The key item list shows min(count, 6) stones
local function syncKeyItems(player, count)
    local want = math.min(count, #keeper.stones)

    for i, ki in ipairs(keeper.stones) do
        if i <= want and not player:hasKeyItem(ki) then
            npcUtil.giveKeyItem(player, ki)
        elseif i > want and player:hasKeyItem(ki) then
            player:delKeyItem(ki)
        end
    end
end

-- For Voidwatch, once it exists: takes n stones if the player has them
keeper.spend = function(player, n)
    local held = keeper.held(player)

    if held < n then
        return false
    end

    player:setCharVar(keeper.countVar, held - n)
    syncKeyItems(player, held - n)

    return true
end

-- Stones waiting for the player (a first visit counts as one day's worth)
keeper.banked = function(player)
    local today = VanadielUniqueDay()
    local last  = player:getCharVar(keeper.dayVar)

    if last == 0 then
        last = today - 1
        player:setCharVar(keeper.dayVar, last)
    end

    return math.max(0, today - last)
end

-- Real minutes until the next Vana'diel midnight (1 game minute = 2.4 real seconds)
local function minutesToNextDay()
    local gameMinutes = (24 - VanadielHour()) * 60 - VanadielMinute()

    return math.max(1, math.ceil(gameMinutes * 2.4 / 60))
end

keeper.onTrigger = function(player, npc)
    local banked = keeper.banked(player)
    local held   = keeper.held(player)

    if banked > 0 then
        held = held + banked
        player:setCharVar(keeper.countVar, held)
        player:setCharVar(keeper.dayVar, player:getCharVar(keeper.dayVar) + banked)
        syncKeyItems(player, held)

        say(player, string.format('Here you go: %d voidstone%s. You now hold %d.', banked, banked == 1 and '' or 's', held))
        say(player, 'One more for every Vana\'diel day; if you do not come, I keep them for you.')
    else
        say(player, string.format('You hold %d voidstone%s. The next one comes with the new Vana\'diel day, in about %d minutes.', held, held == 1 and '' or 's', minutesToNextDay()))
    end
end

m:addOverride('xi.zones.Western_Adoulin.Zone.onInitialize', function(zone)
    super(zone)

    local p = keeper.place

    zone:insertDynamicEntity(
    {
        objtype    = xi.objType.NPC,
        name       = 'Voidstone_Keeper',
        packetName = 'Voidstone Keeper',
        look       = keeper.look,
        x          = p.x,
        y          = p.y,
        z          = p.z,
        rotation   = p.rotation,
        widescan   = 1,
        onTrigger  = keeper.onTrigger,
    })
end)

xi = xi or {}
xi.custom = xi.custom or {}
xi.custom.voidstoneKeeper = keeper -- for tests

return m
