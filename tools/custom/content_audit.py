#!/usr/bin/env python3
"""Content audit: what retail content has code on this server, and what does not.

Usage: ~/lsb-venv/bin/python3 tools/custom/content_audit.py [--json OUT.json]
Reads scripts/, data/zones/ and the DB (settings/network.lua). Changes nothing. Results: docs/custom/CONTENT_STATUS.md.

LSB no longer keeps a "What Works" list (wiki FAQ: "check the code"), so this checks each retail list the code itself
carries against the scripts that implement it:
  missions     xi.mission.id (scripts/globals/missions.lua) vs Mission:new(...) in scripts/missions/
  quests       xi.quest.id (scripts/globals/quests.lua) vs Quest:new(...) in scripts/quests/; a quest with no script
               but referenced in NPC / zone scripts counts as "old-style" (often partial)
  battlefields xi.battlefield.id (scripts/globals/battlefield.lua) vs battlefieldId = ... in scripts/battlefields/
  trusts       trust spells (spell_list 896+ in the enum) vs scripts/actions/spells/trust/<name>.lua
  zones        zones with no monsters / no NPCs in data/zones/*
  mob skills   mob_skills rows vs scripts/actions/mobskills/<name>.lua
  usable items item_usable rows vs scripts/items/<name>.lua
A script existing is not proof it works as in retail (see job_audit.py for the same caveat).
"""

import argparse
import collections
import json
import os
import re
import sys

import yaml

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools', 'custom'))
import migrate  # noqa: E402


def read(path):
    return open(os.path.join(REPO, path), encoding='utf-8', errors='ignore').read()


def lua_files(root):
    for dp, _, fn in os.walk(os.path.join(REPO, root)):
        for f in fn:
            if f.endswith('.lua'):
                yield os.path.join(dp, f)


