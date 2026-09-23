-----------------------------------
-- Numbers for the !buff command (modules/custom/commands/buff.lua) and the pool top-up (modules/custom/lua/buff_pool.lua).
-- This is a helper file, not a module: it registers nothing and is only loaded when another file requires it.
-----------------------------------

return
{
    duration = 36000, -- seconds (10 hours)

    -- EXP is Dedication: power is the percentage bonus on kill EXP, applied before the server's EXP_RATE (see xi.experiencePoints.calculate).
    expPercent = 100,

    -- Dedication pays its bonus out of a pool (subPower) and ends when it is empty. The pool is saved to char_effects.subpower,
    -- which is a SIGNED smallint (max 32767): anything bigger makes the whole effects save fail. So the pool is kept under the
    -- limit and buff_pool.lua tops it back up after every kill, which makes it effectively endless.
    expPool = 32000,

    -- Regen and Refresh: power is HP / MP restored every tick (3 seconds).
    regenPower   = 50,
    refreshPower = 50,

    -- Regain: scripts/effects/regain.lua multiplies the effect power by 10 to get the REGAIN mod, and the mod is the TP gained every tick.
    -- So an effect power of 5 is Regain +50.
    regainPower = 5,
}
