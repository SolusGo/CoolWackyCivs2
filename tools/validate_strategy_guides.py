"""Validate authored guides, native chapter routing, preserved lore and metadata-only changes."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib
import json
import re
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/python'))
from generate_strategy_guides import prefix, sections, render_sql, render_markdown, render_index, render_matchups


def database_and_paths():
    if ROOT.name.endswith('2'):
        from database import database
        from build_mod import files
        return database(), [p for p in files() if p.suffix == '.sql']
    from build_mod import read_project, NS
    from validate_mod import apply_current_cp_schema
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    source = sqlite3.connect((user / 'cache_backup/Civ5DebugDatabase.db').as_uri() + '?mode=ro', uri=True)
    db = sqlite3.connect(':memory:'); source.backup(db); source.close(); db.row_factory = sqlite3.Row
    apply_current_cp_schema(db, user / 'MODS/(1) Community Patch')
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    paths = [ROOT / e.text for e in read_project()[1].findall('m:ModActions/m:Action/m:FileName', NS)]
    return db, paths


def translations(db):
    return dict(db.execute('SELECT Tag,Text FROM Language_en_US'))


def chapters(text, key):
    # The native SelectCivilizationArticle loop stops at the first missing pair.
    result = []; i = 1
    while key and key + '_HEADING_' + str(i) in text and key + '_TEXT_' + str(i) in text:
        result.append((text[key + '_HEADING_' + str(i)], text[key + '_TEXT_' + str(i)])); i += 1
    return result


def gameplay_snapshot(db):
    allowed = {'Civilizations': {'Description', 'ShortDescription', 'Civilopedia', 'CivilopediaTag', 'Strategy'},
               'Leaders': {'Description', 'Civilopedia', 'CivilopediaTag'}}
    snapshot = {}
    for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        if table == 'Language_en_US':
            continue
        columns = [r[1] for r in db.execute('PRAGMA table_info("' + table + '")') if r[1] not in allowed.get(table, set())]
        query = 'SELECT ' + ','.join('"' + c.replace('"', '""') + '"' for c in columns) + ' FROM "' + table.replace('"', '""') + '"'
        snapshot[table] = db.execute(query).fetchall()
    return snapshot


def check_links(path):
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
        if target.startswith(('http:', 'https:', '#')):
            continue
        assert (path.parent / target.split('#')[0]).is_file(), (path, 'broken link', target)


def run():
    data = json.loads((ROOT / 'docs/StrategyGuides.json').read_text(encoding='utf-8'))
    registry = data['opponents']; records = data['civilizations']
    assert len({c['civ'] for c in records}) == len(records)
    db, paths = database_and_paths()
    roster = {p.relative_to(ROOT).parts[0] for p in paths if p.name.endswith('_Core.sql')}
    assert roster == {c['folder'] for c in records}, 'An activated civilization is missing its strategy guide'
    guides = [p for p in paths if p.name == '90_PlayerGuide.sql']
    assert len(guides) == len(records), 'Guide SQL missing from actual activation order'
    for path in paths:
        if path not in guides:
            db.executescript(path.read_text(encoding='utf-8-sig'))
    before_text = translations(db); before_game = gameplay_snapshot(db)
    for c in records:
        for field in ['strengths', 'weaknesses', 'counterplay', 'mistakes']:
            assert len(c[field]) >= 3 and all(len(s.split()) >= 5 for s in c[field]), (c['folder'], field)
        for kind in ['favourable', 'unfavourable']:
            assert len(c[kind]) == 2
            for other, reason in c[kind]:
                assert other in registry and other != c['folder'] and len(reason.split()) >= 5, (c['folder'], other, reason)
        for source in c['sources']:
            assert (ROOT / source).is_file(), source
        sql = ROOT / c['folder'] / 'SQL/90_PlayerGuide.sql'
        assert sql in guides
        assert sql.read_text(encoding='utf-8') == render_sql(c, registry)
        page = ROOT / 'docs/strategy' / (c['folder'] + '.md')
        assert page.read_text(encoding='utf-8') == render_markdown(c, registry).rstrip() + '\n'
        check_links(page)
        db.executescript(sql.read_text(encoding='utf-8'))
    after = translations(db)
    assert all(after.get(key) == value for key, value in before_text.items()), 'An existing localization key changed'
    assert before_game == gameplay_snapshot(db), 'Guide overlay changed gameplay, IDs or selection flags'
    all_lore = 0
    for c in records:
        base = prefix(c); civ = db.execute('SELECT * FROM Civilizations WHERE Type=?', (c['civ'],)).fetchone()
        leader = db.execute('SELECT * FROM Leaders WHERE Type=?', (c['leader'],)).fetchone()
        assert (civ['Playable'], civ['AIPlayable']) == (1, 0)
        assert civ['CivilopediaTag'] == base + '_CIV' and leader['CivilopediaTag'] == base + '_LEADER'
        for field, old in [('Description', c['description_key']), ('ShortDescription', c['short_key'])]:
            assert after[civ[field]] == before_text[old], (c['folder'], 'display name changed')
        assert after[leader['Description']] == before_text[c['leader_name_key']]
        for article, old, lead, biography in [(civ, c['civ_prefix'], len(sections(c, registry)), c['civ_pedia']),
                                               (leader, c['leader_prefix'], 3, c['leader_pedia'])]:
            actual = chapters(after, article['CivilopediaTag'])
            original = chapters(before_text, old)
            expected = original or [('Background and history', before_text.get(biography, c['plan']))]
            assert len(actual) == lead + len(expected), (c['folder'], 'incomplete native article', len(actual))
            assert actual[lead:] == expected, (c['folder'], 'old lore changed or disappeared')
            all_lore += len(expected)
        assert chapters(after, civ['CivilopediaTag'])[:len(sections(c, registry))] == sections(c, registry)
        assert civ['Strategy'] in after and after[civ['Strategy']].startswith(c['plan'])
    # Reapplication must not duplicate lore or grow paragraphs on cache reload.
    for path in guides:
        db.executescript(path.read_text(encoding='utf-8'))
    assert translations(db) == after and gameplay_snapshot(db) == before_game, 'Non-idempotent presentation overlay'
    for name, expected in [('StrategyGuide.md', render_index(data)), ('Matchups.md', render_matchups(data))]:
        path = ROOT / 'docs' / name
        assert path.read_text(encoding='utf-8') == expected.rstrip() + '\n'
        check_links(path)
    # Replay the actual installed indexing functions in a disposable fixture.
    # This known archived baseline omits Arabia's native leader relation.
    from civilopedia_index import replay_index, support_source
    if not db.execute("SELECT 1 FROM Civilization_Leaders WHERE CivilizationType='CIVILIZATION_ARABIA'").fetchone():
        native = support_source().parent.parent / 'Gameplay/XML/Civilizations/CIV5Civilizations.xml'
        row = next(r for r in ET.parse(native).findall('Civilization_Leaders/Row') if r.findtext('CivilizationType') == 'CIVILIZATION_ARABIA')
        db.execute('INSERT INTO Civilization_Leaders(CivilizationType,LeaderheadType) VALUES (?,?)',
                   (row.findtext('CivilizationType'), row.findtext('LeaderheadType')))
    terms = tuple(dict.fromkeys([after[db.execute('SELECT ShortDescription FROM Civilizations WHERE Type=?', (c['civ'],)).fetchone()[0]].lower() for c in records] +
                               [after[db.execute('SELECT Description FROM Leaders WHERE Type=?', (c['leader'],)).fetchone()[0]].lower() for c in records]))
    native = replay_index(db, after, terms)
    assert native['completed_categories'] == list(range(1, 17)), native
    assert all(native['search'][term] and native['search'][term]['entryCategory'] == 10 for term in terms), native['search']
    db.close()
    print(f'PASS {len(records)} complete civ/leader guides, {all_lore} preserved lore chapters, native indexing/search, linked docs, idempotence and unchanged gameplay')
    return {'civilizations': len(records), 'preserved_lore_chapters': all_lore, 'native_indexing': native, 'native_rendering': 'NOT RUN'}


if __name__ == '__main__':
    run()
