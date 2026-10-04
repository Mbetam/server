-----------------------------------
-- Trust: Teodor
-- Retail (BG Wiki BGWiki:Trusts): BLM/DRK, HP+35%, MP+50%. Only uses his elemental magic to magic burst, with -ja and
-- -ga spells. Left out: Start from Scratch and his TP moves (Sinner's Cross, Ravenous Assault, Frenzied Thrust, Open
-- Coffin, Hemocladis: trust-unique, no scripts), his special melee attacks.
-----------------------------------
local kit = require('modules/custom/lua/trust_caster_kit')

-- Magic burst order: -ja, then -ga III / II / I
local burstSpells =
{
    { xi.magic.spell.FIRAJA, 90 },
    { xi.magic.spell.BLIZZAJA, 93 },
    { xi.magic.spell.AEROJA, 87 },
    { xi.magic.spell.STONEJA, 81 },
    { xi.magic.spell.THUNDAJA, 87 },
    { xi.magic.spell.WATERJA, 84 },
    { xi.magic.spell.FIRAGA_III, 69 },
    { xi.magic.spell.BLIZZAGA_III, 71 },
    { xi.magic.spell.AEROGA_III, 67 },
    { xi.magic.spell.STONEGA_III, 63 },
    { xi.magic.spell.THUNDAGA_III, 73 },
    { xi.magic.spell.WATERGA_III, 65 },
    { xi.magic.spell.FIRAGA_II, 53 },
    { xi.magic.spell.BLIZZAGA_II, 57 },
    { xi.magic.spell.AEROGA_II, 48 },
    { xi.magic.spell.STONEGA_II, 40 },
    { xi.magic.spell.THUNDAGA_II, 61 },
    { xi.magic.spell.WATERGA_II, 44 },
    { xi.magic.spell.FIRAGA, 28 },
    { xi.magic.spell.BLIZZAGA, 32 },
    { xi.magic.spell.AEROGA, 23 },
    { xi.magic.spell.STONEGA, 15 },
    { xi.magic.spell.THUNDAGA, 36 },
    { xi.magic.spell.WATERGA, 19 },
}

---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 35)
    mob:addMod(xi.mod.MPP, 50)

    kit.onCombatTick(mob, 'TEODOR_BURST', function(mobArg)
        kit.burstTick(mobArg, burstSpells, 1)
    end)
end

spellObject.onMobDespawn = function(mob)
    kit.cleanup(mob, 'TEODOR_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    kit.cleanup(mob, 'TEODOR_BURST')
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
