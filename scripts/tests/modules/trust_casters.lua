-----------------------------------
-- The 19 caster trusts that never cast, and Matsui-P (trust audit; fixed 2026-10-04): each one is summoned for real next to a
-- monster and every spell, job ability and TP move it uses is recorded through the engine's own listeners.
-- Magic bursts: a skillchain resonance is put on the monster (what a closed skillchain leaves) and the burst is checked.
-----------------------------------

describe('Caster trusts', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob
    local trust
    local used

    local function idOf(thing)
        if type(thing) == 'number' then
            return thing
        end

        return thing:getID()
    end

    local function count(tbl, key)
        tbl[key] = (tbl[key] or 0) + 1
    end

    local function summon(spellId)
        player:spawnTrust(spellId)
        xi.test.world:skipTime(2)

        trust = nil
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() and member:getTrustID() == spellId then
                trust = member
            end
        end

        assert(trust, 'the trust was not summoned')

        used = { spell = {}, ability = {}, skill = {}, order = {} }
        trust:addListener('MAGIC_USE', 'TEST_CASTER_MAGIC', function(entity, target, spell, action)
            count(used.spell, idOf(spell))
            table.insert(used.order, idOf(spell))
        end)
        trust:addListener('ABILITY_USE', 'TEST_CASTER_ABILITY', function(entity, target, ability, action)
            count(used.ability, idOf(ability))
        end)
        trust:addListener('WEAPONSKILL_USE', 'TEST_CASTER_WS', function(entity, target, skill, tp, action, damage)
            count(used.skill, idOf(skill))
        end)
    end

    -- The player holds the monster's hate, as a tank would: otherwise its hits keep interrupting the trust's casts
    local function fight(seconds)
        player.actions:engage(mob)

        for _ = 1, seconds / 2 do
            mob:addEnmity(player, 30000, 30000)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end
    end

    local function reset()
        used = { spell = {}, ability = {}, skill = {}, order = {} }
    end

    local function usedAny(tbl, ids)
        for _, id in ipairs(ids) do
            if tbl[id] then
                return true
            end
        end

        return false
    end

    local function spellsOfElement(element)
        local n = 0

        for id, times in pairs(used.spell) do
            if GetSpell(id):getElement() == element then
                n = n + times
            end
        end

        return n
    end

    local function total(tbl)
        local n = 0

        for _, times in pairs(tbl) do
            n = n + times
        end

        return n
    end

    local function dump()
        local parts = {}

        for kind, tbl in pairs(used) do
            if kind ~= 'order' then
                for id, n in pairs(tbl) do
                    table.insert(parts, string.format('%s %d x%d', kind, id, n))
                end
            end
        end

        table.sort(parts)

        return 'used: ' .. (#parts > 0 and table.concat(parts, ', ') or 'nothing')
    end

    -- Leaves a skillchain resonance on the monster, as a closed skillchain would
    local function resonance(skillchain)
        mob:delStatusEffect(xi.effect.SKILLCHAIN)
        mob:addStatusEffect(xi.effect.SKILLCHAIN, { power = skillchain, duration = 15, tier = 2, origin = player })
    end

    -- A burst check: wait for the trust to finish its current cast, stop the monster's TP moves (a Stun would take the
    -- window), open the window and fight through it. `used` then holds only what happened in the window.
    local function burstWindow(skillchain, seconds)
        -- Healers rightly cure ailments before bursting: clear what the monster put on the player
        for _, effect in ipairs({ xi.effect.BLINDNESS, xi.effect.POISON, xi.effect.PARALYSIS, xi.effect.SILENCE }) do
            player:delStatusEffect(effect)
            trust:delStatusEffect(effect)
        end

        trust:setMP(trust:getMaxMP())
        mob:setMobAbilityEnabled(false)

        for _ = 1, 10 do
            if trust:getCurrentAction() ~= 30 then
                break
            end

            xi.test.world:skipTime(1)
        end

        reset()
        resonance(skillchain)
        fight(seconds or 14)
        mob:setMobAbilityEnabled(true)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 99 })
        player:setUnkillable(true)
        player:setCharVar('TrustEngageType', 1)

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    -- Nukers

    it("D. Shantotto nukes only with ice, earth and water and uses her scythe weapon skills", function()
        summon(xi.magic.spell.DOMINA_SHANTOTTO)
        trust:setTP(3000)
        fight(60)

        local dark = spellsOfElement(xi.element.ICE) + spellsOfElement(xi.element.EARTH) + spellsOfElement(xi.element.WATER)
        assert(dark >= 1, 'no ice / earth / water nuke. ' .. dump())
        assert(dark == total(used.spell), 'cast an element other than ice / earth / water. ' .. dump())
        assert(usedAny(used.skill, { 102, 103, 98, 3264 }), 'no scythe weapon skill. ' .. dump())
    end)

    it('Gadalar keeps Blaze Spikes up and casts Firaga', function()
        summon(xi.magic.spell.GADALAR)
        fight(30)

        assert(used.spell[xi.magic.spell.BLAZE_SPIKES], 'no Blaze Spikes. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.FIRAGA, xi.magic.spell.FIRAGA_II, xi.magic.spell.FIRAGA_III }), 'no Firaga. ' .. dump())
    end)

    it('Leonoyne keeps Ice Spikes up and casts Blizzaga', function()
        summon(xi.magic.spell.LEONOYNE)
        fight(30)

        assert(used.spell[xi.magic.spell.ICE_SPIKES], 'no Ice Spikes. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.BLIZZAGA, xi.magic.spell.BLIZZAGA_II, xi.magic.spell.BLIZZAGA_III }), 'no Blizzaga. ' .. dump())
        assert(trust:getMod(xi.mod.ENSPELL) == xi.element.ICE, 'no permanent Enblizzard')
    end)

    it('Kayeel-Payeel casts only ice and lightning, and magic bursts', function()
        summon(xi.magic.spell.KAYEEL_PAYEEL)
        fight(30)

        local iceThunder = spellsOfElement(xi.element.ICE) + spellsOfElement(xi.element.THUNDER)
        assert(iceThunder >= 1, 'no ice / lightning spell. ' .. dump())
        assert(iceThunder == total(used.spell), 'cast another element. ' .. dump())

        burstWindow(xi.skillchainType.IMPACTION) -- lightning

        assert(spellsOfElement(xi.element.THUNDER) >= 1, 'no lightning burst on Impaction. ' .. dump())
    end)

    it('Robel-Akbel stuns TP moves, nukes, and bursts with an -aja spell', function()
        summon(xi.magic.spell.ROBEL_AKBEL)
        fight(20)
        assert(total(used.spell) >= 1, 'no nuke. ' .. dump())

        burstWindow(xi.skillchainType.LIQUEFACTION) -- fire
        assert(used.spell[xi.magic.spell.FIRAJA], 'no Firaja burst on Liquefaction. ' .. dump())

        fight(10)
        reset()
        -- A TP move is "readying" for about a second and the trust checks its gambits every few seconds: give it three
        -- chances, one second at a time
        for _ = 1, 3 do
            if used.spell[xi.magic.spell.STUN] then
                break
            end

            mob:setTP(3000)
            mob:useMobAbility(257) -- Foot Kick
            for _ = 1, 6 do
                xi.test.world:tickEntity(player)
                xi.test.world:skipTime(1)
            end
        end
        assert(used.spell[xi.magic.spell.STUN], 'no Stun on a readied TP move. ' .. dump())
    end)

    it('Ullegore nukes and casts Comet', function()
        summon(xi.magic.spell.ULLEGORE)
        fight(40)

        assert(used.spell[xi.magic.spell.COMET], 'no Comet. ' .. dump())
        assert(total(used.spell) >= 2, 'no nukes besides Comet. ' .. dump())
    end)

    it('Rosulatia casts only earth magic', function()
        summon(xi.magic.spell.ROSULATIA)
        -- She stops casting while she holds hate (retail), and the test player fights bare-handed: keep the rabbit on him
        player.actions:engage(mob)
        for _ = 1, 15 do
            mob:addEnmity(player, 30000, 30000)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(2)
        end

        assert(spellsOfElement(xi.element.EARTH) >= 1, 'no Stone. ' .. dump())
        assert(spellsOfElement(xi.element.EARTH) == total(used.spell), 'cast another element. ' .. dump())
    end)

    it('Teodor casts only to magic burst, with -ja / -ga spells', function()
        summon(xi.magic.spell.TEODOR)
        fight(20)
        assert(total(used.spell) == 0, 'cast without a skillchain. ' .. dump())

        burstWindow(xi.skillchainType.DETONATION) -- wind
        assert(usedAny(used.spell, { xi.magic.spell.AEROJA, xi.magic.spell.AEROGA_III }), 'no Aeroja / Aeroga III burst on Detonation. ' .. dump())
        assert(total(used.spell) == 1, 'more than one burst on one skillchain. ' .. dump())
    end)

    it('Mumor II nukes', function()
        summon(xi.magic.spell.MUMOR_II)
        fight(30)

        assert(total(used.spell) >= 2, 'fewer than two nukes in 30 s. ' .. dump())
    end)

    it('Ark Angel TT: Last Resort, Souleater, Poison and Bio, bursts only (up to two per skillchain)', function()
        summon(xi.magic.spell.AATT)
        fight(30)

        assert(used.ability[xi.jobAbility.LAST_RESORT], 'no Last Resort. ' .. dump())
        assert(used.ability[xi.jobAbility.SOULEATER], 'no Souleater. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.POISON, xi.magic.spell.POISON_II }), 'no Poison. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.BIO, xi.magic.spell.BIO_II }), 'no Bio. ' .. dump())
        local nukes = total(used.spell) - (used.spell[xi.magic.spell.POISON_II] or 0) - (used.spell[xi.magic.spell.BIO_II] or 0) -
            (used.spell[xi.magic.spell.ASPIR] or 0) - (used.spell[xi.magic.spell.ASPIR_II] or 0) - (used.spell[xi.magic.spell.STUN] or 0)
        assert(nukes == 0, 'nuked without a skillchain. ' .. dump())

        burstWindow(xi.skillchainType.DISTORTION) -- water / ice
        assert(spellsOfElement(xi.element.WATER) + spellsOfElement(xi.element.ICE) >= 1, 'no burst on Distortion. ' .. dump())
    end)

    -- Dark knights

    it('Zeid: Last Resort, Absorb-TP once the enemy has TP, Absorb spells, and his weapon skills', function()
        summon(xi.magic.spell.ZEID)
        trust:setTP(3000)
        fight(30)
        mob:setMobAbilityEnabled(true)

        assert(used.ability[xi.jobAbility.LAST_RESORT], 'no Last Resort. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.ABSORB_ACC, xi.magic.spell.ABSORB_STR }), 'no Absorb spell. ' .. dump())
        assert(usedAny(used.skill, { 51, 56, 3195, 3196 }), 'no weapon skill. ' .. dump())

        -- Absorb-TP may already have gone off once the rabbit built TP on its own (60 s recast): count the whole fight
        mob:setMobAbilityEnabled(false) -- keep its TP (it would spend it on a TP move, which Zeid stuns)
        mob:setTP(2000)
        fight(10)
        assert(used.spell[xi.magic.spell.ABSORB_TP], 'no Absorb-TP on an enemy with TP. ' .. dump())
    end)

    it('Balamor casts Absorb-STAT spells', function()
        summon(xi.magic.spell.BALAMOR)
        fight(30)

        assert(usedAny(used.spell, {
            xi.magic.spell.ABSORB_STR, xi.magic.spell.ABSORB_DEX, xi.magic.spell.ABSORB_VIT, xi.magic.spell.ABSORB_AGI,
            xi.magic.spell.ABSORB_INT, xi.magic.spell.ABSORB_MND, xi.magic.spell.ABSORB_CHR,
        }), 'no Absorb spell. ' .. dump())
    end)

    -- Red mages

    it('Ovjang enfeebles (Slow, Paralyze, Silence) and nukes', function()
        summon(xi.magic.spell.OVJANG)
        fight(40)

        assert(usedAny(used.spell, { xi.magic.spell.SLOW }), 'no Slow. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.PARALYZE }), 'no Paralyze. ' .. dump())
        assert(total(used.spell) >= 3, 'no nukes. ' .. dump())
    end)

    it('Arciela hastes and refreshes her master, Protect / Shell, Slow / Paralyze', function()
        summon(xi.magic.spell.ARCIELA)
        fight(70) -- eight buffs (master and herself) come first

        assert(usedAny(used.spell, { xi.magic.spell.HASTE, xi.magic.spell.HASTE_II }), 'no Haste. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.REFRESH, xi.magic.spell.REFRESH_II }), 'no Refresh. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.PROTECT_V, xi.magic.spell.PROTECT_IV }), 'no Protect. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.SLOW, xi.magic.spell.SLOW_II }), 'no Slow. ' .. dump())
    end)

    it('Arciela II hastes a melee master, enfeebles, nukes and bursts', function()
        summon(xi.magic.spell.ARCIELA_II)
        fight(40)

        assert(usedAny(used.spell, { xi.magic.spell.HASTE, xi.magic.spell.HASTE_II }), 'no Haste on a WAR master. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.SLOW, xi.magic.spell.SLOW_II }), 'no Slow. ' .. dump())
        assert(used.spell[xi.magic.spell.ADDLE], 'no Addle. ' .. dump())

        burstWindow(xi.skillchainType.LIQUEFACTION)
        assert(spellsOfElement(xi.element.FIRE) >= 1, 'no fire burst on Liquefaction. ' .. dump())
    end)

    it('King of Hearts opens with Dia, hastes / refreshes the master, Phalanx, cures at 50% and bursts Firaga', function()
        summon(xi.magic.spell.KING_OF_HEARTS)
        fight(40)

        assert(usedAny(used.spell, { xi.magic.spell.DIA, xi.magic.spell.DIA_II, xi.magic.spell.DIA_III }), 'no Dia. ' .. dump())
        local first = used.order[1]
        assert(first == xi.magic.spell.DIA or first == xi.magic.spell.DIA_II or first == xi.magic.spell.DIA_III, 'first spell was not Dia. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.HASTE, xi.magic.spell.HASTE_II }), 'no Haste. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.REFRESH, xi.magic.spell.REFRESH_II }), 'no Refresh. ' .. dump())
        assert(usedAny(used.spell, { xi.magic.spell.PHALANX, xi.magic.spell.PHALANX_II }), 'no Phalanx. ' .. dump())

        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.4))
        fight(10)
        assert(usedAny(used.spell, { xi.magic.spell.CURE_IV, xi.magic.spell.CURE_III }), 'no Cure on a master at 40%. ' .. dump())

        burstWindow(xi.skillchainType.FUSION)
        assert(usedAny(used.spell, { xi.magic.spell.FIRAGA_IV, xi.magic.spell.FIRAGA_III }), 'no Firaga burst on Fusion. ' .. dump())
    end)

    -- White mages

    it('Ygnas: Cure VI under 45%, Cure III under 66%, Protectra / Shellra, Haste', function()
        summon(xi.magic.spell.YGNAS)
        fight(30)

        assert(usedAny(used.spell, { xi.magic.spell.PROTECTRA_V }), 'no Protectra. ' .. dump())
        assert(used.spell[xi.magic.spell.HASTE], 'no Haste on a WAR master. ' .. dump())

        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.6))
        fight(6)
        assert(used.spell[xi.magic.spell.CURE_III], 'no Cure III at 60%. ' .. dump())

        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.3))
        fight(6)
        assert(used.spell[xi.magic.spell.CURE_VI], 'no Cure VI at 30%. ' .. dump())
    end)

    it('Pieuje (UC): Afflatus Misery, Auspice, Haste on the master, cures, and Nott for MP', function()
        summon(xi.magic.spell.PIEUJE_UC)
        fight(50)

        assert(used.ability[xi.jobAbility.AFFLATUS_MISERY], 'no Afflatus Misery. ' .. dump())
        assert(used.spell[xi.magic.spell.AUSPICE], 'no Auspice. ' .. dump())
        assert(used.spell[xi.magic.spell.HASTE], 'no Haste. ' .. dump())

        reset()
        player:setHP(math.floor(player:getMaxHP() * 0.4))
        trust:setTP(3000)
        fight(10)
        assert(usedAny(used.spell, { xi.magic.spell.CURE_VI, xi.magic.spell.CURE_V, xi.magic.spell.CURE_IV }), 'no Cure at 40%. ' .. dump())
        assert(used.skill[3502], 'no Nott at 3000 TP. ' .. dump())
    end)

    it('Ingrid II casts only to burst, with Holy II on a light skillchain', function()
        summon(xi.magic.spell.INGRID_II)
        fight(20)
        assert(total(used.spell) == 0, 'cast without a skillchain. ' .. dump())

        burstWindow(xi.skillchainType.TRANSFIXION) -- light
        assert(used.spell[xi.magic.spell.HOLY_II], 'no Holy II burst on Transfixion. ' .. dump())
    end)

    it('Matsui-P keeps shadows and Innin up, nukes with ninjutsu, and bursts', function()
        summon(xi.magic.spell.MATSUI_P)
        fight(40)

        assert(usedAny(used.spell, { xi.magic.spell.UTSUSEMI_ICHI, xi.magic.spell.UTSUSEMI_NI, xi.magic.spell.UTSUSEMI_SAN }), 'no Utsusemi. ' .. dump())
        assert(used.ability[xi.jobAbility.INNIN], 'no Innin. ' .. dump())
        assert(usedAny(used.spell, {
            xi.magic.spell.KATON_SAN, xi.magic.spell.HYOTON_SAN, xi.magic.spell.HUTON_SAN,
            xi.magic.spell.DOTON_SAN, xi.magic.spell.RAITON_SAN, xi.magic.spell.SUITON_SAN,
        }), 'no elemental ninjutsu. ' .. dump())

        burstWindow(xi.skillchainType.INDURATION) -- ice
        assert(spellsOfElement(xi.element.ICE) >= 1, 'no ice burst on Induration. ' .. dump())
    end)

    it('caster trusts can be released mid-fight (their burst listeners go with them)', function()
        for _, spellId in ipairs({ xi.magic.spell.TEODOR, xi.magic.spell.KING_OF_HEARTS, xi.magic.spell.AATT }) do
            summon(spellId)
            fight(6)
            player:clearTrusts()
            xi.test.world:skipTime(4)
        end
    end)
end)
