#!/usr/bin/env python3
"""Generate modules/custom/lua/af_upgrade_materials.lua: the retail materials of every Armor Upgrader step.

Usage: ~/lsb-venv/bin/python3 tools/custom/gen_upgrade_materials.py [--cache DIR]
Downloads the BG Wiki tier category pages (Artifact / Relic / Empyrean +1 and +2, Reforged 109 to +3) and Windower's
item names (resources_data/items.lua, to turn the wiki's names into item ids), reads Sagheera's own table for old
Artifact +1, the chains in af_upgrade_config.lua and item names from the DB (settings/network.lua), then rewrites the
Lua file. Diff the result before committing. Background: docs/custom/NOTES.md (Armor Upgrader: retail materials).

Some amounts live in BG sub-templates, not on the pages; they are written out below (AF109, AF119, CARD2, CARD3, DAY2,
R1JOB, R2JOB, RSLOT, SHARD, VOID, R3SLOT, STONE).
"""

import argparse
import collections
import json
import os
import re
import sys
import urllib.parse
import urllib.request

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools', 'custom'))
import migrate  # noqa: E402

TIER_PAGES = ['Relic Armor +1', 'Relic Armor +2', 'Empyrean Armor +1', 'Empyrean Armor +2', 'Reforged Artifact Armor',
              'Reforged Artifact Armor +1', 'Reforged Artifact Armor +2', 'Reforged Artifact Armor +3', 'Reforged Relic Armor',
              'Reforged Empyrean Armor', 'Reforged Empyrean Armor +1', 'Reforged Empyrean Armor +2', 'Reforged Empyrean Armor +3']
ITEMS_URL = 'https://raw.githubusercontent.com/Windower/Resources/master/resources_data/items.lua'
AGENT = {'User-Agent': 'Mozilla/5.0 (LSB private server upgrade materials)'}


def fetch(url, path):
    if not os.path.exists(path):
        with urllib.request.urlopen(urllib.request.Request(url, headers=AGENT), timeout=60) as response:
            data = response.read()
        with open(path, 'wb') as out:
            out.write(data)
    return open(path, encoding='utf-8').read()


def fetch_pages(cache):
    path = os.path.join(cache, 'upgrade_tiers.json')
    if not os.path.exists(path):
        titles = ['Category:' + t for t in TIER_PAGES]
        pages = {}
        for k in range(0, len(titles), 20):
            q = urllib.parse.urlencode({'action': 'query', 'prop': 'revisions', 'rvprop': 'content', 'rvslots': 'main',
                                        'format': 'json', 'redirects': '1', 'titles': '|'.join(titles[k:k + 20])})
            req = urllib.request.Request('https://www.bg-wiki.com/api.php?' + q, headers=AGENT)
            data = json.load(urllib.request.urlopen(req, timeout=60))
            for page in data['query']['pages'].values():
                pages[page['title']] = page['revisions'][0]['slots']['main']['*'] if 'revisions' in page else ''
        json.dump(pages, open(path, 'w'))
    return {k: (v or '').replace('\n||', '\n|') for k, v in json.load(open(path)).items()}


parser = argparse.ArgumentParser()
parser.add_argument('--cache', default=os.path.join(REPO, 'build', 'upgrade_materials_cache'))
args = parser.parse_args()
os.makedirs(args.cache, exist_ok=True)
pages = fetch_pages(args.cache)
items_lua = fetch(ITEMS_URL, os.path.join(args.cache, 'items.lua'))
R = REPO

# ---------- item names -> ids (Windower resources)
en, enl = {}, {}
for m in re.finditer(r'\[(\d+)\] = \{id=\d+,en="((?:[^"\\]|\\.)*)",ja="[^"]*",enl="((?:[^"\\]|\\.)*)"', items_lua):
    i = int(m.group(1))
    en.setdefault(m.group(2).lower(), i)
    l = m.group(3).lower()
    enl.setdefault(l, i)
    l2 = re.sub(r'^(?:a|an|the|(?:\w+ )?(?:\w+) of) ', '', l)
    enl.setdefault(l2, i)

def norm(s):
    return re.sub(r'[^a-z0-9+]', '', s.lower())
ennorm, enlnorm = {}, {}
for k, v in en.items(): ennorm.setdefault(norm(k), v)
for k, v in enl.items(): enlnorm.setdefault(norm(k), v)

