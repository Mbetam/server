# Content status vs retail (2026-09-28)

What retail content has no code on this server, and what has code that is incomplete or known broken.
LSB stopped keeping a "What Works" list (wiki FAQ: "check the code"), so this comes from the code itself:
`tools/custom/content_audit.py` (rerun it to refresh the numbers), zone data, entry NPCs and teleports, TODOs in the
system scripts, and our own findings in `docs/custom/NOTES.md`.
Caveat: "has a script" is not proof it works like retail. Items marked **(check in game)** could not be settled from
the code.

## 1. Not coded (no way to play it)

| Content | Evidence |
|---|---|
| **Limbus (Temenos / Apollyon)** | 23 of its battlefields have no script, no entry. Zones and monsters exist, unreachable. |
| **Rhapsodies of Vana'diel chapter 3** (missions 104-226, 51 missions) | No scripts from "Where Divinities Collide" on. Blocks Escha Ru'Aun, Reisenjima story, the later Rhapsody key items (Emerald, Mauve, Fuchsia, Puce, Ochre). Chapters 1-2 play. |
| **Coalition assignments (Adoulin)** | 0 of 95 scripted. |
| **Sortie** | Outer Ra'Kaznar [U2]/[U3] have no monsters and no entry. |
| **Odyssey (Sheol)** | Walk of Echoes [P1]/[P2] have monsters but no entry. |
| **Dynamis Divergence ([D] zones)** | ~800 monsters per zone, no entry. |
| **Omen** | Reisenjima Sanctorium has no entry. |
| **Walk of Echoes (event content)** | Zone only used by two RoV missions. |
| **Legion** | Maquette Abdhaljs-Legion zones have monsters, no entry. |
| **Voidwatch** | No system; Voidwatch quests (VW_OP_*) unscripted. |
| **Geas Fete, Vagary, Delve, Skirmish, Wildskeeper Reives** | No system code (the [U] zones are only used by SoA missions). |
| **Meeble Burrows, Moblin Maze Mongers** | Enums / empty folder only. |
| **Pankration** | Helper tables only. |
| **Domain Invasion** | Only a fence helper in Escha Ru'Aun. |
| **Master Levels / Exemplar points** | Nothing. |
| **Ergon / Prime weapons** | Nothing playable. |
| **Assault** | 5 of about 50 missions scripted (Leujaoam Cleansing, Excavation Duty, Golden Salvage, Requiem, Seagull Grounded). |

