-----------------------------------
-- Voidstone Keeper (modules/custom/lua/voidstone_npc.lua): a Mithra in Western Adoulin; one voidstone per Vana'diel
-- day, unclaimed ones stack with no limit, and there is no limit on how many you hold.
-----------------------------------

describe('Voidstone Keeper', function()
    ---@type CClientEntityPair
    local player
    local keeper = xi.custom.voidstoneKeeper

    local function talk()
        player.entities:gotoAndTrigger('DE_Voidstone_Keeper')
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WESTERN_ADOULIN })
    end)

    it('stands in Western Adoulin as a Mithra', function()
        local npc = player.entities:get('DE_Voidstone_Keeper')
        -- A humanoid look's model id is race * 256 + face (getRace only reads players)
        assert(math.floor(npc:getModelId() / 256) == xi.race.MITHRA, 'not a Mithra (model id ' .. npc:getModelId() .. ')')
    end)

    it('gives one voidstone on the first visit, then nothing until the next Vana\'diel day', function()
        talk()
        assert(keeper.held(player) == 1, 'expected 1 voidstone, got ' .. keeper.held(player))
        assert(player:hasKeyItem(xi.keyItem.VOIDSTONE1), 'no Voidstone key item')

        talk()
        assert(keeper.held(player) == 1, 'a second stone on the same day')

        xi.test.world:skipToNextVanaDay()
        talk()
        assert(keeper.held(player) == 2, 'no stone on the next Vana\'diel day')
    end)

    it('unclaimed stones stack up, and you can hold any number (the key items show up to 6)', function()
        talk() -- first visit: 1
        xi.test.world:skipVanaDays(9)
        talk()
        assert(keeper.held(player) == 10, 'expected 10 held, got ' .. keeper.held(player))
        assert(keeper.banked(player) == 0, 'expected nothing banked, got ' .. keeper.banked(player))

        for _, ki in ipairs(keeper.stones) do
            assert(player:hasKeyItem(ki), 'the key item list should show 6 stones')
        end

        -- Voidwatch-style spending: the count drops, the key items follow once below 6
        assert(keeper.spend(player, 7), 'could not spend 7 of 10')
        assert(keeper.held(player) == 3, 'expected 3 held, got ' .. keeper.held(player))
        assert(player:hasKeyItem(xi.keyItem.VOIDSTONE3) and not player:hasKeyItem(xi.keyItem.VOIDSTONE4), 'the key items should show 3 stones')
        assert(not keeper.spend(player, 4), 'spent more than held')
    end)

    it('stones from before the change (key items only) still count', function()
        player:addKeyItem(xi.keyItem.VOIDSTONE1)
        player:addKeyItem(xi.keyItem.VOIDSTONE2)
        player:addKeyItem(xi.keyItem.VOIDSTONE3)
        talk() -- first visit: 1 more
        assert(keeper.held(player) == 4, 'expected 4 held, got ' .. keeper.held(player))
    end)
end)
