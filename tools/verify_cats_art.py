"""Check reproducible Cats 2D compilation and unchanged peer artwork.

Requires the same Pillow/DirectXTex environment as the normal collection build.
Runs the actual preparation/manifest/atlas pipeline, then compares exact bytes.
"""
from pathlib import Path
import hashlib, subprocess, sys
from build_mod import R, CIVILIZATIONS, manifests

def snapshot(paths):
    return {str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}

def main():
    sources=R/'art-source/The11Cats'
    derived=[sources/name for name in ['Alpha.png','Cats.png','Icon.png','Objects.png','Portrait.png','Group.png','Identity.json','PortraitPreview.png']]
    masters=list((R/'art-source/IconAtlasMasters').glob('THE11CATS_*.png'))
    cats=list((R/'The11Cats/Art').glob('*'))
    peers=[p for civ in CIVILIZATIONS if civ!='The11Cats' for p in (R/civ/'Art').glob('*') if p.is_file()]
    before=snapshot(derived+masters+cats+peers)
    subprocess.run([sys.executable,str(R/'tools/prepare_cats_art.py')],check=True)
    manifests()
    after=snapshot(derived+masters+cats+peers)
    changed=[name for name,value in before.items() if after.get(name)!=value]
    assert not changed,('non-reproducible or peer-art change',changed)
    print('PASS exact repeat build:',len(cats),'Cats game art files,',len(derived)+len(masters),'derived masters,',len(peers),'unchanged peer-art files')

if __name__=='__main__':main()