Other gaps from the audit:
- **Battlefields:** 194 of 249 scripted. Besides the 23 Limbus areas: Unity/coalition fights (Clash of the Comrades,
  Heroine's Combat...), several old BCNMs and Ode of Life Bestowing / Mirror Mirror / Whom Wilt Thou Call, and more.
  Full list: run the audit with `--json`.
- **Missions:** Zilart "The Last Verse"; CoP 10 missing (Ancient Flames Beckon, A Transient Dream, Descendants of a
  Line Lost, Comedy of Errors Act I, Partners Without Fame, Spiral, Where Messengers Gather, Flames for the Dead,
  Emptiness Bleeds, The Last Verse); A Moogle Kupo d'Etat final; RoV above. San d'Oria / Bastok / Windurst / ToAU /
  WotG / ACP / ASA / SoA / TVR: every mission has a script.
- **Quests** (scripted by the quest framework / only in old NPC scripts / nothing):
  San d'Oria 59/19/4, Bastok 81/3/9, Windurst 51/35/4, Jeuno 64/34/47, Other Areas 45/12/10, Outlands 26/21/9,
  Aht Urhgan 52/2/18, Crystal War 47/9/39, Abyssea 71/0/121, Adoulin 15/27/55, Coalition 0/0/95.
  "Old NPC scripts" quests usually work but are often partial.
- **Monster skills:** 406 of 2,069 have no script (monsters that have them simply never use them).
- **Usable items:** 865 of 3,137 items flagged usable have no script (using them does nothing).

## 2. Coded, but incomplete or needs checking

| Content | State |
|---|---|
| **Besieged** | NPCs, Imperial Standing, mercenary ranks, core system in C++. Astral Candescence TODO. Invasions **(check in game)**. |
| **Campaign (WotG)** | Coded with ~40 TODOs (medals, freelance flags). **(check in game)** |
| **Ambuscade** | Tome menus are TODO stubs; one instance id hard-coded. Treat as not working. |
| **Abyssea** | Maws, confluxes, lights, Atma, NMs coded. Custom: cruor from kills, unlimited Visitant, 50% pop KIs (abyssea_rework.lua); the 70 ??? LSB left disabled in Vunkerl / Misareaux / Uleguerand and Myrmecoleon fixed (abyssea_pops.lua). Tuskertrap's pop item drops from nothing. Yellow / blue proc bonuses still a TODO. |
| **Escha Zi'Tah** | Entry works after RoV "Set Free". Escha Silt is "Not Implemented" in the Sparks shop, so many NM pops are hard to get. **(check in game)** |
| **Escha Ru'Aun / Reisenjima** | Zones populated, but the story gating needs RoV chapter 3. |
| **Nyzul Isle, Salvage, Einherjar** | Coded, with TODOs. **(check in game)** |
| **Mythic weapons** | Depends on Nyzul / Assault / Salvage; Assault is mostly missing, so the chain is blocked. |
| **ZNMs** | Coded (Soul plates, pops, Pandemonium Warden). |
| **Oboro (Port Jeuno)** | Custom (2026-09-28): Relic / Mythic / Empyrean weapons 99 -> 119 -> 119 III for stored Pluton / Riftborn Boulder / Beitetsu. |
| **Voidwalker NMs** | Works (`scripts/tests/systems/voidwalker.lua`): Clear Abyssite from Assai Nybaem (Ru'Lude Gardens, 1,000 gil), /heal to find and pop NMs in 25 field zones, abyssite upgrades on kills (1 in 10). |
| **Dynamis (current retail form)** | Entry (Trail Markings) and zones coded. |
| **Unity / Records of Eminence / Sparks** | Coded and in use; Sparks missing Escha Silt and Naakual items. |
| **Magian trials** | Coded; some TODOs on augment handling. |
| **Monstrosity** | Coded, switched off here (Eric). |
| **Mog Garden** | Only hides/shows NPCs; no garden features. Treat as not working. |
| **Chocobo Racing** | Coded but its settings are marked "not ready for release". |
| **Chocobo Raising** | Coded with TODOs ("validate this"). |
| **Synergy, Garrison, Fishing contest, Dark Ixion, Sandworm** | Coded (Dark Ixion's "only Stygian Ash damage" TODO). |

## 3. Our own known issues (from NOTES.md)

- **Trusts:** Morimar and Lilisette II have no unique moves (8 mob skills unscripted); Cid / Gilgamesh unique moves
  missing; the gambit `LOWEST` selector does nothing for spells; `PARTY_MULTI` is not implemented; no visible bubble
  around aura trusts (Cornelia, Sakura, ...). 12 story trusts are unobtainable because their quest / mission is not in
  LSB. Yoran-Oran sitting at 3000 TP without weaponskills: not looked at.
- **Jobs:** SMN Ward pact durations from gear not done; Wicce Chausses +3 "magic effect duration" (no -ja stacking
  window in LSB); THF Aura Steal's second-aura augment disabled upstream.
- **Armor Upgrader drops:** the Omen items / Paragon cards I put on Limbus NMs (Temenos / Apollyon, Omega / Ultima
  Forerunner) can never drop, because Limbus is not coded; the Sky / Sea / ZNM / Dynamis Lord sources do work.
  Should move to reachable monsters.
- **Old Artifact +1 materials** come from Limbus in retail; here they are only sold by the curio vendor with the Rhapsody
  in White key item (RoV 1-6, reachable).

## 4. Rough priority (suggestion)

1. Move the unreachable Limbus drops (quick, config only).
2. Ambuscade, Mog Garden: coded shells players will find and expect to work.
3. Assault (45 missions) and Limbus: big retail end-game pieces with zones and monsters already in the data.
4. RoV chapter 3: unlocks Escha Ru'Aun / Reisenjima properly.
5. Coalition assignments, Adoulin / Abyssea quests: large but repetitive.
6. Sortie / Odyssey / Omen / Divergence: very large; our custom content (hunts, Upgrader drops) stands in for now.
