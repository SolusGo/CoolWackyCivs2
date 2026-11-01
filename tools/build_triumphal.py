"""Build a genuinely independent BNW + CP151 installer from the isolated module."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, tempfile, zipfile
import py7zr
from generate_triumphal import R,V

ID='0b3e628b-65d1-4b1d-9f06-e2aa1a2c1e11'
NAME='The Triumphal Imperium (v 1)'
ENTRY='TheTriumphalImperium/UI/TRI_Panel.xml'

def build():
    out=R/'dist';out.mkdir(exist_ok=True)
    stage=out/NAME;stage.mkdir(exist_ok=True)
    game=[R/'Shared/SQL/00_OptionalCompatibility.sql']+sorted(p for p in V.rglob('*') if p.suffix in ('.sql','.xml','.lua','.dds'))
    game.sort(key=lambda p:(p.relative_to(R).parts[0]!='Shared',p.as_posix()))
    root=ET.Element('Mod',id=ID,version='1')
    props=ET.SubElement(root,'Properties')
    for key,value in {'Name':'The Triumphal Imperium','Teaser':'One Victory Demands Another.',
        'Description':'Imperator Aurelion leads a human-only civilization with persistent Victory Momentum, The Unbroken and Halls of Triumphs. Requires Brave New World and Community Patch v151, without Vox Populi. Start a new single-player game. Do not enable with Cool Wacky Civs 2 v23+, which already includes this civilization.',
        'Authors':'SolusGo','AffectsSavedGames':'1','MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1',
        'SupportsMultiplayer':'0','SupportsHotSeat':'0','SupportsMac':'0','ReloadAudioSystem':'0',
        'ReloadLandmarkSystem':'0','ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}.items():
        ET.SubElement(props,key).text=value
    deps=ET.SubElement(root,'Dependencies')
    ET.SubElement(deps,'Dlc',id='6DA07636-4123-4018-B643-6575B4EC336B',minversion='0',maxversion='999',title='Expansion - Brave New World')
    ET.SubElement(deps,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='151',title='(1) Community Patch')
    ET.SubElement(root,'References')
    ET.SubElement(ET.SubElement(root,'Blocks'),'Mod',id='f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392',minversion='23',maxversion='999',title='Cool Wacky Civs 2 (includes this civilization)')
    declared=ET.SubElement(root,'Files')
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for path in game:
        rel=path.relative_to(R).as_posix()
        imported=path.suffix!='.sql' and rel!=ENTRY
        ET.SubElement(declared,'File',md5=hashlib.md5(path.read_bytes()).hexdigest().upper(),**{'import':str(int(imported))}).text=rel
        if path.suffix=='.sql':ET.SubElement(actions,'UpdateDatabase').text=rel
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file=ENTRY)
    ET.SubElement(entry,'Name').text='Victory Momentum'
    ET.SubElement(entry,'Description').text='Saved combat momentum, native military mobilisation and six-laurel display.'
    ET.indent(root,'  ')
    manifest=stage/(NAME+'.modinfo')
    ET.ElementTree(root).write(manifest,encoding='utf-8',xml_declaration=True)
    expected={NAME+'.modinfo':manifest.read_bytes()}
    documents=[p for p in V.rglob('*') if p.suffix in ('.md','.json')]
    for path in game+documents:
        rel=path.relative_to(R).as_posix();target=stage/rel;target.parent.mkdir(parents=True,exist_ok=True)
        data=path.read_bytes();target.write_bytes(data);expected[rel]=data
    assert {p.relative_to(stage).as_posix() for p in stage.rglob('*') if p.is_file()}==set(expected),'stale standalone stage inventory'
    with zipfile.ZipFile(out/(NAME+'.zip'),'w',compression=zipfile.ZIP_DEFLATED) as z:
        for rel,data in expected.items():z.writestr(NAME+'/'+rel,data)
    with py7zr.SevenZipFile(out/(NAME+'.civ5mod'),'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for rel in expected:z.write(stage/rel,rel)
    with zipfile.ZipFile(out/(NAME+'.zip')) as z:
        assert z.testzip() is None
        assert {p.removeprefix(NAME+'/') for p in z.namelist()}==set(expected)
        for rel,data in expected.items():assert z.read(NAME+'/'+rel)==data,rel
    with tempfile.TemporaryDirectory(prefix='verify-triumphal-',dir=out) as temporary:
        target=Path(temporary).resolve();assert target.parent==out.resolve()
        with py7zr.SevenZipFile(out/(NAME+'.civ5mod')) as z:
            assert z.testzip() is None;assert set(z.getnames())==set(expected)
        with py7zr.SevenZipFile(out/(NAME+'.civ5mod')) as z:z.extractall(target)
        for rel,data in expected.items():assert (target/rel).read_bytes()==data,rel
    print('PASS standalone ZIP and genuine 7z Civ5Mod: exact inventory, bytes and CRC;',len(game),'game files;',len(expected),'total files')
    return root

if __name__=='__main__':build()
