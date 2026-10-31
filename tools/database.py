"""Read-only BNW cache adapter; all schema changes occur in memory."""
from pathlib import Path
import re, sqlite3
from xml.etree import ElementTree as ET
from validation_prerequisites import inspect_database,paths,SCHEMA_FILES

def quote(s):
    return '"' + s.replace('"', '""') + '"'

def is_cp_cache(cache):
    """A menu/vanilla cache cannot serve as an already-activated CP baseline."""
    with sqlite3.connect(Path(cache).resolve().as_uri()+'?mode=ro',uri=True) as d:
        return 'IsDummy' in {r[1] for r in d.execute('PRAGMA table_info(Buildings)')} and bool(
            d.execute("SELECT 1 FROM sqlite_master WHERE name='CustomModOptions'").fetchone())

def database(cache=None, cp=None):
    cache,cp=paths(cache,cp)
    inspect_database(cache,cp)
    source = sqlite3.connect(cache.resolve().as_uri() + '?mode=ro', uri=True)
    d = sqlite3.connect(':memory:'); source.backup(d); source.close()
    for relative in SCHEMA_FILES:
        text = (cp / 'Database Changes' / relative).read_text(encoding='utf-8-sig')
        for sql in re.findall(r'ALTER\s+TABLE\s+[^;]+?\s+ADD\s+.*?;', text, re.I | re.S):
            try: d.execute(sql)
            except sqlite3.OperationalError as e:
                if 'duplicate column name' not in str(e).lower(): raise
    d.execute('CREATE TABLE IF NOT EXISTS CustomModOptions(Name TEXT,Value INTEGER,Class INTEGER,DbUpdates INTEGER)')
    for row in ET.parse(cp / 'Database Changes/NewCustomModOptions.xml').iter('Row'):
        if row.get('Name'):
            d.execute('DELETE FROM CustomModOptions WHERE Name=?', (row.get('Name'),))
            d.execute('INSERT INTO CustomModOptions VALUES(?,?,?,?)',
                      (row.get('Name'), int(row.get('Value', 0)), int(row.get('Class', 0)), int(row.get('DbUpdates', 0))))
    for path in sorted((cp / 'Database Changes').rglob('*.xml')):
        text = re.sub(r'<!--.*?-->', '', path.read_text(encoding='utf-8-sig'), flags=re.S)
        try: root = ET.fromstring(text)
        except ET.ParseError: continue
        for table in root.findall('Table'):
            name = table.get('name', '')
            if not name.startswith(('Building_', 'Unit_', 'UnitPromotions_', 'Policy_')) and name != 'CityEventChoices': continue
            columns = []
            for col in table.findall('Column'):
                default = col.get('default')
                suffix = '' if default is None else " DEFAULT '" + default.replace("'", "''") + "'"
                if col.get('primarykey') == 'true':
                    suffix += ' PRIMARY KEY'
                    if col.get('autoincrement') == 'true': suffix += ' AUTOINCREMENT'
                columns.append(quote(col.get('name')) + ' ' + col.get('type', 'text') + suffix)
            if columns: d.execute('CREATE TABLE IF NOT EXISTS ' + quote(name) + '(' + ','.join(columns) + ')')
    if d.execute("SELECT 1 FROM sqlite_master WHERE name='Building_ThemingBonuses_new'").fetchone():
        if 'ConsecutiveEras' in {r[1] for r in d.execute('PRAGMA table_info(Building_ThemingBonuses)')}:
            d.execute('DROP TABLE Building_ThemingBonuses_new')
        else: d.executescript((cp/'Database Changes/City/Buildings/BuildingTableFixes.sql').read_text(encoding='utf-8-sig'))
    d.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    d.row_factory = sqlite3.Row
    return d
