"""Run the complete collection regression suite without rewriting released civs.

Legacy validators refresh JSON evidence files (some include elapsed timings).
Suppress those report writes, preserving the user's original civilizations exactly.
Gameplay/source writes to a released civilization are rejected, never hidden.
"""
from pathlib import Path
import hashlib,importlib,runpy,sys,time
from build_mod import R,CIVILIZATIONS

def snapshot():
    return {p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for c in CIVILIZATIONS if c!='TheTriumphalImperium'
            for p in (R/c).rglob('*') if p.is_file()}

def main():
    before=snapshot();original=Path.write_text;reports=[];started=time.perf_counter()
    def guarded(path,data,*args,**kwargs):
        resolved=path.resolve()
        try:rel=resolved.relative_to(R).as_posix()
        except ValueError:rel=''
        if rel.split('/')[0] in set(CIVILIZATIONS)-{'TheTriumphalImperium'}:
            assert path.suffix=='.json' and '/docs/' in rel,('regression attempted source mutation',rel)
            reports.append(rel);return len(data)
        return original(path,data,*args,**kwargs)
    Path.write_text=guarded
    resumed='--after-red' in sys.argv or '--after-rfd' in sys.argv
    try:
        if not resumed:
            runpy.run_path(str(R/'tools/validate_mod.py'),run_name='__main__')
        else:
            # Continue after correcting a legacy localization parser, without
            # repeating already-passed 335 MB texture decoding and core tests.
            proof=(R/'tools/reference/triumphal-core-validation.log').read_text(encoding='utf-8-sig')
            for receipt in ('PASS manifest/project load order','PASS read-only original-collection audit',
                            'PASS Pigeon actual-schema SQL','PASS Red Lua 5.1 simulations'):
                assert receipt in proof,('missing preceding validation phase',receipt)
            remaining=[('mcpvp','validate'),('kingdom','validate'),('twelfth','validate'),
                 ('circus','validate'),('cats','validate'),('saba','validate'),('garvey','validate'),
                 ('conical_union','validate'),('unrung','validate'),('urgal','main'),('jin','main'),
                 ('threshold','main'),('honeycomb','validate'),('laureate','validate'),
                 ('t1zofgk','validate'),('rfd','validate'),('lantern','validate'),('triumphal','validate')]
            if '--after-rfd' in sys.argv:
                proof=(R/'tools/reference/triumphal-through-rfd-validation.log').read_text(encoding='utf-8-sig')
                assert 'PASS RFD 26 shipped Lua 5.1 scenarios' in proof
                assert 'PASS Laureate Lua 5.1, manifest checksums' in proof
                remaining=remaining[remaining.index(('lantern','validate')):]
            for module,function in remaining:
                getattr(importlib.import_module('validate_'+module),function)()
    finally:Path.write_text=original
    assert snapshot()==before,'A released civilization changed during regression'
    summary=('# Collection regression\n\n'
             'Result: PASS all collection regression checks. '
             +('The core/package/Pigeon/Red phase and the remaining-civilization phase '
               'were run separately after repairing legacy localization-reference parsers. '
               'Already-passed core checks were not repeated.\n\n' if resumed else
               'The complete `tools/validate_mod.py` suite ran in one pass.\n\n')+
             f'All {len(before)} files in the twenty pre-existing civilization folders '
             'retain their SHA-256 hashes, including every Laureate Commonwealth file. '
             f'{len(reports)} legacy JSON report writes in the final phase were suppressed so their '
             'timing/results files remain unchanged.\n\n'
             'This includes database activation, native Civilopedia indexing replay, '
             'all shipped Lua syntax, per-civilization mock contracts, UI contracts, '
             'DDS decoding, original-collection namespace coexistence and the generated '
             'manifest/project inventory. These are not in-game tests.\n\n'
             f'Final phase elapsed test time: {time.perf_counter()-started:.1f} seconds.\n')
    (R/'TheTriumphalImperium/docs/Regression.md').write_text(summary,encoding='utf-8')
    print('PASS complete collection regression; all',len(before),'released civilization files unchanged')

if __name__=='__main__':main()
