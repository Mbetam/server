-----------------------------------
-- Ability: Odyllic Subterfuge
-- Greatly reduces the target's magic accuracy.
-- Obtained: Rune Fencer Level 96
-- Recast Time: 01:00:00
-- Duration: 00:00:30
-- Job points: Magic Attack Bonus -2 per rank (up to -40)
-----------------------------------
---@type TAbility
local abilityObject = {}

-- BG Wiki gives no number for "greatly reduces magic accuracy": -40 is an estimate (docs/custom/NOTES.md)
local maccDown = 40
local duration = 30

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0, 0
end

abilityObject.onUseAbility = function(player, target, ability, action)
    local mabDown = player:getJobPointLevel(xi.jp.ODYLLIC_SUBTER_EFFECT) * 2

    if target:addStatusEffect(xi.effect.ODYLLIC_SUBTERFUGE, { power = maccDown, duration = duration, origin = player, subPower = mabDown }) then
        ability:setMsg(xi.msg.basic.JA_ENFEEB_IS)
    else
        ability:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return xi.effect.ODYLLIC_SUBTERFUGE
end

return abilityObject
