/*
===========================================================================

  Custom (not upstream LSB): shorter respawn timers for timed monsters.

  Timed NMs set their own timer from script (mob:setRespawnTime in onMobInitialize / onMobDespawn), so this is
  applied there, in CLuaBaseEntity::setRespawnTime. Settings (map.lua): NM_RESPAWN_CAP, HNM_RESPAWN_CAP,
  HNM_RESPAWN_THRESHOLD. A cap of 0 means off. A timer is only ever shortened, never lengthened, and 0 (which
  means "never respawn") is left alone.

===========================================================================
*/

#pragma once

#include <cstdint>

namespace respawncap
{

// The respawn time (seconds) to actually use.
//   requested: what the script asked for
//   isNM:      the mob is notorious
// A request of at least hnmThreshold is an HNM (retail 18 h+), capped at hnmCap whatever the mob type: King Arthro's
// 21-24 h timer is set on its Knight Crabs, which are not NMs. Any shorter timer on an NM is capped at nmCap.
constexpr auto cappedRespawn(uint32_t requested, bool isNM, uint32_t nmCap, uint32_t hnmCap, uint32_t hnmThreshold) -> uint32_t
{
    if (requested == 0)
    {
        return 0;
    }

    if (hnmThreshold > 0 && requested >= hnmThreshold)
    {
        return (hnmCap > 0 && requested > hnmCap) ? hnmCap : requested;
    }

    if (isNM && nmCap > 0 && requested > nmCap)
    {
        return nmCap;
    }

    return requested;
}

} // namespace respawncap
