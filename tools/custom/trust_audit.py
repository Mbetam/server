"""Audit every trust: can it be summoned, can players obtain it, and how much of its AI is scripted.

Usage: ~/lsb-venv/bin/python3 tools/custom/trust_audit.py [--json OUT.json]
Reads the DB (settings/network.lua) and scripts/. Changes nothing. Findings: docs/custom/NOTES.md (2026-09-22, Trust audit).
Rules it relies on (checked in the engine):
  - a trust loads only with a mob_pools row at poolid = spellid + 5000 and a matching mob_resistances row (trustutils.cpp);
  - weapon skills come from mob_skill_lists; ids <= 255 are player weapon skills, the rest mob skills; the engine uses
    them at random as soon as it has TP, even with no gambits;
  - spells and job abilities are ONLY used through gambits (addGambit in the trust's script): a caster with no
    gambits never casts, however long its spell list.
"""
import json
import os
import re
import sys

REPO = '/home/mbetam/server'
sys.path.insert(0, os.path.join(REPO, 'tools/custom'))
import migrate  # noqa: E402

JOBS = {1: 'WAR', 2: 'MNK', 3: 'WHM', 4: 'BLM', 5: 'RDM', 6: 'THF', 7: 'PLD', 8: 'DRK', 9: 'BST', 10: 'BRD', 11: 'RNG',
        12: 'SAM', 13: 'NIN', 14: 'DRG', 15: 'SMN', 16: 'BLU', 17: 'COR', 18: 'PUP', 19: 'DNC', 20: 'SCH', 21: 'GEO', 22: 'RUN'}
CASTER_JOBS = {3, 4, 5, 7, 8, 13, 15, 16, 20, 21, 22}  # jobs whose kit is mostly or partly spells

TRUST_DIR = os.path.join(REPO, 'scripts/actions/spells/trust')
MOBSKILL_DIR = os.path.join(REPO, 'scripts/actions/mobskills')
mobskill_files = {f[:-4] for f in os.listdir(MOBSKILL_DIR) if f.endswith('.lua')}
ws_files = {f[:-4] for f in os.listdir(os.path.join(REPO, 'scripts/actions/weaponskills')) if f.endswith('.lua')}

# spell id -> enum name, and every script line that grants a trust spell or hands out a cipher
enum = {}
for line in open(os.path.join(REPO, 'scripts/enum/magic.lua')):
    m = re.match(r'\s+([A-Z0-9_]+)\s*=\s*(\d+),', line)
    if m and 896 <= int(m.group(2)) <= 1023:
        enum[int(m.group(2))] = m.group(1)
item_const = {}
for line in open(os.path.join(REPO, 'scripts/enum/item.lua')):
    m = re.match(r'\s+([A-Z0-9_]+)\s*=\s*(\d+),', line)
    if m:
        item_const[int(m.group(2))] = m.group(1)
lua_files = {}
for root, _, files in os.walk(os.path.join(REPO, 'scripts')):
    if 'actions/spells/trust' in root or '/tests' in root or '/specs' in root or root.endswith('/enum'):
        continue
    for f in files:
        if f.endswith('.lua'):
            lua_files[os.path.relpath(os.path.join(root, f), REPO)] = open(os.path.join(root, f), errors='replace').read()
all_lua = '\n'.join(lua_files.values())
sql_text = '\n'.join(open(os.path.join(REPO, 'sql', f), errors='replace').read() for f in os.listdir(os.path.join(REPO, 'sql')) if f.endswith('.sql') and f != 'item_basic.sql')

