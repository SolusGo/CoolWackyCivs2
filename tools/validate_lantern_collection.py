"""Run the current collection suite while preserving every civ report/source.

Includes the user's newer/uncommitted civilizations. Redirect generated JSON
evidence to ignored tools/reference; reject any attempted gameplay/source write.
"""
from pathlib import Path
import hashlib
import json
import runpy
import time
from build_mod import R, CIVILIZATIONS


def snapshot():
    return {p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for name in CIVILIZATIONS if name!='TheLanternFleet'
            for p in (R/name).rglob('*') if p.is_file()}


def main():
    before=snapshot();original=Path.write_text;reports=[];start=time.perf_counter()
    evidence=R/'tools/reference/lantern-collection-reports'
    def guarded(path,data,*args,**kwargs):
        target=path.resolve()
        try:relative=target.relative_to(R)
        except ValueError:relative=None
        if relative and relative.parts[0] in CIVILIZATIONS:
            assert path.suffix=='.json' and 'docs' in relative.parts,('unexpected source mutation',str(relative))
            report=evidence/relative;report.parent.mkdir(parents=True,exist_ok=True)
            reports.append(relative.as_posix())
            return original(report,data,*args,**kwargs)
        return original(path,data,*args,**kwargs)
    Path.write_text=guarded
    try:
        runpy.run_path(str(R/'tools/validate_mod.py'),run_name='__main__')
    finally:
        Path.write_text=original
        changed=[name for name,digest in before.items() if not (R/name).is_file()
                 or hashlib.sha256((R/name).read_bytes()).hexdigest()!=digest]
        added=set(snapshot())-set(before)
        assert not changed and not added,('civilization files changed during regression',changed,sorted(added))
    result={'result':'PASS','scope':'complete current tools/validate_mod.py; static and simulated only',
            'civilizations':list(CIVILIZATIONS),'preserved_civilization_files':len(before),
            'redirected_report_writes':reports,'elapsed_seconds':round(time.perf_counter()-start,2),
            'native_tests':'NOT RUN; user instructed not to launch Civ V'}
    (R/'TheLanternFleet/docs/CollectionRegression.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('PASS complete collection regression;',len(CIVILIZATIONS),'civs;',len(before),'other-civ files preserved; no native gameplay tests')
    return result


if __name__=='__main__':main()
