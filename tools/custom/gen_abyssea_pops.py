#!/usr/bin/env python3
"""Generate modules/custom/lua/abyssea_pops_data.lua: retail pop requirements for the Abyssea ??? whose scripts LSB
left commented out (Vunkerl, Misareaux, Uleguerand).

Usage: ~/lsb-venv/bin/python3 tools/custom/gen_abyssea_pops.py [--cache DIR]
Reads the BG Wiki zone pages (NM table "Spawn_Condition"), Windower item names (name -> id), scripts/zones/<zone>/npcs/
qm*.lua (the "Spawns <NM>" comment), data/zones/<zone>/{npcs,mobs}.yaml (positions; each ??? pops the nearest spawn of
its NM), scripts/enum/key_item.codegen.lua and the DB. Prints any pop item / key item nobody drops. Diff the result.
Background: docs/custom/NOTES.md (JSE weapon progression, Abyssea pops).
"""

import argparse
import json
import math
import os
import re
import sys
import urllib.parse
import urllib.request

import yaml

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools', 'custom'))
import migrate  # noqa: E402

ZONES = {  # script dir, data dir, BG page, zone enum
    'Abyssea-Vunkerl':    ('abyssea_vunkerl',    'Abyssea - Vunkerl',    'ABYSSEA_VUNKERL'),
    'Abyssea-Misareaux':  ('abyssea_misareaux',  'Abyssea - Misareaux',  'ABYSSEA_MISAREAUX'),
    'Abyssea-Uleguerand': ('abyssea_uleguerand', 'Abyssea - Uleguerand', 'ABYSSEA_ULEGUERAND'),
}
AGENT = {'User-Agent': 'Mozilla/5.0 (LSB private server abyssea pops)'}
ITEMS_URL = 'https://raw.githubusercontent.com/Windower/Resources/master/resources_data/items.lua'


def norm(s):
    return re.sub(r'[^a-z0-9]', '', s.lower().replace('high-quality', 'hq'))


def cached(path, fetch):
    if not os.path.exists(path):
        data = fetch()
        with open(path, 'w', encoding='utf-8') as f:
            f.write(data)
    return open(path, encoding='utf-8').read()


def fetch_pages():
    q = urllib.parse.urlencode({'action': 'query', 'prop': 'revisions', 'rvprop': 'content', 'rvslots': 'main',
                                'format': 'json', 'redirects': '1', 'titles': '|'.join(z[1] for z in ZONES.values())})
    d = json.load(urllib.request.urlopen(urllib.request.Request('https://www.bg-wiki.com/api.php?' + q, headers=AGENT), timeout=60))
    return json.dumps({p['title']: p['revisions'][0]['slots']['main']['*'] for p in d['query']['pages'].values()})


parser = argparse.ArgumentParser()
parser.add_argument('--cache', default=os.path.join(REPO, 'build', 'abyssea_pops_cache'))
args = parser.parse_args()
os.makedirs(args.cache, exist_ok=True)
pages = json.loads(cached(os.path.join(args.cache, 'pages.json'), fetch_pages))
itemsLua = cached(os.path.join(args.cache, 'items.lua'), lambda: urllib.request.urlopen(urllib.request.Request(ITEMS_URL, headers=AGENT), timeout=60).read().decode('utf-8'))

# BG: NM -> ('trade' | 'ki', [names])
bg = {}
for zoneDir, (_, page, _) in ZONES.items():
    for row in pages[page].split('{{Zone NM Row 2')[1:]:
        name = re.search(r'\|NM\.Name=([^\n|]*)', row).group(1).strip()
        cond = (re.search(r'\|NM\.Spawn_Condition=([^\n]*)', row) or [None, ''])[1]
        things = re.findall(r'\[\[([^\]|]+)', cond)
        kind = 'ki' if ('Examine' in cond or '{{KI}}' in cond) else ('trade' if 'Trade' in cond else None)
        if kind:
            bg[(zoneDir, norm(name))] = (kind, things)

# names -> ids
itemIds = {}
for m in re.finditer(r'\[(\d+)\] = \{id=\d+,en="((?:[^"\\]|\\.)*)",ja="[^"]*",enl="((?:[^"\\]|\\.)*)"', itemsLua):
    i = int(m.group(1))
    for n in (m.group(2), m.group(3), re.sub(r'^(?:a|an|the|(?:\w+ )?\w+ of) ', '', m.group(3))):
        itemIds.setdefault(norm(n), i)