rows = []
with migrate.MySQL() as db:
    spells = db.query("SELECT spellid, name FROM spell_list WHERE `group` = 8 ORDER BY spellid")
    for spellid, name in spells:
        spellid = int(spellid)
        r = {'id': spellid, 'name': name, 'problems': [], 'notes': []}
        pool = db.query(f"SELECT name, mJob, sJob, spellList, skill_list_id, resist_id, HEX(modelid) FROM mob_pools WHERE poolid = {spellid + 5000}")
        if not pool:
            r['problems'].append('no mob_pools row (poolid = id + 5000): cannot be summoned')
        else:
            pname, mjob, sjob, spell_list, skill_list, resist_id, model = pool[0]
            mjob, sjob, spell_list, skill_list = int(mjob), int(sjob), int(spell_list), int(skill_list)
            r['job'] = JOBS.get(mjob, str(mjob)) + ('/' + JOBS.get(sjob, str(sjob)) if sjob else '')
            if not db.query(f"SELECT 1 FROM mob_resistances WHERE resist_id = {resist_id}"):
                r['problems'].append(f'resist_id {resist_id} not in mob_resistances: cannot be summoned (the load query joins on it)')
            if set(model) <= {'0'}:
                r['problems'].append('no model')
            # spells
            n_spells = int(db.query(f"SELECT COUNT(*) FROM mob_spell_lists WHERE spell_list_id = {spell_list}")[0][0]) if spell_list else 0
            r['spells'] = n_spells
            if spell_list and n_spells == 0:
                r['problems'].append(f'spellList {spell_list} is empty')
            # weapon skills
            raw = db.query(f"SELECT l.mob_skill_id FROM mob_skill_lists l WHERE l.skill_list_id = {skill_list}") if skill_list else []
            skills = []
            for (sid,) in raw:
                sid = int(sid)
                if sid <= 255:  # player weapon skill (trustutils.cpp)
                    n = db.query(f"SELECT name FROM weapon_skills WHERE weaponskillid = {sid}")
                    n = n[0][0] if n else None
                    skills.append((sid, n, 'ws'))
                else:
                    n = db.query(f"SELECT mob_skill_name FROM mob_skills WHERE mob_skill_id = {sid}")
                    n = n[0][0] if n else None
                    skills.append((sid, n, 'mob'))
            r['ws'] = len(skills)
            if skill_list == 0 or not skills:
                r['problems'].append('no weapon skills (skill_list_id %s empty)' % skill_list)
            missing_row = [s for s, n, k in skills if n in (None, 'NULL')]
            missing_script = [n for s, n, k in skills if n not in (None, 'NULL') and n not in (mobskill_files if k == 'mob' else ws_files)]
            if missing_row:
                r['problems'].append(f'skill list references mob_skill ids with no mob_skills row: {missing_row}')
            if missing_script:
                r['problems'].append(f'weapon skills with no script (never usable): {missing_script}')
            r['ws_names'] = [n for s, n, k in skills]
            r['_caster'] = mjob in CASTER_JOBS or sjob in CASTER_JOBS
            r['_spell_list'] = spell_list

        # how to obtain it
        e = enum.get(spellid)
        r['quest_grant'] = bool(e and re.search(r'addSpell\(\s*xi\.magic\.spell\.' + e + r'\b', all_lua))
        cipher = db.query(f"SELECT itemid, name FROM item_basic WHERE itemid BETWEEN 10112 AND 10193 AND subid = {spellid}")
        r['cipher'] = cipher[0][1] if cipher else None
        r['cipher_from'] = []
        if cipher:
            iid = int(cipher[0][0])
            const = item_const.get(iid)
            if const:
                r['cipher_from'] = sorted(f for f, t in lua_files.items() if re.search(r'xi\.item\.' + const + r'\b', t))
            if db.query(f"SELECT 1 FROM mob_droplist WHERE itemId = {iid} LIMIT 1"):
                r['cipher_from'].append('mob_droplist')
            r['cipher_source'] = bool(r['cipher_from'])
        else:
            r['cipher_source'] = False
        r['grant_from'] = sorted(f for f, t in lua_files.items() if e and re.search(r'addSpell\(\s*xi\.magic\.spell\.' + e + r'\b', t))
        if not r['quest_grant'] and not r['cipher_source']:
            r['problems'].append('no way to obtain: no quest grants it and nothing hands out its cipher' + ('' if cipher else ' (no cipher item)'))

        # script
        path = os.path.join(TRUST_DIR, name + '.lua')
        if not os.path.isfile(path):
            r['problems'].append(f'no script {name}.lua')
            rows.append(r)
            continue
        src = open(path).read()
        code = '\n'.join(l for l in src.splitlines() if not l.strip().startswith('--'))
        r['gambits'] = len(re.findall(r'addGambit\(', code))
        r['uses_MA'] = bool(re.search(r'ai\.r\.MA\b', code))
        r['uses_WS'] = bool(re.search(r'ai\.r\.WS\b|tp_select|setTrustTPSkillSettings|ai\.r\.MS\b', code))
        comments = [l.strip() for l in src.splitlines() if re.search(r'TODO|FIXME|not implemented|unimplemented|NYI|placeholder|missing|verify|capture', l, re.I)]
        r['todo'] = comments
        if r['gambits'] == 0:
            r['notes'].append('no gambits: only auto-attacks (and weapon skills if the engine picks them)')
        if r.get('_caster') and r.get('_spell_list') == 0 and r['uses_MA']:
            r['problems'].append('script casts spells (ai.r.MA) but mob_pools.spellList = 0')
        if r['uses_MA'] and r.get('spells', 0) == 0 and r.get('_spell_list', 0) == 0:
            pass
        rows.append(r)

