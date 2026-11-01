"""Check selection flags after the complete, ordered collection SQL activation."""
from contextlib import closing
from database import database
from build_mod import R, CIVILIZATIONS, files


def validate(sql_paths, expected_count, label):
    with closing(database()) as db:
        before = {r['Type']: (r['Playable'], r['AIPlayable'])
                  for r in db.execute('SELECT Type,Playable,AIPlayable FROM Civilizations')}
        for path in sql_paths:
            db.executescript(path.read_text(encoding='utf-8-sig'))
        after = {r['Type']: (r['Playable'], r['AIPlayable'])
                 for r in db.execute('SELECT Type,Playable,AIPlayable FROM Civilizations')}
        added = after.keys() - before.keys()
        assert len(added) == expected_count, (label, 'unexpected roster size', len(added))
        assert all(after[civ] == (1, 0) for civ in added), {
            civ: after[civ] for civ in added if after[civ] != (1, 0)}
        assert all(after.get(civ) == flags for civ, flags in before.items()), (
            label, 'unrelated civilization selection flags changed')
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    print(f'PASS {label}: all {len(added)} civs human-only after full SQL activation; unrelated selection flags preserved')
    return len(added)


def run():
    return validate([p for p in files() if p.suffix == '.sql'], len(CIVILIZATIONS), R.name)


if __name__ == '__main__':
    run()
