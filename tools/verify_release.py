"""Verify built ZIP/7z inventories, game-file bytes and the embedded modinfo."""
from pathlib import Path
import tempfile, zipfile
import py7zr
from build_mod import R,NAME,CIVILIZATIONS,files,relative

def main():
    game=files()
    paths=game+[R/(NAME+'.modinfo'),R/'README.md',R/'CHANGELOG.md']
    paths += [p for civ in CIVILIZATIONS for p in (R/civ).rglob('*.md')]+list((R/'docs').rglob('*.md'))
    paths += [p for civ in CIVILIZATIONS for p in (R/civ/'docs').glob('*.json')]
    expected={relative(p):p for p in paths}
    assert len(expected)==len(paths),'duplicate package paths'
    with zipfile.ZipFile(R/'dist'/(NAME+'.zip')) as z:
        assert z.testzip() is None
        assert {n.removeprefix(NAME+'/') for n in z.namelist()}==set(expected),'ZIP inventory'
        for name,p in expected.items(): assert z.read(NAME+'/'+name)==p.read_bytes(),('ZIP stale bytes',name)
    with py7zr.SevenZipFile(R/'dist'/(NAME+'.civ5mod')) as z:
        assert set(z.getnames())==set(expected),'7z inventory'
        assert z.testzip() is None,'7z CRC'
    # Extract a small authoritative sample, confined to the ignored workspace output.
    with tempfile.TemporaryDirectory(prefix='verify-release-',dir=R/'dist') as temporary:
        target=Path(temporary).resolve()
        assert target.parent==(R/'dist').resolve(),'unsafe extraction target'
        sample=[NAME+'.modinfo','TheWanderingCircus/UI/WanderingCircus.lua',
                'TheWanderingCircus/SQL/02_WCIRCUS_Effects.sql']
        with py7zr.SevenZipFile(R/'dist'/(NAME+'.civ5mod')) as z: z.extract(path=target,targets=sample)
        for name in sample: assert (target/name).read_bytes()==(R/name).read_bytes(),('7z stale bytes',name)
    print('PASS ZIP and genuine 7z/LZMA release:',len(expected),'files,',len(game),'game files, exact ZIP bytes, CRC and extracted 7z manifest/runtime/SQL')

if __name__=='__main__': main()