kiEnum = {norm(k): k for k, _ in re.findall(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', open(os.path.join(REPO, 'scripts/enum/key_item.codegen.lua')).read(), re.M)}
zoneEnum = dict(re.findall(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', open(os.path.join(REPO, 'scripts/enum/zone.codegen.lua')).read(), re.M))

with migrate.MySQL() as db:
    dbNames = {int(a): b for a, b in db.query('SELECT itemid, name FROM item_basic')}

# who drops what (YAML loot, all zones)
drops = {}
for zd in os.listdir(os.path.join(REPO, 'data/zones')):
    p = os.path.join(REPO, 'data/zones', zd, 'mobs.yaml')
    if not os.path.exists(p):
        continue
    txt = re.sub(r'one_of:\s*\[([^\]]*)\]', lambda m: '\n'.join('item: ' + x.strip() for x in m.group(1).split(',')), open(p).read())
    for it in re.findall(r'item:\s+(\S+)', txt):
        drops.setdefault(it, set()).add(zd)
kiDropped = set(re.findall(r'xi\.keyItem\.(\w+)', open(os.path.join(REPO, 'scripts/globals/abyssea.lua')).read()))

out, problems = {}, []
for zoneDir, (dataDir, page, enumName) in ZONES.items():
    npcs = yaml.safe_load(open(os.path.join(REPO, 'data/zones', dataDir, 'npcs.yaml')))
    npcs = npcs.get('npcs') or npcs.get('spawns') or {}
    qmPos = {v.get('script'): v.get('at') for v in npcs.values() if str(v.get('script', '')).startswith('qm')}
    mobs = yaml.safe_load(open(os.path.join(REPO, 'data/zones', dataDir, 'mobs.yaml')))
    spawns = mobs['spawns']
    used = set()
    for f in sorted(os.listdir(os.path.join(REPO, 'scripts/zones', zoneDir, 'npcs'))):
        if not re.match(r'qm\d+\.lua$', f):
            continue
        txt = open(os.path.join(REPO, 'scripts/zones', zoneDir, 'npcs', f)).read()
        m = re.search(r'Spawns\s+([^\n]+)', txt)
        if not m:
            continue
        nm = m.group(1).strip().replace('Pulverizor', 'Pulverizer').replace('Funeral Apkallu', 'Funereal Apkallu')
        req = bg.get((zoneDir, norm(nm)))
        if req is None:
            problems.append(f'{zoneDir}/{f}: {nm}: no BG spawn condition')
            continue
        template = [k for k in {s.get('template') for s in spawns.values()} if k and norm(k) == norm(nm)]
        if not template:
            problems.append(f'{zoneDir}/{f}: {nm}: no monster data')
            continue
        pos = qmPos.get(f[:-4])
        cands = [(int(k), s) for k, s in spawns.items() if s.get('template') == template[0] and s.get('at') and int(k) not in used]  # no position: never loaded
        if pos and cands and all(s.get('at') for _, s in cands):
            mobId = min(cands, key=lambda c: math.dist(c[1]['at'][:3], pos[:3]))[0]
        else:
            mobId = min(c[0] for c in cands) if cands else None
        if mobId is None:
            problems.append(f'{zoneDir}/{f}: {nm}: every spawn already taken')
            continue
        used.add(mobId)
        kind, names = req
        entry = {'mob': mobId, 'nm': template[0], 'kind': kind}
        if kind == 'trade':
            ids = []
            for n in names:
                i = itemIds.get(norm(n))
                if i is None:
                    problems.append(f'{zoneDir}/{f}: {nm}: item "{n}" not found')
                    continue
                ids.append(i)
                if dbNames.get(i) not in drops:
                    problems.append(f'{zoneDir}/{f}: {nm}: nothing drops {dbNames.get(i)}')
            entry['items'] = ids
        else:
            kis = []
            for n in names:
                k = kiEnum.get(norm(n))
                if k is None:
                    problems.append(f'{zoneDir}/{f}: {nm}: key item "{n}" not found')
                    continue
                kis.append(k)
                if k not in kiDropped:
                    problems.append(f'{zoneDir}/{f}: {nm}: no NM drops key item {k}')
            entry['kis'] = kis
        out.setdefault((zoneDir, enumName), {})[f[:-4]] = entry

lines = ['-----------------------------------',
         '-- Abyssea pops LSB left commented out (Vunkerl, Misareaux, Uleguerand): retail requirements. Not a module.',
         '-- GENERATED by tools/custom/gen_abyssea_pops.py (BG Wiki zone NM tables). Do not edit by hand: rerun and diff.',
         '-- [zone] = { [??? script name] = { mob = id (nearest spawn of its NM), items = { trade } or kis = { key items } } }',
         '-----------------------------------',
         'local data =',
         '{']
for (zoneDir, enumName), qms in sorted(out.items()):
    lines.append(f'    [xi.zone.{enumName}] =')
    lines.append('    {')
    for qm, e in sorted(qms.items(), key=lambda kv: int(kv[0][2:])):
        if e['kind'] == 'trade':
            req = 'items = { ' + ', '.join(str(i) for i in e['items']) + ' }'
            note = ', '.join(dbNames.get(i, '?') for i in e['items'])
        else:
            req = 'kis = { ' + ', '.join('xi.keyItem.' + k for k in e['kis']) + ' }'
            note = 'key items'
        lines.append(f"        {qm:5} = {{ mob = {e['mob']}, {req} }}, -- {e['nm']}: {note}")
    lines.append('    },')
lines += ['}', '', 'return data', '']
open(os.path.join(REPO, 'modules/custom/lua/abyssea_pops_data.lua'), 'w').write('\n'.join(lines))
print(sum(len(v) for v in out.values()), '??? written')
for p in problems:
    print('  PROBLEM', p)