def enum_blocks(text, start_marker):
    """{block key: {NAME: id}} for tables like xi.mission.id = { [key] = { NAME = 1, ... }, ... }"""
    body = text[text.index(start_marker):]
    out, key = {}, None
    for line in body.splitlines()[1:]:
        m = re.match(r"^    \[(?:xi\.\w+\.area\[xi\.[\w.]*?\.(\w+)\]|'(\w+)')\] =", line)
        if m:
            key = (m.group(1) or m.group(2) or '').lower()
            out[key] = {}
            continue
        if re.match(r'^}', line):
            break
        m = re.match(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', line)
        if m and key is not None:
            out[key][m.group(1)] = int(m.group(2))
    return out


def audit_missions():
    ids = enum_blocks(read('scripts/globals/missions.lua'), 'xi.mission.id =')
    area = dict(re.findall(r"\[xi\.mission\.log_id\.(\w+)\]\s*=\s*'(\w+)'", read('scripts/globals/missions.lua')))
    done = set()
    for f in lua_files('scripts/missions'):
        for m in re.finditer(r'Mission:new\(xi\.mission\.log_id\.\w+,\s*xi\.mission\.id\.(\w+)\.(\w+)\)', open(f).read()):
            done.add((m.group(1), m.group(2)))
    result = {}
    for logName, names in ids.items():
        key = area.get(logName.upper(), logName)
        if key == 'nation':
            continue
        real = {n: v for n, v in names.items() if n not in ('NONE',)}
        missing = [n for n in real if (key, n) not in done]
        result[key] = {'total': len(real), 'scripted': len(real) - len(missing), 'missing': missing}
    return result


def audit_quests():
    text = read('scripts/globals/quests.lua')
    ids = enum_blocks(text, 'xi.quest.id =')
    area = dict(re.findall(r"\[xi\.questLog\.(\w+)\]\s*=\s*'(\w+)'", text))
    done = set()
    for f in lua_files('scripts/quests'):
        for m in re.finditer(r'Quest:new\(xi\.questLog\.\w+,\s*xi\.quest\.id\.(\w+)\.(\w+)\)', open(f).read()):
            done.add((m.group(1), m.group(2)))
    referenced = set()
    for root in ('scripts/zones', 'scripts/globals', 'scripts/events'):
        for f in lua_files(root):
            for m in re.finditer(r'xi\.quest\.id\.(\w+)\.(\w+)', open(f, encoding='utf-8', errors='ignore').read()):
                referenced.add((m.group(1), m.group(2)))
    result = {}
    for logName, names in ids.items():
        key = area.get(logName.upper(), logName)
        rows = {'total': len(names), 'scripted': 0, 'oldStyle': [], 'missing': []}
        for n in names:
            if (key, n) in done:
                rows['scripted'] += 1
            elif (key, n) in referenced:
                rows['oldStyle'].append(n)
            else:
                rows['missing'].append(n)
        result[key] = rows
    return result


def audit_battlefields():
    text = read('scripts/globals/battlefield.lua')
    body = text[text.index('xi.battlefield.id ='):]
    body = body[:body.index('\n}')]
    ids = dict(re.findall(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', body, re.M))
    done = set()
    for f in lua_files('scripts/battlefields'):
        done |= set(re.findall(r'battlefieldId\s*=\s*xi\.battlefield\.id\.(\w+)', open(f).read()))
    missing = sorted(n for n in ids if n not in done)
    return {'total': len(ids), 'scripted': len(ids) - len(missing), 'missing': missing}


def audit_trusts(db):
    enum = read('scripts/enum/magic.lua')
    trustSpells = {int(v): n for n, v in re.findall(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', enum, re.M) if 896 <= int(v) <= 1020}
    names = {int(i): n for i, n in db.query('SELECT spellid, name FROM spell_list WHERE spellid BETWEEN 896 AND 1020')}
    files = {os.path.splitext(f)[0] for f in os.listdir(os.path.join(REPO, 'scripts/actions/spells/trust'))}
    missing = sorted(names[i] for i in names if names[i] not in files)
    return {'total': len(names), 'scripted': len(names) - len(missing), 'missing': missing}


def audit_zones():
    rows = []
    enumZones = dict((k.lower(), int(v)) for k, v in re.findall(r'^\s+([A-Z0-9_]+)\s*=\s*(\d+),', read('scripts/enum/zone.codegen.lua'), re.M))
    for zone, zid in sorted(enumZones.items(), key=lambda kv: kv[1]):
        d = os.path.join(REPO, 'data', 'zones', zone)
        mobs = npcs = 0
        ztype = []
        if os.path.exists(os.path.join(d, 'mobs.yaml')):
            mobs = len((yaml.safe_load(open(os.path.join(d, 'mobs.yaml'))) or {}).get('spawns') or {})
        if os.path.exists(os.path.join(d, 'npcs.yaml')):
            data = yaml.safe_load(open(os.path.join(d, 'npcs.yaml'))) or {}
            npcs = len(data.get('npcs') or data.get('spawns') or {})
        if os.path.exists(os.path.join(d, 'zone.yaml')):
            t = (yaml.safe_load(open(os.path.join(d, 'zone.yaml'))) or {}).get('type')
            ztype = t if isinstance(t, list) else ([t] if t else [])
        rows.append({'zone': zone, 'id': zid, 'hasData': os.path.isdir(d), 'mobs': mobs, 'npcs': npcs, 'type': ztype})
    return rows


def audit_named_scripts(db, sql, folder):
    names = [r[0] for r in db.query(sql)]
    files = set()
    for dp, _, fn in os.walk(os.path.join(REPO, folder)):
        files |= {os.path.splitext(f)[0] for f in fn if f.endswith('.lua')}
    missing = sorted({n for n in names if n and n not in files})
    return {'total': len(set(names)), 'scripted': len(set(names)) - len(missing), 'missing': missing}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--json')
    args = parser.parse_args()

    out = {'missions': audit_missions(), 'quests': audit_quests(), 'battlefields': audit_battlefields(), 'zones': audit_zones()}
    with migrate.MySQL() as db:
        out['trusts'] = audit_trusts(db)
        out['mobskills'] = audit_named_scripts(db, 'SELECT mob_skill_name FROM mob_skills', 'scripts/actions/mobskills')
        out['items'] = audit_named_scripts(db, 'SELECT name FROM item_usable', 'scripts/items')

    if args.json:
        json.dump(out, open(args.json, 'w'), indent=1)

    print('== Missions (scripted / total)')
    for k, v in out['missions'].items():
        print(f"  {k:10} {v['scripted']:4} / {v['total']:4}")
    print('== Quests (scripted / old-style / none / total)')
    for k, v in out['quests'].items():
        print(f"  {k:12} {v['scripted']:4} / {len(v['oldStyle']):4} / {len(v['missing']):4} / {v['total']:4}")
    b = out['battlefields']
    print(f"== Battlefields {b['scripted']} / {b['total']}")
    for key in ('trusts', 'mobskills', 'items'):
        v = out[key]
        print(f"== {key} {v['scripted']} / {v['total']}")
    empty = [z for z in out['zones'] if z['hasData'] and z['mobs'] == 0 and 'city' not in z['type']]
    print(f"== Zones with data but no monsters (not cities): {len(empty)}; zones with no data at all: {sum(1 for z in out['zones'] if not z['hasData'])}")


if __name__ == '__main__':
    main()