OVERRIDE = {
    "rem's tale ch.1": 4064, "rem's tale ch.2": 4065, "rem's tale ch.3": 4066, "rem's tale ch.4": 4067, "rem's tale ch.5": 4068,
    "rem's tale ch.6": 4069, "rem's tale ch.7": 4070, "rem's tale ch.8": 4071, "rem's tale ch.9": 4072, "rem's tale ch.10": 4073,
    "dark adaman sheet": 2001, "etoile shoes -1": 2722, "lightweight steel sheet": 2008,
}
unresolved = set()
def iid(name):
    n = name.strip().strip('[]').split('|')[0].strip()
    k = n.lower()
    if k in OVERRIDE: return OVERRIDE[k]
    for d, key in ((en, k), (enl, k), (ennorm, norm(n)), (enlnorm, norm(n))):
        if key in d: return d[key]
    unresolved.add(n)
    return None

def links(text):
    """'[[One Byne Bill]] x28' -> [('One Byne Bill', 28)]; plain 'Tiger Leather' -> [('Tiger Leather',1)]"""
    out = []
    text = text.replace('<br />', ' ').replace('<br/>', ' ')
    found = list(re.finditer(r'\[\[([^\]|]+)(?:\|[^\]]*)?\]\](?:\s*x\s*(\d+))?', text))
    if found:
        for m in found:
            out.append((m.group(1).strip(), int(m.group(2) or 1)))
    else:
        m = re.match(r'\s*(.+?)\s*(?:x\s*(\d+))?\s*$', text)
        if m and m.group(1): out.append((m.group(1), int(m.group(2) or 1)))
    return out

JOBS = {'Warrior': 'WAR', 'Monk': 'MNK', 'White Mage': 'WHM', 'Black Mage': 'BLM', 'Red Mage': 'RDM', 'Thief': 'THF', 'Paladin': 'PLD',
        'Dark Knight': 'DRK', 'Beastmaster': 'BST', 'Bard': 'BRD', 'Ranger': 'RNG', 'Samurai': 'SAM', 'Ninja': 'NIN', 'Dragoon': 'DRG',
        'Summoner': 'SMN', 'Blue Mage': 'BLU', 'Corsair': 'COR', 'Puppetmaster': 'PUP', 'Dancer': 'DNC', 'Scholar': 'SCH',
        'Geomancer': 'GEO', 'Rune Fencer': 'RUN'}
SLOTS = ['head', 'body', 'hands', 'legs', 'feet']

def sections(page):
    parts = re.split(r'\n==\s*([^=\n]+?)\s*==\s*\n', '\n' + page)
    for k in range(1, len(parts), 2):
        name = parts[k].strip()
        if name in JOBS: yield JOBS[name], parts[k + 1]

def params(block):
    out = {}
    for m in re.finditer(r'\n\|\s*([^=\n|]+?)\s*=(.*?)(?=\n\||\n\}\}|\Z)', block, re.S):
        out[m.group(1).strip()] = m.group(2).strip()
    return out

def blocks(sec, tname):
    """per-slot sub-templates -> {slot: params}"""
    out = {}
    for b in re.split(r'\{\{' + re.escape(tname) + r'\s*\n', sec)[1:]:
        p = params('\n' + b)
        if 'slot' in p: out[p.get('slot').strip().lower()] = p
    return out

recipes = {}  # (family, step, job, slot) -> [(name, qty)] ; gil
skipped = []
def put(family, step, job, slot, mats):
    if any(n is None or n == '' for n, q in mats):
        skipped.append((family, step, job, slot)); return
    recipes[(family, step, job, slot)] = mats

# ---- Relic +1 (Dynamis): currency, relic -1, slot ingredient
for job, sec in sections(pages['Category:Relic Armor +1']):
    p = params(sec)
    for n, slot in enumerate(SLOTS, 1):
        mats = links(p.get(f'relic required item {n}', ''))
        mats += [(p[f'relic relic -1 {n}'], 1), (p[f'relic slot ingredient {n}'], 1)]
        put('relic', 'oldPlus1', job, slot, mats)

# ---- Relic +2 (Magian trials on Forgotten items; both trials' items together)
for job, sec in sections(pages['Category:Relic Armor +2']):
    for slot, p in blocks(sec, 'Relic Armor').items():
        mats = links(p.get('trial1', '')) + links(p.get('trial2', ''))
        mats = [(n, q) for n, q in mats if not n.startswith('Trial ')]
        put('relic', 'oldPlus2', job, slot, mats)

