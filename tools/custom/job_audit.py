#!/usr/bin/env python3
"""Audit every job: which job abilities, spells, weapon skills and traits exist in the DB, and whether the script the
engine runs for each one exists and does something.

Usage: ~/lsb-venv/bin/python3 tools/custom/job_audit.py [--json OUT.json] [--job WAR]
Reads the DB (settings/network.lua) and scripts/. Changes nothing. Findings: docs/custom/NOTES.md (job audit).

Where the engine looks (src/map/lua/luautils.cpp, src/map/spell.cpp):
  job ability        scripts/actions/abilities/<abilities.name>.lua           (pet abilities: .../abilities/pets/<name>.lua)
  spell              scripts/actions/spells/<group dir>/<spell_list.name>.lua (group: spell_list.group)
  weapon skill       scripts/actions/weaponskills/<weapon_skills.name>.lua
  job trait          traits rows: a modifier + value, applied by the engine (no script)
A static check: "has a script that is not empty and has no TODO" is not proof that it works as in retail.
"""

import json
import os
import re
import sys

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools', 'custom'))
import migrate  # noqa: E402

JOBS = ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN',
        'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN']
GROUP_DIR = {1: 'songs', 2: 'black', 3: 'blue', 4: 'ninjutsu', 5: 'summoning', 6: 'white', 7: 'geomancy'}
ACTIONS = os.path.join(REPO, 'scripts', 'actions')
TODO_RE = re.compile(r'TODO|FIXME|not implemented|unimplemented|NYI|placeholder', re.I)

# abilities rows that are client menu headers (Phantom Roll, Steps, Blood Pact: Rage, ...), not usable abilities:
# they need no script
MENU_HEADERS = {'pet_commands', 'ready', 'blood_pact_rage', 'blood_pact_ward', 'phantom_roll', 'quick_draw', 'sambas',
                'waltzes', 'steps', 'flourishes_i', 'flourishes_ii', 'flourishes_iii', 'jigs', 'stratagems', 'ward',
                'effusion', 'rune_enchantment'}
# Scripts that are empty on purpose: the engine does the work from the abilities row (Provoke's enmity)
EMPTY_ON_PURPOSE = {'provoke'}


def blob_levels(hexstr):
    """spell_list.jobs / weapon_skills.jobs: one byte per job (WAR first), queried as HEX() so tabs and newlines in
    the binary data cannot break the row parsing."""
    return list(bytes.fromhex(hexstr)) if hexstr and hexstr != 'NULL' else []


def code_of(path):
    src = open(path, errors='replace').read()
    code = '\n'.join(l for l in src.splitlines() if not l.strip().startswith('--'))
    return src, code


def script_state(path, main_fn):
    """'missing', 'empty' (main function has no body), 'todo' (works but has TODO/NYI notes) or 'ok'."""
    if not os.path.isfile(path):
        return 'missing', []
    src, code = code_of(path)
    todos = [l.strip()[:140] for l in src.splitlines() if TODO_RE.search(l)]
    m = re.search(r'%s\s*=\s*function\s*\([^)]*\)(.*?)\nend\b' % re.escape(main_fn), code, re.S)
    if m and not re.sub(r'\s|return\s*(0|nil|false)?', '', m.group(1)):
        return 'empty', todos
    if m is None and main_fn not in code:
        return 'empty', todos
    return ('todo' if todos else 'ok'), todos


