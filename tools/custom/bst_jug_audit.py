#!/usr/bin/env python3
"""Audit every Beastmaster jug pet: can it be called, and do its Ready moves work.

Usage: ~/lsb-venv/bin/python3 tools/custom/bst_jug_audit.py [--json OUT.json]
Reads the DB (settings/network.lua) and scripts/. Changes nothing. Findings: docs/custom/NOTES.md (BST audit).

The chain the engine uses (scripts/globals/job_utils/beastmaster.lua, src/map/utils/charutils.cpp):
  jug item (ammo slot, item_weapon.skill = 0) -> item_weapon.subskill = petid -> pet_list -> mob_pools (poolid)
  -> mob_pools.skill_list_id -> mob_skill_lists rows that hold ABILITY ids (the Ready menu shows abilityId - 496)
  -> abilities row -> scripts/actions/abilities/pets/<ability name>.lua -> it calls
     xi.actions.mobskills[skillName].onMobWeaponSkill, i.e. scripts/actions/mobskills/<skillName>.lua
A Ready move works only if every link exists.
"""

import json
import os
import re
import sys

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools', 'custom'))
import migrate  # noqa: E402

PET_ABILITY_DIR = os.path.join(REPO, 'scripts', 'actions', 'abilities', 'pets')
MOBSKILL_DIR = os.path.join(REPO, 'scripts', 'actions', 'mobskills')
BST = 9

# Pets that have no Ready moves in retail (confirmed by Eric in game, 2026-09-23): an empty list is correct for them.
NO_READY_MOVES_IN_RETAIL = {'SlipperySilas', 'BraveHeroGlenn'}


def skill_name_in(path):
    """The mob skill a pet ability script hands off to (its local skillName), or None."""
    src = open(path, errors='replace').read()
    m = re.search(r"local\s+skillName\s*=\s*'([^']+)'", src)
    if m:
        return m.group(1)
    m = re.search(r"xi\.actions\.mobskills\[['\"]([^'\"]+)['\"]\]", src)
    return m.group(1) if m else None


def main():
    rows = []
    with migrate.MySQL() as db:
        jugs = db.query("""
            SELECT w.itemId, b.name, e.level, w.subskill
            FROM item_weapon w
            JOIN item_basic b ON b.itemid = w.itemId
            LEFT JOIN item_equipment e ON e.itemId = w.itemId
            WHERE w.skill = 0 AND w.subskill >= 21
            ORDER BY e.level, b.name""")
        for itemid, iname, level, petid in jugs:
            r = {'item': iname, 'itemid': int(itemid), 'level': int(level) if level not in (None, 'NULL') else None,
                 'petid': int(petid), 'problems': [], 'moves': []}
            pet = db.query(f"SELECT name, poolid, minLevel, maxLevel, time FROM pet_list WHERE petid = {petid}")
            if not pet:
                r['problems'].append('no pet_list row: Call Beast does nothing')
                rows.append(r)
                continue
            pname, pool, pmin, pmax, ptime = pet[0]
            r.update(pet=pname, minLevel=int(pmin), maxLevel=int(pmax), duration_min=int(ptime) // 60)
            if r['level'] is None:
                r['problems'].append('jug has no item_equipment row (no level): Call Beast refuses it')
            poolrow = db.query(f"SELECT skill_list_id FROM mob_pools WHERE poolid = {pool}")
            if not poolrow:
                r['problems'].append(f'mob_pools {pool} missing: the pet cannot spawn')
                rows.append(r)
                continue
            sl = int(poolrow[0][0])
            ids = [int(x[0]) for x in db.query(f"SELECT mob_skill_id FROM mob_skill_lists WHERE skill_list_id = {sl}")] if sl else []
            if not ids and pname not in NO_READY_MOVES_IN_RETAIL:
                r['problems'].append('no Ready moves (empty skill list)')
            for aid in ids:
                move = {'id': aid, 'ok': False}
                ab = db.query(f"SELECT name, job, level FROM abilities WHERE abilityId = {aid}")
                if not ab:
                    move['why'] = f'ability {aid} not in abilities table'
                else:
                    aname, ajob, alevel = ab[0]
                    move.update(name=aname, level=int(alevel))
                    script = os.path.join(PET_ABILITY_DIR, aname + '.lua')
                    if int(ajob) != BST:
                        move['why'] = f'ability job is {ajob}, not BST'
                    elif not os.path.isfile(script):
                        move['why'] = 'no pet ability script'
                    elif re.search(r'TODO implement this ability', open(script, errors='replace').read()):
                        move['why'] = 'placeholder script (always refuses: TODO implement this ability)'
                    else:
                        skill = skill_name_in(script)
                        move['mobskill'] = skill
                        if not skill:
                            move['why'] = 'pet ability script does not name a mob skill (custom logic, check by hand)'
                            move['ok'] = True  # a self-contained script can still work
                        elif not os.path.isfile(os.path.join(MOBSKILL_DIR, skill + '.lua')):
                            move['why'] = f'mob skill script {skill}.lua missing'
                        else:
                            move['ok'] = True
                r['moves'].append(move)
            broken = [m for m in r['moves'] if not m['ok']]
            if broken:
                r['problems'].append('broken Ready moves: ' + ', '.join(f"{m.get('name', m['id'])} ({m['why']})" for m in broken))
            rows.append(r)

        pets_without_jug = db.query("""
            SELECT p.petid, p.name FROM pet_list p
            WHERE p.petid >= 21 AND p.petid NOT IN (SELECT subskill FROM item_weapon WHERE skill = 0 AND subskill >= 21)""")

    if '--json' in sys.argv:
        json.dump(rows, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)

    ok = [r for r in rows if not r['problems']]
    print(f"{len(rows)} jugs: {len(ok)} fully working, {len(rows) - len(ok)} with problems")
    for r in rows:
        moves = ', '.join((m.get('name') or str(m['id'])) + ('' if m['ok'] else ' [BROKEN]') for m in r['moves'])
        status = 'OK ' if not r['problems'] else 'BAD'
        print(f"{status} lv{r['level']} {r['item']} -> {r.get('pet', '?')} ({r.get('duration_min', '?')} min, pet lv {r.get('minLevel', '?')}-{r.get('maxLevel', '?')}): {moves}")
        for p in r['problems']:
            print(f"      {p}")
    print(f"\npet_list entries (21+) with no jug item: {len(pets_without_jug)}")
    print('   ' + ', '.join(f'{n} ({i})' for i, n in pets_without_jug))


if __name__ == '__main__':
    main()