# ---- Empyrean +1 / +2 (Abyssea seals / stones)
for job, sec in sections(pages['Category:Empyrean Armor +1']):
    p = params(sec)
    seal = (p.get('emp seal') or '').strip()
    for slot in SLOTS:
        put('empyrean', 'oldPlus1', job, slot, [(f"{seal} Seal: {slot.capitalize()}", 10 if slot == 'body' else 8)])
STONE = {'head': ('Vision', 6), 'body': ('Ardor', 9), 'hands': ('Wieldance', 6), 'legs': ('Balance', 6), 'feet': ('Voyage', 6)}
for job, sec in sections(pages['Category:Empyrean Armor +2']):
    p = params(sec)
    for n, slot in enumerate(SLOTS, 1):
        word, q = STONE[slot]
        put('empyrean', 'oldPlus2', job, slot, [(f"{p[f'emp seal {n}'].strip()} of {word}", q)])

# ---- Reforged AF (109) from AF +1
AF109 = ['Phoenix Feather', 'Malboro Fiber', 'Beetle Blood', 'Damascene Cloth', 'Oxblood']
for job, sec in sections(pages['Category:Reforged Artifact Armor']):
    p = params(sec)
    for n, slot in enumerate(SLOTS, 1):
        put('af', 'reforged', job, slot, [(f"Rem's Tale Ch.{n}", 5), (p.get('af job ingredient'), 1), (AF109[n - 1], 1)])

# ---- Reforged AF +1
AF119 = ['Maliyakaleya Orb', 'Hepatizon Ingot', 'Beryllium Ingot', 'Exalted Lumber', "Sif's Macrame"]
for job, sec in sections(pages['Category:Reforged Artifact Armor +1']):
    p = params(sec)
    for n, slot in enumerate(SLOTS, 1):
        put('af', 'reforgedPlus1', job, slot, [(f"Rem's Tale Ch.{n + 5}", 8), (p.get('af job ingredient'), 1), (AF119[n - 1], 1)])

# ---- Reforged AF +2 (per-piece values on the page)
AFP2 = ["Emperor Arthro's Shell", "Joyous's Moss", "Imperator's Wing", "Warblade Beak's Hide", "Abyssdiver's Feather"]
CARD2 = [4, 5, 3, 4, 3]
for job, sec in sections(pages['Category:Reforged Artifact Armor +2']):
    p = params(sec)
    card = p.get('af required item 1')
    jing = p.get('af job ingredient 1')
    for n, slot in enumerate(SLOTS, 1):
        put('af', 'reforgedPlus2', job, slot, [(card, CARD2[n - 1]), (jing, 1), (AFP2[n - 1], 1)])

# ---- Reforged AF +3
CARD3 = [12, 15, 9, 12, 9]
DAY2 = [[('Khoma Cloth', 1), ('S. Faulpie Leather', 1), ('Cyan Orb', 2)], [('Niobium Ingot', 1), ('Cypress Lumber', 1), ('Cyan Orb', 3)],
        [('Faulpie Leather', 3), ('Cypress Log', 1), ('Cyan Orb', 1)], [('Ruthenium Ingot', 1), ('Cypress Lumber', 1), ('Cyan Orb', 2)],
        [('Azure Cermet', 3), ('Khoma Thread', 1), ('Cyan Orb', 1)]]
for job, sec in sections(pages['Category:Reforged Artifact Armor +3']):
    p = params(sec)
    for n, slot in enumerate(SLOTS, 1):
        put('af', 'reforgedPlus3', job, slot, [(p.get('af required item 1'), CARD3[n - 1]), (p.get('af job ingredient 1'), 1)] + DAY2[n - 1])

# ---- Reforged Relic (109) from Relic +2 (no Magian augment: x10 chapters)
for job, sec in sections(pages['Category:Reforged Relic Armor']):
    for slot, p in blocks(sec, 'Reforged Armor').items():
        ch = links(p.get('alternatechapters1', p.get('chapters', '')))[:1]
        put('relic', 'reforged', job, slot, ch + [(p.get('jobingredient'), 1), (p.get('slotingredient'), 1)])

# ---- Reforged Relic +1 / +2 / +3
R1JOB = {}
for js, item in [('WAR NIN DRG', 'Voidwrought Plate'), ('MNK THF BRD COR', "Kaggen's Cuticle"), ('WHM BLM SCH GEO', "Akvan's Pennon"),
                 ('RDM PLD DRK BLU SAM', "Pil's Tuille"), ('BST SMN PUP', "Hahava's Mail"), ('RNG DNC RUN', "Celaeno's Cloth")]:
    for j in js.split(): R1JOB[j] = item