def main():
    only = sys.argv[sys.argv.index('--job') + 1].upper() if '--job' in sys.argv else None
    report = {}

    with migrate.MySQL() as db:
        abilities = db.query("SELECT abilityId, name, job, level FROM abilities ORDER BY job, level, abilityId")
        spells = db.query("SELECT spellid, name, HEX(jobs), `group` FROM spell_list")
        wskills = db.query("SELECT weaponskillid, name, HEX(jobs) FROM weapon_skills")
        traits = db.query("SELECT traitid, name, job, level, modifier FROM traits")
        blue = {int(r[0]): int(r[1]) for r in db.query("SELECT spellid, mob_skill_id FROM blue_spell_list")}
        mobskill_names = {int(r[0]): r[1] for r in db.query("SELECT mob_skill_id, mob_skill_name FROM mob_skills")}

    for j, abbr in enumerate(JOBS, start=1):
        if only and abbr != only:
            continue
        r = {'abilities': [], 'pet_abilities': [], 'spells': [], 'weaponskills': [], 'traits': 0, 'problems': []}

        # Job abilities (and the pet abilities the job's pets use: Blood Pacts, Ready moves, Wyvern breaths...)
        for aid, name, job, level in abilities:
            if int(job) != j or name in MENU_HEADERS:
                continue
            aid, level = int(aid), int(level)
            is_pet = aid >= 512 or os.path.isfile(os.path.join(ACTIONS, 'abilities', 'pets', name + '.lua')) and \
                not os.path.isfile(os.path.join(ACTIONS, 'abilities', name + '.lua'))
            path = os.path.join(ACTIONS, 'abilities', 'pets' if is_pet else '', name + '.lua')
            state, todos = script_state(path, 'onUseAbility' if not is_pet else 'onPetAbility')
            if state == 'empty' and is_pet:  # many pet ability scripts only hand off to a mob skill
                state, todos = script_state(path, 'onUseAbility')
            if state == 'empty' and name in EMPTY_ON_PURPOSE:
                state = 'ok'
            (r['pet_abilities'] if is_pet else r['abilities']).append(
                {'id': aid, 'name': name, 'level': level, 'state': state, 'todo': todos})

        # Spells the job can learn (level 1-99 in its byte of spell_list.jobs)
        for sid, name, jobs, group in spells:
            lv = blob_levels(jobs)
            if len(lv) < j or not (1 <= lv[j - 1] <= 99) or int(group) not in GROUP_DIR:
                continue
            path = os.path.join(ACTIONS, 'spells', GROUP_DIR[int(group)], name + '.lua')
            state, todos = script_state(path, 'onSpellCast')
            entry = {'id': int(sid), 'name': name, 'level': lv[j - 1], 'state': state, 'todo': todos}
            if int(group) == 3:  # Blue Magic runs the monster's own skill
                ms = blue.get(int(sid))
                if ms is None:
                    entry['state'], entry['why'] = 'broken', 'no blue_spell_list row'
                elif not os.path.isfile(os.path.join(ACTIONS, 'mobskills', (mobskill_names.get(ms) or '') + '.lua')):
                    entry['note'] = f'mob skill {ms} ({mobskill_names.get(ms)}) has no mobskill script (the spell script may not need it)'
            r['spells'].append(entry)

        # Weapon skills the job can use
        for wid, name, jobs in wskills:
            lv = blob_levels(jobs)
            if len(lv) < j or lv[j - 1] == 0:
                continue
            state, todos = script_state(os.path.join(ACTIONS, 'weaponskills', name + '.lua'), 'onUseWeaponSkill')
            r['weaponskills'].append({'id': int(wid), 'name': name, 'state': state, 'todo': todos})

        r['traits'] = sum(1 for t in traits if int(t[2]) == j)

        # Job-wide notes in scripts/globals/job_utils/<job>.lua
        ju = [f for f in os.listdir(os.path.join(REPO, 'scripts', 'globals', 'job_utils'))]
        name_map = {'WAR': 'warrior', 'MNK': 'monk', 'WHM': 'white_mage', 'BLM': 'black_mage', 'RDM': 'red_mage',
                    'THF': 'thief', 'PLD': 'paladin', 'DRK': 'dark_knight', 'BST': 'beastmaster', 'BRD': 'bard',
                    'RNG': 'ranger', 'SAM': 'samurai', 'NIN': 'ninja', 'DRG': 'dragoon', 'SMN': 'summoner',
                    'BLU': 'blue_mage', 'COR': 'corsair', 'PUP': 'puppetmaster', 'DNC': 'dancer', 'SCH': 'scholar',
                    'GEO': 'geomancer', 'RUN': 'rune_fencer'}
        f = name_map[abbr] + '.lua'
        r['job_utils_todo'] = []
        if f in ju:
            src, _ = code_of(os.path.join(REPO, 'scripts', 'globals', 'job_utils', f))
            r['job_utils_todo'] = [l.strip()[:140] for l in src.splitlines() if TODO_RE.search(l)]
        r['tests'] = os.path.isdir(os.path.join(REPO, 'scripts', 'tests', 'jobs', abbr.lower()))

        for kind in ('abilities', 'pet_abilities', 'spells', 'weaponskills'):
            for e in r[kind]:
                if e['state'] in ('missing', 'empty', 'broken'):
                    r['problems'].append(f"{kind[:-1] if kind != 'abilities' else 'ability'} {e['name']} (lv{e.get('level', '-')}): {e['state']}" + (f" ({e['why']})" if e.get('why') else ''))
        report[abbr] = r

    if '--json' in sys.argv:
        json.dump(report, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)

    for abbr, r in report.items():
        count = lambda k, s: sum(1 for e in r[k] if e['state'] == s)  # noqa: E731
        line = []
        for k, label in (('abilities', 'JA'), ('pet_abilities', 'pet'), ('spells', 'spells'), ('weaponskills', 'WS')):
            n = len(r[k])
            if n:
                bad = count(k, 'missing') + count(k, 'empty') + count(k, 'broken')
                line.append(f"{label} {n - bad}/{n}" + (f" (TODO in {count(k, 'todo')})" if count(k, 'todo') else ''))
        print(f"{abbr}: " + ', '.join(line) + f", traits {r['traits']}, job_utils TODOs {len(r['job_utils_todo'])}, tests {'yes' if r['tests'] else 'no'}")
        for p in r['problems']:
            print('     ' + p)


if __name__ == '__main__':
    main()
