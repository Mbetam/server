-----------------------------------
-- Abyssea rework (modules/custom/lua/abyssea_rework.lua): cruor from kills, unlimited Visitant status, NM pop key
-- items at 50%.
-----------------------------------

describe('Abyssea rework', function()
    local rework = xi.custom.abysseaRework

    local function spawn(job)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.ABYSSEA_LA_THEINE, job = job or xi.job.WAR, level = 99 })
        xi.abyssea.afterZoneIn(player) -- test spawns do not run the zone-in hooks

        return player
    end

    local function kill(player, name)
        local mob = player.entities:moveTo(name)
        mob:respawn()
        mob:setUnkillable(false)
        mob:updateClaim(player)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), name .. ' did not die')

        return mob
    end

    it('Visitant status is permanent from entry and stays after an hour', function()
        local player = spawn()
        local effect = player:getStatusEffect(xi.effect.VISITANT)

        assert(effect, 'no Visitant status')
        assert(effect:getIcon() == xi.effect.VISITANT, 'Visitant is the 5-minute grace, not real status')
        assert(effect:getDuration() == 0, 'Visitant has a duration: ' .. effect:getDuration())

        for _ = 1, 60 do
            xi.test.world:skipTime(60)
        end

        assert(player:hasStatusEffect(xi.effect.VISITANT), 'Visitant ran out')
    end)

    it('the Conflux Surveyor and a time chest leave it unlimited', function()
        local player = spawn()

        xi.abyssea.surveyorOnTrigger(player, nil)
        xi.pyxis.time.giveTime(player, player) -- npc argument is only used for its zone

        assert(player:getStatusEffect(xi.effect.VISITANT):getDuration() == 0, 'Visitant became timed')
    end)

    it('every kill pays cruor to each party member in the zone; NMs pay ten times more', function()
        local player = spawn()
        local member = spawn(xi.job.WHM)
        player.actions:inviteToParty(member)
        member.actions:acceptPartyInvite()
        xi.test.world:skipTime(1)

        local sheep = kill(player, 'Irate_Sheep')
        local normal = sheep:getMainLvl() * rework.config.cruorPerLevel
        assert(player:getCurrency('cruor') == normal, string.format('normal kill: %d cruor, expected %d', player:getCurrency('cruor'), normal))

        local mob = kill(player, 'Grandgousier')
        local expected = normal + mob:getMainLvl() * rework.config.nmCruorPerLevel

        assert(player:getCurrency('cruor') == expected, string.format('killer: %d cruor, expected %d', player:getCurrency('cruor'), expected))
        assert(member:getCurrency('cruor') == expected, string.format('member: %d cruor, expected %d', member:getCurrency('cruor'), expected))
    end)

    it('NM pop key items drop 50% of the time (a roll of 40 gives one; LSB needed 20 or less)', function()
        local player = spawn()
        local mob    = player.entities:moveTo('Adamastor')
        mob:respawn()
        mob:setLocalVar('[ClaimedBy]', player:getID()) -- what popping it at its ??? records

        stub('math.randomInt', function(low, high)
            return (low == 1 and high == 100) and 40 or low
        end)

        mob:updateClaim(player)
        mob:takeDamage(mob:getHP() + 1, player, xi.attackType.PHYSICAL, xi.damageType.BLUNT)

        for _ = 1, 3 do
            xi.test.world:skipTime(1)
        end

        assert(mob:isDead(), 'Adamastor did not die')
        assert(player:hasKeyItem(xi.keyItem.DENTED_GIGAS_SHIELD), 'no Dented Gigas Shield on a roll of 40')
    end)
end)
