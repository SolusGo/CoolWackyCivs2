"""Reproduce final collection verification without game launch or report churn.

The explicit optional-fixture flag only hides a live cache that preflight has
already rejected as collection-populated from optional exists() gates.
No database is substituted and the unavailable probe is never reported passed.
"""
from argparse import ArgumentParser
from contextlib import nullcontext
from datetime import date
from pathlib import Path
from unittest.mock import patch
import json
import subprocess
from build_mod import R
from validation_prerequisites import inspect_database, PrerequisiteError


def main(stamp, allow_unavailable=False):
    date.fromisoformat(stamp)
    historical=(R/'TheLanternFleet/docs/CollectionRegression.json').resolve()
    output=R/'TheLanternFleet/docs/FinalCollectionRegression.json'
    cache=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    blocked=[]
    if cache.exists():
        try:inspect_database(cache=cache)
        except PrerequisiteError as exc:
            if not allow_unavailable or 'already contains this collection' not in str(exc):raise
            blocked.append({'check':'optional pristine live-cache activation fixture', 'result':'UNAVAILABLE',
                            'affected_validators':['twelfth','circus','saba','conical_union','unrung'],
                            'path':str(cache),'reason':str(exc)})
            print('SKIP optional live-cache activation probes: preflight rejected the collection-populated fixture')
    from validate_lantern_collection import main as collection
    original_write,original_exists=Path.write_text,Path.exists
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=R,text=True).strip()
    def write(path,data,*args,**kwargs):
        if path.resolve()==historical:
            result=json.loads(data)
            result.update(date=stamp,audited_commit=commit,unavailable_checks=blocked,
                          result='PASS_AVAILABLE_CHECKS' if blocked else 'PASS',
                          native_tests='NOT RUN: user prohibited launching Civ V')
            return original_write(output,json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
        return original_write(path,data,*args,**kwargs)
    # The production controller, database adapter and assertions are untouched.
    # All primary archived-fixture paths and all other files keep real availability.
    def available(path):return False if path==cache else original_exists(path)
    context=patch.object(Path,'exists',available) if blocked else nullcontext()
    Path.write_text=write
    try:
        with context:collection()
    finally:
        Path.write_text=original_write
    print('PASS available collection checks;',len(blocked),'optional fixture(s) unavailable; no native gameplay acceptance')
    return json.loads(output.read_text(encoding='utf-8'))


if __name__=='__main__':
    parser=ArgumentParser(description=__doc__)
    parser.add_argument('--date',required=True,help='ISO date of this verification run')
    parser.add_argument('--allow-unavailable-optional-cache',action='store_true',
                        help='Explicitly report and skip only an already-populated optional live-cache probe')
    args=parser.parse_args()
    main(args.date,args.allow_unavailable_optional_cache)