R2JOB = {}
for js, item in [('WAR BST RNG', 'S. Faulpie Leather'), ('PLD DRG', 'Ruthenium Ore'), ('DRK SAM NIN RUN', 'Niobium Ore'),
                 ('WHM BRD BLU GEO', 'Khoma Thread'), ('MNK THF DNC', 'Cypress Log'), ('RDM SMN SCH', 'Cyan Coral'), ('BLM COR PUP', 'Azure Leaf')]:
    for j in js.split(): R2JOB[j] = item
RSLOT = ['Gabbrath Horn', 'Yggdreant Bole', 'Bztavian Stinger', 'Waktza Rostrum', 'Rockfin Tooth']
SHARD = ['Headshard', 'Torsoshard', 'Handshard', 'Legshard', 'Footshard']
VOID = ['Voidhead', 'Voidtorso', 'Voidhand', 'Voidleg', 'Voidfoot']
R3SLOT = ['Defiant Scarf', "Hades' Claw", 'Macuil Plating', 'Tartarian Soul', 'Plovid Flesh']
for job in JOBS.values():
    for n, slot in enumerate(SLOTS):
        put('relic', 'reforgedPlus1', job, slot, [(f"Rem's Tale Ch.{n + 6}", 8), (R1JOB[job], 1), (RSLOT[n], 1)])
        put('relic', 'reforgedPlus2', job, slot, [(f'{SHARD[n]}: {job}', 2), (R2JOB[job], 1), (RSLOT[n], 1)])
        put('relic', 'reforgedPlus3', job, slot, [(f'{SHARD[n]}: {job}', 2), (f'{VOID[n]}: {job}', 2), (R3SLOT[n], 2)])

# ---- Reforged Empyrean (109) from +2, +1, +2, +3
for job, sec in sections(pages['Category:Reforged Empyrean Armor']):
    for slot, p in blocks(sec, 'Reforged Empyrean Armor').items():
        put('empyrean', 'reforged', job, slot, links(p.get('chapters')) + [(p.get('jobingredient'), 1), (p.get('slotingredient'), 1)])
for job, sec in sections(pages['Category:Reforged Empyrean Armor +1']):
    for slot, p in blocks(sec, 'Reforged Empyrean Armor +1').items():
        put('empyrean', 'reforgedPlus1', job, slot, links(p.get('chapters')) + links(p.get('jobingredient')) + links(p.get('slotingredient')))
for tier, page in (('reforgedPlus2', 'Category:Reforged Empyrean Armor +2'), ('reforgedPlus3', 'Category:Reforged Empyrean Armor +3')):
    for job, sec in sections(pages[page]):
        for slot, p in blocks(sec, 'Reforged Empyrean Armor +2').items():
            put('empyrean', tier, job, slot, links(p.get('item')) + [('GIL', 1)])

# ---------- join with the chains
cfg = open(R + '/modules/custom/lua/af_upgrade_config.lua').read()
fam = job = None
steps = {}  # resultId -> (family, step, job, slot, fromId)
OLD = [None, 'oldPlus1', 'oldPlus2']
REF = ['reforged', 'reforgedPlus1', 'reforgedPlus2', 'reforgedPlus3', 'reforgedPlus4']
for line in cfg.splitlines():
    m = re.match(r'^    (af|relic|empyrean) =', line)
    if m: fam = m.group(1); continue
    m = re.match(r'^        ([A-Z]{3}) =', line)
    if m: job = m.group(1); continue
    m = re.match(r'^\s*\{ base = \{([^}]*)\}, reforged = \{([^}]*)\} \}, -- (\w+)', line)
    if m and fam:
        base = [int(x) for x in m.group(1).split(',') if x.strip()]
        ref = [int(x) for x in m.group(2).split(',') if x.strip()]
        slot = m.group(3)
        ids = base + ref
        keys = [OLD[i] for i in range(len(base))] + REF[:len(ref)]
        for i in range(1, len(ids)):
            steps[ids[i]] = (fam, keys[i], job, slot, ids[i - 1])

# Old AF +1: Sagheera's own table (exact retail, item ids)
sag = {}
for m in re.finditer(r'trade = \{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\}, abc =\s*(\d+), reward =\s*(\d+)', open(R + '/scripts/zones/Port_Jeuno/npcs/Sagheera.lua').read()):
    base, t, a, c, abc, rew = map(int, m.groups())
    sag[rew] = [(t, 1), (a, 1), (c, 1), (1875, abc)]  # 1875 = ancient beastcoin

