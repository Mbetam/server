"""
A minimal reader for settings/network.lua, and a connection helper. Deliberately not a full Lua
parser - it only understands simple `KEY = value,` lines, the same as tools/dbtool.py's own reader.
Kept separate from dbtool.py so importing this module never runs dbtool's menu code.
"""

import os

import mariadb

REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))


def _read_lua_settings(path):
    values = {}

    if not os.path.isfile(path):
        return values

    with open(path) as f:
        for line in f:
            line = line.strip()

            if '=' not in line or line.startswith('--'):
                continue

            key, _, rest = line.partition('=')
            key = key.strip()
            val = rest.split('--', 1)[0].strip()  # drop a trailing comment

            if val.endswith(','):
                val = val[:-1].strip()

            if val.startswith(("'", '"')) and val.endswith(("'", '"')):
                val = val[1:-1]

            values[key] = val

    return values


def network_settings():
    """SQL_HOST, SQL_PORT, SQL_LOGIN, SQL_PASSWORD, SQL_DATABASE, read from the git-ignored settings
    file (settings/network.lua), falling back to settings/default/network.lua for anything missing."""
    settings = _read_lua_settings(os.path.join(REPO_ROOT, 'settings', 'default', 'network.lua'))
    settings.update(_read_lua_settings(os.path.join(REPO_ROOT, 'settings', 'network.lua')))

    return settings


def connect():
    settings = network_settings()

    return mariadb.connect(
        host=settings.get('SQL_HOST', '127.0.0.1'),
        port=int(settings.get('SQL_PORT', 3306)),
        user=settings['SQL_LOGIN'],
        password=settings['SQL_PASSWORD'],
        database=settings['SQL_DATABASE'],
    )
