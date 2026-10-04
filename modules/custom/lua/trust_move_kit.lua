-----------------------------------
-- Helpers for trust-unique mob skills written with estimated numbers (2026-10-04, Eric's go-ahead), required by the
-- scripts in scripts/actions/mobskills/. BG Wiki lists their numbers as unknown, so each script gives its own fTP
-- estimate, in line with the trust's other moves. Not a module (not in init.txt).
-----------------------------------

local kit = {}

-- Physical (melee or ranged) estimated move. p: { hits, fTP = { a, b, c }, damageType, ranged, ignoreShadows }
kit.physical = function(mob, target, skill, action, p)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = p.hits or 1
    params.fTP            = p.fTP -- TODO: Capture fTPs (estimate)
    params.attackType     = p.ranged and xi.attackType.RANGED or xi.attackType.PHYSICAL
    params.damageType     = p.damageType or xi.damageType.SLASHING
    params.shadowBehavior = p.ignoreShadows and xi.mobskills.shadowBehavior.IGNORE_SHADOWS or xi.mobskills.shadowBehavior.NUMSHADOWS_1

    if params.numHits > 1 then
        params.fTPSubsequentHits = p.fTP
    end

    if p.ranged then
        params.skipParry = true
        params.skipGuard = true
        params.skipBlock = true
    end

    local info = p.ranged and xi.mobskills.mobRangedMove(mob, target, skill, action, params) or
        xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    local landed = xi.mobskills.processDamage(mob, target, skill, action, info)

    if landed then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage, landed
end

-- Magical estimated move. p: { element, fTP = { a, b, c }, drain (heals the user by the damage) }
kit.magical = function(mob, target, skill, action, p)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = p.fTP -- TODO: Capture fTPs (estimate)
    params.element        = p.element
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.ELEMENTAL + p.element
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info   = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    local landed = xi.mobskills.processDamage(mob, target, skill, action, info)

    if landed then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        if p.drain and info.damage > 0 then
            mob:addHP(info.damage)
        end
    end

    return info.damage, landed
end

-- The user's party within `range` (trusts: through their master; mission NPCs: their own party, or themselves)
kit.party = function(mob, range)
    local master  = mob:isTrust() and mob:getMaster() or nil
    local members = master and master:getPartyWithTrusts() or mob:getParty() or { mob }
    local near    = {}

    for _, member in ipairs(members) do
        if member:isAlive() and mob:checkDistance(member) <= (range or 15) then
            table.insert(near, member)
        end
    end

    return near
end

return kit