out, missing = {}, []
for rid, (f, step, j, slot, frm) in sorted(steps.items()):
    if step == 'reforgedPlus4':
        continue
    if f == 'af' and step == 'oldPlus1':
        mats = sag.get(rid)
        if not mats: missing.append((rid, f, step, j, slot)); continue
        out[rid] = {'from': frm, 'step': step, 'fam': f, 'job': j, 'slot': slot, 'items': mats}
        continue
    r = recipes.get((f, step, j, slot))
    if r is None:
        missing.append((rid, f, step, j, slot)); continue
    items, gil = [], False
    for n, q in r:
        if n == 'GIL': gil = True; continue
        i = iid(n)
        items.append((i if i else n, q))
    out[rid] = {'from': frm, 'step': step, 'fam': f, 'job': j, 'slot': slot, 'items': items, 'gil': gil}


problems = missing or unresolved
print('steps', len(out), 'missing', len(missing), 'unresolved names', len(unresolved))
for x in missing[:40]:
    print('  missing', x)
for n in sorted(unresolved):
    print('  ?', n)
if problems:
    sys.exit('not writing the Lua file: fix the missing steps / names first')

m = {str(k): v for k, v in out.items()}
ids = set(int(k) for k in m) | {int(i) for r in m.values() for i, q in r['items']} | {r['from'] for r in m.values()}
with migrate.MySQL() as db:
    names = {int(a): b for a, b in db.query(f"SELECT itemid,name FROM item_basic WHERE itemid IN ({','.join(map(str, ids))})")}
assert all(i in names for i in ids), [i for i in ids if i not in names]
order = {'af': 0, 'relic': 1, 'empyrean': 2}
stepname = {'oldPlus1': 'old +1', 'oldPlus2': 'old +2', 'reforged': 'Reforged', 'reforgedPlus1': 'Reforged +1', 'reforgedPlus2': 'Reforged +2', 'reforgedPlus3': 'Reforged +3'}
jobs = 'WAR MNK WHM BLM RDM THF PLD DRK BST BRD RNG SAM NIN DRG SMN BLU COR PUP DNC SCH GEO RUN'.split()
slots = ['head', 'body', 'hands', 'legs', 'feet']
rows = sorted(m.items(), key=lambda kv: (order[kv[1]['fam']], jobs.index(kv[1]['job']), list(stepname).index(kv[1]['step']), slots.index(kv[1]['slot']), int(kv[0])))
out = []
out.append('''-----------------------------------
-- Armor Upgrader: the retail materials for every upgrade step, by the item the step MAKES. Not a module (loaded by require).
-- Eric's choice (2026-09-26): retail requirements where the game has them, added drops (upgrade_drops.lua) for content LSB
-- does not have (Omen, Escha, Sortie, Geas Fete, Voidwatch). Generated from the BG Wiki tier pages (Artifact / Relic /
-- Empyrean +1 and +2, Reforged 109 to +3) and, for old Artifact +1, from Sagheera's own table in Port Jeuno. Do not edit
-- by hand: rerun the generator (see docs/custom/NOTES.md) and diff.
-- Retail steps that need a currency with no item (Gallimaufry for Reforged Empyrean +2/+3) cost gil instead
-- (af_upgrade_config.lua prices). Magian trials are replaced by trading the trial's items directly, and both Relic +2
-- trials' items are asked for at once. Old sets are upgraded from their +1 (Reforged 109 retail: fewer chapters than
-- from the base piece); Relic +2 has no Magian augment here, so it takes the full 10 chapters.
-- Format: [made item] = { item, quantity, item, quantity, ... }, -- made <- traded piece: materials
-----------------------------------
local materials =
{''')
last = None
for rid, r in rows:
    head = (r['fam'], r['job'], r['step'])
    if head[:2] != (last or (None, None))[:2]:
        out.append(f"    -- {r['fam']} {r['job']}")
    last = head
    agg = collections.OrderedDict()
    for i, q in r['items']:
        agg[int(i)] = agg.get(int(i), 0) + q
    flat = ', '.join(f'{i}, {q}' for i, q in agg.items())
    desc = ', '.join(names[i] + (f' x{q}' if q > 1 else '') for i, q in agg.items())
    gil = ' + gil' if r.get('gil') else ''
    out.append(f"    [{int(rid)}] = {{ {flat} }}, -- {names[int(rid)]} <- {names[r['from']]}: {desc}{gil}")
out.append('}\n\nreturn materials\n')
open(os.path.join(REPO, 'modules/custom/lua/af_upgrade_materials.lua'), 'w').write('\n'.join(out))
print(len(rows), 'entries')
