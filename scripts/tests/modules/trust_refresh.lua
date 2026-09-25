-----------------------------------
-- modules/custom/lua/trust_refresh.lua: every trust summoned through xi.trust.spawn gets Refresh +50, once.
-----------------------------------

describe('Trust refresh', function()
    local function trustOf(player, spellId)
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                return member
            end
        end
    end

    it('adds Refresh +50 to a trust summoned by its spell, and only once', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 99 })

        -- control: the same trust summoned directly (not through xi.trust.spawn) has its normal refresh
        player:spawnTrust(xi.magic.spell.KUPIPI)
        xi.test.world:skipTime(2)
        local plain = trustOf(player, xi.magic.spell.KUPIPI)
        assert(plain, 'control Kupipi did not spawn')
        local base = plain:getMod(xi.mod.REFRESH)
        player:clearTrusts()
        xi.test.world:skipTime(2)

        xi.trust.spawn(player, GetSpell(xi.magic.spell.KUPIPI))
        xi.test.world:skipTime(2)
        local kupipi = trustOf(player, xi.magic.spell.KUPIPI)
        assert(kupipi, 'Kupipi did not spawn')
        assert(kupipi:getMod(xi.mod.REFRESH) == base + 50, string.format('refresh %d, expected %d', kupipi:getMod(xi.mod.REFRESH), base + 50))

        xi.trust.spawn(player, GetSpell(xi.magic.spell.NAJI))
        xi.test.world:skipTime(2)
        assert(kupipi:getMod(xi.mod.REFRESH) == base + 50, 'a second summon must not add the bonus again')
        local naji = trustOf(player, xi.magic.spell.NAJI)
        assert(naji and naji:getMod(xi.mod.REFRESH) >= 50, 'Naji should have the bonus too')
    end)
end)
