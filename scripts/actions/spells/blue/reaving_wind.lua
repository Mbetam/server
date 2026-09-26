-----------------------------------
-- Spell: Reaving Wind
-- Reduces the TP of enemies in range.
-- Level: 90, Type: Magical, Monster: Amphiptere (Dragon)
-- Custom (2026-09-25): LSB had no script for this spell. Values from BG Wiki; TP -1000; -750 vs Amorphs and -1250 vs Aquans (monster correlation)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local resist = xi.combat.magicHitRate.calculateResistRate(caster, target,
    {
        effectId       = xi.effect.NONE,
        magicalElement = spell:getElement(),
        actorStat      = xi.mod.INT,
        skillType      = xi.skill.BLUE_MAGIC,
        spellGroup     = spell:getSpellGroup(),
    })

    if resist < 0.5 or target:getTP() <= 0 then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return 0
    end

    local amount    = 1000
    local ecosystem = target:getEcosystem()

    if ecosystem == xi.ecosystem.AMORPH then
        amount = 750
    elseif ecosystem == xi.ecosystem.AQUAN then
        amount = 1250
    end

    target:setTP(math.max(0, target:getTP() - amount))
    spell:setMsg(xi.msg.basic.MAGIC_TP_REDUCE)

    return amount
end

return spellObject
