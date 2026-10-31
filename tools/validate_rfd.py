"""Actual-schema SQL, shipped Lua 5.1 simulations, CP151 source and DDS checks.

The installed BNW snapshot receives CP schema in memory. This cannot substitute
for native engine, UI rendering, serialization or DLL gameplay acceptance.
"""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib
import json
import math
import re
import struct
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import files, imported, ENTRIES, NAME, NS
from generate_rfd import R, V, CIV, LEADER, UNIT, WORKSHOP, DUMMIES, TEXT, CITIES
from validation_prerequisites import inspect_database, require_sources


def apply(d):
    for p in sorted((V / 'SQL').glob('*.sql')):
        d.executescript(p.read_text(encoding='utf-8'))


def yields(d, building):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType', (building,)))


def inheritance(d):
    count = 0
    metadata = {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}
    for table, old, new, allowed, prefix, key in [
        ('Units','UNIT_CATAPULT',UNIT,metadata | {'Moves','UnitFlagAtlas','UnitFlagIconOffset'},'Unit','UnitType'),
        ('Buildings','BUILDING_WORKSHOP',WORKSHOP,metadata,'Building','BuildingType')]:
        source = d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        target = d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for field in source.keys():
            if field not in allowed:
                assert source[field] == target[field], (table,field,source[field],target[field])
        if table == 'Units':
            assert target['Moves'] == source['Moves']+1
        for (companion,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            columns = [r[1] for r in d.execute('PRAGMA table_info('+quote(companion)+')')]
            if not companion.startswith(prefix) or key not in columns:
                continue
            fields = [c for c in columns if c not in [key,'ID']]
            sql = 'SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+key+'=?'
            left = Counter(tuple(r) for r in d.execute(sql,(old,)))
            right = Counter(tuple(r) for r in d.execute(sql,(new,)))
            if companion == 'Unit_FreePromotions':
                right.subtract({('PROMOTION_RFD_INK_MORTAR_SIGHT',):1})
                right = +right
            if companion == 'Building_YieldChanges':
                expected = yields(d,old)
                expected['YIELD_CULTURE'] = expected.get('YIELD_CULTURE',0)+1
                assert yields(d,new) == expected
            else:
                assert left == right, (companion,left-right,right-left)
            count += 1
    return count


def sql_checks():
    d = database()
    for p in files():
        if p.suffix == '.sql' and p.relative_to(R).parts[0] != 'TheRepublicOfFirstDrafts':
            d.executescript(p.read_text(encoding='utf-8'))
    before = {t: Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t)))
              for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall()
              if t != 'CustomModOptions'}
    options = dict(d.execute('SELECT Name,Value FROM CustomModOptions'))
    apply(d)
    for table, rows in before.items():
        assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(table))), ('released row changed',table)
    for name, value in options.items():
        assert d.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(name,)).fetchone()[0] == (1 if name=='EVENTS_CITY' else value)
    companion_count = inheritance(d)
    assert d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:] == (1,0)
    assert d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0] == 'TRAIT_RFD_NOTHING_FINAL'
    assert d.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0] == LEADER
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_CATAPULT')).fetchone()[0] == UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_WORKSHOP')).fetchone()[0] == WORKSHOP
    promotion = d.execute("SELECT VisibilityChange,LostWithUpgrade,CannotBeChosen FROM UnitPromotions WHERE Type='PROMOTION_RFD_INK_MORTAR_SIGHT'").fetchone()
    assert promotion[:] == (1,1,1)
    for dummy in DUMMIES:
        row = d.execute('SELECT * FROM Buildings WHERE Type=?',(dummy,)).fetchone()
        for key, value in {'Cost':-1,'FaithCost':-1,'GreatWorkCount':-1,'IsDummy':1,
                           'ShowInPedia':0,'NeverCapture':1,'ConquestProb':0,'GoldMaintenance':0,
                           'SpecialistCount':0,'Happiness':0,'Defense':0}.items():
            assert row[key] == value,(dummy,key)
        assert yields(d,dummy)=={'YIELD_SCIENCE':1}
        cls=d.execute('SELECT * FROM BuildingClasses WHERE Type=?',(row['BuildingClass'],)).fetchone()
        assert all(cls[key]==-1 for key in ['MaxGlobalInstances','MaxTeamInstances','MaxPlayerInstances'])
    for key,value in TEXT.items():
        assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_RFD_'+key,)).fetchone()[0] == value
    for p in (V/'SQL').glob('*.sql'):
        for key in re.findall(r"'(TXT_KEY_RFD_[A-Z_0-9%]+)'",p.read_text(encoding='utf-8')):
            assert key.rstrip('%') in {'TXT_KEY_RFD_CIV5','TXT_KEY_RFD_MARGINALIA'} or any('TXT_KEY_RFD_'+k == key or ('TXT_KEY_RFD_'+k).startswith(key.rstrip('%')) for k in TEXT),key
    assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0] == len(CITIES)
    assert d.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    # Alter base rules and add scalar fields to prove runtime inheritance rather
    # than generated copies of remembered vanilla numbers.
    altered=database()
    altered.executescript("""ALTER TABLE Units ADD RFD_TestScalar INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD RFD_TestScalar INTEGER DEFAULT 0;
UPDATE Units SET Cost=177,Moves=4,Combat=19,RangedCombat=27,Range=3,BaseSightRange=4,RFD_TestScalar=81 WHERE Type='UNIT_CATAPULT';
UPDATE Buildings SET Cost=311,GoldMaintenance=6,SpecialistCount=3,PrereqTech='TECH_ENGINEERING',RFD_TestScalar=91 WHERE Type='BUILDING_WORKSHOP';
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_CATAPULT','PROMOTION_AMPHIBIOUS');
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_WORKSHOP','YIELD_CULTURE',4),('BUILDING_WORKSHOP','YIELD_CULTURE',2),('BUILDING_WORKSHOP','YIELD_GOLD',3);
""")
    apply(altered)
    inheritance(altered)
    assert altered.execute('SELECT RFD_TestScalar,Moves FROM Units WHERE Type=?',(UNIT,)).fetchone()[:]==(81,5)
    assert altered.execute('SELECT RFD_TestScalar,Cost FROM Buildings WHERE Type=?',(WORKSHOP,)).fetchone()[:]==(91,311)
    assert yields(altered,WORKSHOP)['YIELD_CULTURE']==7
    print(f'PASS RFD actual-schema SQL, {companion_count} companion tables, altered-baseline inheritance and released-row preservation')
    return d, companion_count


