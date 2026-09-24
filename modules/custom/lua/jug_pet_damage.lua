-----------------------------------
-- Jug pets (BST Call Beast / Bestial Loyalty) deal more damage than retail (Eric's choice, 2026-09-24).
--   Ready moves: the final damage of every move is multiplied (xi.mobskills.processDamage runs right before the damage
--                is applied, for physical, magical and breath moves alike).
--   Auto-attacks: the pet's weapon damage multiplier is raised (mobMod BASE_DAMAGE_MULTIPLIER, C++). It scales the
--                 weapon-damage part of each hit, so the total gain is a little under the full multiplier.
-- Charmed monsters, wyverns, avatars, automatons and luopans are not affected.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobskills')
require('scripts/globals/job_utils/beastmaster')
-----------------------------------

local multiplier = 1.5 -- +50%

-- True for a jug pet (not a charmed monster or another job's pet)
local function isJugPet(entity)
    if entity == nil or not entity:isPet() then
        return false
    end

    local master = entity:getMaster()

    return master ~= nil and master:isPC() and master:hasJugPet() and master:getPet() ~= nil and master:getPet():getID() == entity:getID()
end

-- Every jug pet has cmbDmgMult 100 (checked 2026-09-24), so this mobMod (which replaces it) gives exactly x1.5
local function boostAutoAttacks(player)
    local pet = player:getPet()

    if pet and player:hasJugPet() then
        pet:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, math.floor(100 * multiplier))
    end
end

local m = Module:new('jug_pet_damage')

m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    if info and info.damage and info.damage > 0 and isJugPet(actor) then
        info.damage = math.floor(info.damage * multiplier)
    end

    return super(actor, target, skill, action, info)
end)

m:addOverride('xi.job_utils.beastmaster.useCallBeast', function(player, target, ability)
    local result = super(player, target, ability)
    boostAutoAttacks(player)

    return result
end)

m:addOverride('xi.job_utils.beastmaster.useBestialLoyalty', function(player, target, ability)
    local result = super(player, target, ability)
    boostAutoAttacks(player)

    return result
end)
