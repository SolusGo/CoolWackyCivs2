"""Actual SQL, Lua 5.1 syntax, independent population simulation and package checks."""
from pathlib import Path
from xml.etree import ElementTree as ET
from collections import Counter
import hashlib,re,struct,time
from database import database,quote
from build_mod import R,files,NAME,NS,ENTRY,ENTRIES,imported,MOD_ID,VERSION,DEPS
from generate_database import TEXT
from lupa.lua51 import LuaRuntime
V=R/'TheBoundlessCity'

def sql():
    d=database()
    native_traits=[tuple(r) for r in d.execute('SELECT * FROM Traits ORDER BY ID')]
    before={t:d.execute('SELECT * FROM '+t+' WHERE Type=?',(n,)).fetchone() for t,n in
            [('Civilizations','CIVILIZATION_AMERICA'),('Units','UNIT_WORKER'),('Buildings','BUILDING_MONUMENT')]}
    for path in sorted((V/'SQL').glob('*.sql')):d.executescript(path.read_text(encoding='utf-8'))
    assert tuple(d.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_BOUNDLESS_CITY'").fetchone())==(1,1)
    for table,old,new,allowed in [
        ('Units','UNIT_WORKER','UNIT_BC_SURVEYOR',{'ID','Type','Moves','WorkRate','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_MONUMENT','BUILDING_BC_REGISTRY',{'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone();b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for k in a.keys():
            if k not in allowed:assert a[k]==b[k],(table,k)
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in columns:continue
            fields=[c for c in columns if c not in [col,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            original=Counter(tuple(r) for r in d.execute(query,(old,)))
            unique=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Building_YieldChanges':
                original=Counter({row:count for row,count in original.items() if row[0]!='YIELD_CULTURE'})
            assert not original-unique,('companion inheritance',t)
    row=d.execute("SELECT Moves,WorkRate FROM Units WHERE Type='UNIT_BC_SURVEYOR'").fetchone()
    assert row[0]==3 and row[1]==int(before['Units']['WorkRate']*1.25)
    assert d.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_BC_REGISTRY' AND YieldType='YIELD_CULTURE'").fetchone()[0]==3
    assert d.execute("SELECT NoAnnexing FROM Traits WHERE Type='TRAIT_BC_ONE_WORLD'").fetchone()[0]==1
    assert d.execute("SELECT StaysAliveZeroCities FROM Traits WHERE Type='TRAIT_BC_ONE_WORLD'").fetchone()[0]==1
    assert native_traits==[tuple(r) for r in d.execute("SELECT * FROM Traits WHERE Type!='TRAIT_BC_ONE_WORLD' ORDER BY ID")]
    assert d.execute("SELECT NoCapture FROM UnitPromotions WHERE Type='PROMOTION_BC_NO_CAPTURE'").fetchone()[0]==1
    assert d.execute("SELECT Count FROM Civilization_FreeUnits WHERE CivilizationType='CIVILIZATION_BOUNDLESS_CITY' AND UnitClassType='UNITCLASS_SETTLER'").fetchone()[0]==1
    for table,old in [('Civilizations','CIVILIZATION_AMERICA'),('Units','UNIT_WORKER'),('Buildings','BUILDING_MONUMENT')]:
        assert tuple(d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone())==tuple(before[table]),'changed an unrelated native type'
    for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_BC_'+key,)).fetchone()[0]==value
    for path in V.rglob('*.lua'):
        for key in re.findall(r"B.Text\('([A-Z_]+)'",path.read_text(encoding='utf-8')):assert key in TEXT,key
    for key in re.findall(r"'(SIEGE_[A-Z_]+)'",(V/'Lua/BoundlessSiege.lua').read_text(encoding='utf-8')):assert key in TEXT,key
    for (atlas,index) in d.execute("SELECT IconAtlas,PortraitIndex FROM Civilizations WHERE Type='CIVILIZATION_BOUNDLESS_CITY' UNION ALL SELECT IconAtlas,PortraitIndex FROM Leaders WHERE Type='LEADER_BC_ARCHITECT' UNION ALL SELECT IconAtlas,PortraitIndex FROM Units WHERE Type='UNIT_BC_SURVEYOR' UNION ALL SELECT IconAtlas,PortraitIndex FROM Buildings WHERE Type LIKE 'BUILDING_BC_%'"):
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    for (name,) in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'BC_%'"):assert (V/'Art'/name).is_file(),name
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS actual BNW/CP SQL, complete Worker/Monument inheritance, starting Settler, UI localization and art references')

def syntax():
    lua=LuaRuntime();check=lua.eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')
    for path in [p for p in files() if p.suffix=='.lua']+list((R/'tools/tests').glob('*.lua')):check(path.read_text(encoding='utf-8'),str(path))
    print('PASS every Lua source parses under Lua 5.1')

def runtime():
    for test in ['boundless_assertions.lua','frontier_assertions.lua','ui_assertions.lua','workforce_stress.lua','completion_safety.lua','siege_safety.lua','stability_assertions.lua','ai_stability.lua','engine_completion.lua','dispatcher_contract.lua']:
        lua=LuaRuntime()
        def include(name):
            if name!='InstanceManager':lua.execute((V/'Lua'/f'{name}.lua').read_text(encoding='utf-8'))
        lua.globals().include=include
        lua.execute((R/'tools/tests/boundless_mock.lua').read_text(encoding='utf-8'))
        include('BoundlessCore')
        lua.globals().LoadWorkforceUI=lambda:lua.execute((V/'UI/BoundlessWorkforce.lua').read_text(encoding='utf-8'))
        started=time.perf_counter();lua.execute((R/'tools/tests'/test).read_text(encoding='utf-8'))
        print(f'PASS {test}: {time.perf_counter()-started:.3f}s (mock, not Civ V timing)')

def package():
    root=ET.parse(R/(NAME+'.modinfo')).getroot()
    assert root.get('id')==MOD_ID and root.get('version')==VERSION
    assert root.findtext('Properties/MinCompatibleSaveVersion')=='1'
    assert root.findtext('Properties/AffectsSavedGames')=='1'
    assert [(e.tag,e.get('id'),e.get('minversion'),e.get('title')) for e in root.find('Dependencies')]==DEPS
    actual={p.relative_to(R).as_posix():p for p in files()}
    declared={e.text:e for e in root.findall('Files/File')}
    vfs=Counter(p.name.casefold() for p in actual.values() if imported(p))
    assert not {name:count for name,count in vfs.items() if count>1},'Duplicate VFS basename would shadow a Lua include'
    assert set(actual)==set(declared),'manifest file mismatch'
    for name,p in actual.items():
        e=declared[name];assert e.get('md5')==hashlib.md5(p.read_bytes()).hexdigest().upper()
        assert e.get('import')==str(int(imported(p)))
        if p.suffix=='.xml':ET.parse(p)
        if p.suffix=='.dds':
            header=p.read_bytes()[:128];assert header[:4]==b'DDS ' and struct.unpack_from('<I',header,4)[0]==124
            from PIL import Image
            with Image.open(p) as im:im.load();assert im.width>0 and im.height>0
    assert [e.text for e in root.findall('Actions/OnModActivated/UpdateDatabase')]==sorted(n for n in actual if n.endswith('.sql'))
    assert [(e.get('file'),e.findtext('Name'),e.findtext('Description')) for e in root.findall('EntryPoints/EntryPoint')]==ENTRIES
    project=ET.parse(R/'CoolWackyCivs2.civ5proj').getroot();prefix='{'+NS+'}'
    assert project.findtext(prefix+'PropertyGroup/'+prefix+'ModVersion')==VERSION
    assert project.findtext(prefix+'PropertyGroup/'+prefix+'Guid')==MOD_ID
    assert {e.get('Include') for e in project.findall(prefix+'ItemGroup/'+prefix+'Content')}==set(actual)
    xml=ET.parse(V/'UI/BoundlessWorkforce.xml');ids={e.get('ID') for e in xml.iter() if e.get('ID')}
    refs=set(re.findall(r'Controls\.([A-Za-z_]+)',(V/'UI/BoundlessWorkforce.lua').read_text()))
    assert refs<=ids,refs-ids
    print('PASS manifest/project load order, MD5, VFS, UI controls, XML and all decoded DDS textures')

def coexist():
    old=R.parent/'CoolWackyCivs'
    manifests=list(old.glob('*.modinfo'))
    if not manifests:
        print('SKIP original-collection namespace audit: sibling repository unavailable');return
    current=ET.parse(R/(NAME+'.modinfo')).getroot()
    new_names={p.name.casefold() for p in files() if imported(p)}
    for manifest in manifests:
        prior=ET.parse(manifest).getroot()
        assert prior.get('id')!=current.get('id'),'shared mod UUID'
        old_names={Path(e.text).name.casefold() for e in prior.findall('Files/File') if e.get('import')=='1'}
        assert not new_names & old_names,('shared VFS basename',new_names & old_names)
    prior_sql='\n'.join(p.read_text(encoding='utf-8-sig') for p in old.rglob('*.sql'))
    new_sql='\n'.join(p.read_text(encoding='utf-8') for p in files() if p.suffix=='.sql')
    types=set(re.findall(r"'((?:[A-Z_]+_(?:BC|PIGEON)_[A-Z_0-9]+|CIVILIZATION_BOUNDLESS_CITY|(?:BC|PIGEON)_[A-Z_0-9]+))'",new_sql))
    for name in types:assert "'"+name+"'" not in prior_sql,('shared database namespace',name)
    prior_lua='\n'.join(p.read_text(encoding='utf-8-sig') for p in old.rglob('*.lua'))
    for name in ['MapModData.BoundlessCity','__BOUNDLESS_CITY_LOADED']:assert name not in prior_lua,('shared runtime namespace',name)
    print('PASS read-only original-collection audit: distinct UUID, VFS, globals and '+str(len(types))+' collection database identifiers')

if __name__=='__main__':
    sql();syntax();runtime();package();coexist()
    from validate_pigeons import validate
    validate()