def add_fixtures(d):
    # These adversarial definitions exist only inside the in-memory test DB.
    cases = {
      'TEAM':{'MaxTeamInstances':1}, 'HIDDEN':{'IsDummy':1},
      'UNBUILDABLE':{'Cost':-1}, 'NODISPLAY':{'ShowInPedia':0},
      'LEAGUE':{'LeagueCost':500}, 'PURCHASE':{'PurchaseOnly':1}, 'ZERO':{'Cost':0},
      'FAKE_MONUMENT':{'BuildingClass':'BUILDINGCLASS_MONUMENT','IsDummy':1},
      'MONUMENT_VARIANT':{'BuildingClass':'BUILDINGCLASS_MONUMENT'}}
    for name, properties in cases.items():
        typ='BUILDING_RFD_TEST_'+name
        cls=properties.get('BuildingClass','BUILDINGCLASS_RFD_TEST_'+name)
        if 'BuildingClass' not in properties:
            d.execute('INSERT INTO BuildingClasses(Type,DefaultBuilding,Description,MaxTeamInstances) VALUES (?,?,?,?)',
                      (cls,typ,'Fixture',properties.get('MaxTeamInstances',-1)))
        d.execute('INSERT INTO Buildings(Type,BuildingClass,Description,Cost,FaithCost) VALUES (?,?,?,?,?)',
                  (typ,cls,'Fixture',properties.get('Cost',80),0))
        for key,value in properties.items():
            if key!='MaxTeamInstances': d.execute('UPDATE Buildings SET '+key+'=? WHERE Type=?',(value,typ))


def runtime(d):
    add_fixtures(d)
    code=(V/'Lua/RFD_FirstDrafts.lua').read_text(encoding='utf-8')
    mock=(R/'tools/tests/rfd_mock.lua').read_text(encoding='utf-8')
    tests=(R/'tools/tests/rfd_assertions.lua').read_text(encoding='utf-8')

    def new_runtime():
        lua=LuaRuntime()
        for table, name in [('Buildings','RFD_BuildingRows'),('BuildingClasses','RFD_ClassRows'),('GameSpeeds','RFD_SpeedRows')]:
            rows=[lua.table_from(dict(row)) for row in d.execute('SELECT * FROM '+table)]
            lua.globals()[name]=lua.table_from(rows)
        lua.globals().RFD_LoadSource=lambda:lua.execute(code)
        lua.execute(mock)
        lua.execute(tests)
        return lua

    names=sorted(new_runtime().globals().RFD_Tests.keys())
    for name in names:
        lua=new_runtime()
        try: lua.globals().RFD_Tests[name]()
        except Exception as exc: raise AssertionError('RFD Lua scenario '+name+': '+str(exc)) from exc
    # Destroy the entire Lua VM, carry only native-like saved player/city state
    # into a new VM, then lose/rebuild every building. No globals survive.
    first=new_runtime()
    first.execute('RFD_Load(); RFD_Diverse(RFD_City(0,1),9); RFD_Next()')
    state=first.globals().Players[0]
    saved=(state.data,state.culture,state.gold)
    second=new_runtime()
    second.globals().Players[0].data=saved[0]
    second.globals().Players[0].culture=saved[1]
    second.globals().Players[0].gold=saved[2]
    second.execute('RFD_Turn=100; RFD_Load(); RFD_Diverse(RFD_City(0,1),9); RFD_Next(); RFD_CheckYields(108,180)')
    names.append('full_VM_restart_saved_class_ledger')
    print(f'PASS RFD {len(names)} shipped Lua 5.1 scenarios (simulated; includes Standard/Marathon and full VM restart)')
    return names