if '--json' in sys.argv:
    json.dump(rows, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)

MELEE = {'WAR','MNK','THF','PLD','DRK','BST','RNG','SAM','NIN','DRG','COR','PUP','DNC','RUN','BLU'}
MAGE = {'WHM','BLM','RDM','SMN','SCH','GEO','BRD'}
cats = {k: [] for k in ['cannot_summon','caster_never_casts','bare_autoattack','melee_ws_no_ai','melee_no_ws','partial_todo','working']}
for r in rows:
    main = (r.get('job') or '?').split('/')[0]
    label = f"{r['name']} ({r.get('job','?')})"
    if any('cannot be summoned' in p for p in r['problems']):
        cats['cannot_summon'].append(label); continue
    g = r.get('gambits', 0)
    if g == 0 and r.get('spells', 0) > 0 and main in MAGE | {'PLD','DRK','RUN','NIN','BLU','GEO'} and main not in MELEE - {'PLD','DRK','RUN','NIN','BLU'} :
        cats['caster_never_casts'].append(label + f" {r['spells']} spells")
    elif g == 0 and r.get('ws', 0) == 0:
        cats['bare_autoattack'].append(label)
    elif g == 0:
        cats['melee_ws_no_ai'].append(label + f" {r['ws']} WS")
    elif main in MELEE and r.get('ws', 0) == 0:
        cats['melee_no_ws'].append(label)
    elif [t for t in r.get('todo', []) if 'TODO' in t]:
        cats['partial_todo'].append(label)
    else:
        cats['working'].append(label)
    if g == 0 and r.get('spells', 0) > 0 and label not in ' '.join(cats['caster_never_casts']):
        r['notes'].append(f"has {r['spells']} spells but no gambits: never casts")

for k, v in cats.items():
    print(f"\n== {k}: {len(v)}")
    print('   ' + ', '.join(v))
# How players get each trust. Event-only sources are switched off here (Festive Moogle needs Mog Pells, which
# almost nothing hands out; Extravaganza and login campaigns are disabled in settings/main.lua).
EVENT = {'festive_moogle.lua', 'extravaganza.lua', 'login_campaign_data.lua', 'mog_bonanza.lua'}
acq = {'normal': [], 'event_only': [], 'none': []}
for r in rows:
    srcs = {f.split('/')[-1] for f in r['cipher_from'] + r['grant_from']}
    acq['normal' if srcs - EVENT else 'event_only' if srcs else 'none'].append(r['name'])
for k, v in acq.items():
    print(f"\n== obtainable, {k}: {len(v)}")
    print('   ' + ', '.join(v))
ws_missing = [(r['name'], p) for r in rows for p in r['problems'] if 'no script' in p and 'weapon' in p or 'mob_skills row' in p]
print('\n== weapon-skill data problems:', ws_missing or 'none')