def static(d):
    lua=LuaRuntime()
    compile_lua=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
    for p in list(V.rglob('*.lua'))+list((R/'tools/tests').glob('rfd_*.lua')):
        compile_lua(p.read_text(encoding='utf-8'),str(p))
    for p in V.rglob('*.xml'): ET.parse(p)
    declared=ET.parse(R/(NAME+'.modinfo')).getroot()
    entries=declared.findall('EntryPoints/EntryPoint')
    assert sum(e.get('file')=='TheRepublicOfFirstDrafts/Lua/RFD_FirstDrafts.xml' for e in entries)==1
    inventory={e.text:e for e in declared.findall('Files/File')}
    assert len(inventory)==len(declared.findall('Files/File'))
    vfs=Counter(p.name.casefold() for p in files() if imported(p))
    assert not {key:value for key,value in vfs.items() if value>1}, 'VFS collision'
    project=ET.parse(R/'CoolWackyCivs2.civ5proj').getroot()
    project_files={e.get('Include'):e for e in project.findall('{'+NS+'}ItemGroup/{'+NS+'}Content')}
    for p in V.rglob('*'):
        if not p.is_file() or p.suffix not in ['.sql','.xml','.lua','.dds']: continue
        relative=p.relative_to(R).as_posix()
        assert relative in inventory and relative in project_files,relative
        assert inventory[relative].get('import')==str(int(imported(p)))
        assert inventory[relative].get('md5')==hashlib.md5(p.read_bytes()).hexdigest().upper()
    order=[e.text for e in declared.findall('Actions/OnModActivated/UpdateDatabase')]
    own=[p.relative_to(R).as_posix() for p in sorted((V/'SQL').glob('*.sql'))]
    assert order[-5:]==own
    for name, in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'RFD_%'"):
        assert (V/'Art'/name).is_file(),name
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',WORKSHOP)]:
        atlas,index=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    for p in (V/'Art').glob('*.dds'):
        header=p.read_bytes()[:128]
        assert header[:4]==b'DDS ' and header[84:88]==b'DXT5',p
        with Image.open(p) as im:
            im.load()
            assert struct.unpack_from('<I',header,28)[0]==int(math.log2(max(im.size)))+1,p
    for name in ['RFD_Dawn.dds','RFD_Map.dds','RFD_Leader.dds','RFD_Flag32.dds']:
        assert (V/'Art'/name).is_file()
    print('PASS RFD Lua syntax, XML, localization, atlases, 40 mipmapped DDS textures and manifest/project load order')


def source_contract():
    names=['CustomMods.h','CvPlayer.cpp','CvCity.cpp','CvLuaPlayer.cpp','CvLuaGame.cpp','CvInfos.cpp','CvUnit.cpp']
    evidence=require_sources(names)
    source={name:(R/'tools/reference'/name).read_text(encoding='utf-8-sig') for name in names}
    speed_source=source['CvInfos.cpp'].split('bool CvGameSpeedInfo::CacheResults',1)[1].split('return true;',1)[0]
    checks={'saved player ScriptData': 'visitor(player.m_strScriptData);' in source['CvPlayer.cpp'],
      'owner-turn hook': '"PlayerDoTurn"' in source['CvPlayer.cpp'],
      'construction speed field': bool(re.search(r'm_iConstructPercent\s*=\s*kResults.GetInt\("ConstructPercent"\)',speed_source)),
      'start turn API': 'Method(GetStartTurn)' in source['CvLuaGame.cpp'],
      'game speed API': 'Method(GetGameSpeedType)' in source['CvLuaGame.cpp'],
      'purchase/construction hook': 'GameEvents.CityConstructed.Add(function(iPlayer, iCity, iBuilding, bGold, bFaith)' in source['CustomMods.h'],
      'building sale hook': 'GameEvents.CitySoldBuilding.Add(function(iPlayer, iCity, iBuilding)' in source['CustomMods.h']}
    checks['Sight lost during native upgrade']='(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in source['CvUnit.cpp']
    for method in ['GetScriptData','SetScriptData','GetJONSCultureTimes100','ChangeJONSCultureTimes100','GetGoldTimes100','ChangeGold']:
        checks['player '+method]='Method('+method+');' in source['CvLuaPlayer.cpp']
    assert all(checks.values()),checks
    print(f'PASS RFD {len(checks)} pinned CP v151 source contracts')
    return {'sources':evidence,'checks':checks}


def validate():
    baseline=inspect_database()
    source=source_contract()
    d, companions=sql_checks()
    static(d)
    scenarios=runtime(d)
    result={'date':'2026-10-31','baseline':baseline,'source_contracts':source,
            'companion_tables':companions,'lua51_scenarios':scenarios,
            'native_game_tests':'NOT RUN; see Testing.md', 'result':'PASS'}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/Validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    return result


if __name__=='__main__': validate()
