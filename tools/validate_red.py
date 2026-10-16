"""Actual-schema SQL, CP v151 source ABI and Lua 5.1 Red state-machine tests."""
from pathlib import Path
import re, struct, json
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import R,files

V=R/'TrainerRed'
TABLES=['Eras','Units','UnitPromotions','GameSpeeds','Buildings','BuildingClasses','UnitClasses','Unit_ClassUpgrades','Civilization_UnitClassOverrides','Civilizations','Projects']

def db():
 d=database()
 # Collection-wide SQL order, against one in-memory database.
 for path in files():
  if path.suffix=='.sql':d.executescript(path.read_text(encoding='utf-8'))
 return d

def sql(d):
 for table,typ in [('Civilizations','CIVILIZATION_RED_INDIGO_CHAMPION'),('Leaders','LEADER_RED_TRAINER'),('Units','UNIT_RED_POKEMON_ACE'),('Buildings','BUILDING_RED_POKEMON_CENTER'),('Buildings','BUILDING_RED_INDIGO_PLATEAU'),('Projects','PROJECT_RED_MT_SILVER')]:assert d.execute('SELECT 1 FROM '+table+' WHERE Type=?',(typ,)).fetchone(),typ
 assert tuple(d.execute("SELECT Moves,Class FROM Units WHERE Type='UNIT_RED_POKEMON_ACE'").fetchone())==(3,'UNITCLASS_GREAT_GENERAL')
 assert tuple(d.execute("SELECT GoldMaintenance,FoodKept,Airlift FROM Buildings WHERE Type='BUILDING_RED_POKEMON_CENTER'").fetchone())==(4,25,0)
 assert d.execute("SELECT Cost FROM Buildings WHERE Type='BUILDING_RED_POKEMON_CENTER'").fetchone()[0]==d.execute("SELECT Cost FROM Buildings WHERE Type='BUILDING_HOSPITAL'").fetchone()[0]
 assert d.execute("SELECT Cost FROM Projects WHERE Type='PROJECT_RED_MT_SILVER'").fetchone()[0]==int(d.execute("SELECT Cost FROM Buildings WHERE Type='BUILDING_STATUE_OF_LIBERTY'").fetchone()[0]*.65+.5)
 # Inherit all native General commands, roles, names and Citadel permissions.
 for table in ['Unit_Builds','Unit_AITypes','Unit_FreePromotions','Unit_UniqueNames']:
  fields=[r[1] for r in d.execute('PRAGMA table_info('+table+')') if r[1] not in ['ID','UnitType']]
  query='SELECT '+','.join(fields)+' FROM '+table+' WHERE UnitType=?'
  assert [tuple(r) for r in d.execute(query,('UNIT_RED_POKEMON_ACE',))]==[tuple(r) for r in d.execute(query,('UNIT_GREAT_GENERAL',))],table
 req=d.execute("SELECT * FROM Building_PrereqBuildingClasses WHERE BuildingType='BUILDING_RED_INDIGO_PLATEAU'").fetchall()
 assert any(r['BuildingClassType']=='BUILDINGCLASS_BARRACKS' for r in req),'Heroic Epic national prerequisites'
 known={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
 for path in (V/'SQL').glob('*.sql'):
  for key in set(re.findall(r"'(TXT_KEY_RED_[A-Z0-9_]+)'",path.read_text(encoding='utf-8'))):assert key in known,key
 for table,column,target in [('Civilization_UnitClassOverrides','UnitType','Units'),('Civilization_BuildingClassOverrides','BuildingType','Buildings'),('Unit_FreePromotions','PromotionType','UnitPromotions')]:
  for row in d.execute(f"SELECT {column} FROM {table} WHERE {column} LIKE '%RED_%'"):
   assert d.execute('SELECT 1 FROM '+target+' WHERE Type=?',(row[0],)).fetchone(),tuple(row)
 # Every visible object has a registered, in-bounds icon and English help.
 for table in ['Civilizations','Leaders','Buildings','Units','Projects','UnitPromotions']:
  for row in d.execute('SELECT * FROM '+table+" WHERE Type GLOB '*_RED_*'"):
   atlas=d.execute('SELECT IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas=? LIMIT 1',(row['IconAtlas'],)).fetchone()
   assert atlas and int(row['PortraitIndex'])<int(atlas[0])*int(atlas[1]),(table,row['Type'])
 print('PASS Red SQL: replacements, native inheritance, national prerequisites, project baseline, art references and localization')

def standalone():
 d=database()
 for row in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
  if '_JFD_' in row[0] or row[0] in ['Leader_SharedTraits','Civilization_FreePolicies','Civilization_DisableTechs']:
   d.execute('DROP TABLE '+quote(row[0]))
 for path in files():
  if path.suffix=='.sql':d.executescript(path.read_text(encoding='utf-8'))
 assert d.execute("SELECT AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_RED_INDIGO_CHAMPION'").fetchone()[0]==1
 print('PASS collection SQL without optional third-party metadata tables; guarded legacy inheritance')

def source_audit():
 ref=R/'tools/reference'
 sources={p.stem:p.read_text(encoding='utf-8-sig') for p in ref.glob('*.cpp')}
 # Check every method invoked on a known native object; no undocumented shims.
 bindings={kind:set(re.findall(r'Method\(\s*(\w+)\s*\)',sources['CvLua'+kind])) for kind in ['Unit','Player','City','Plot']}
 unions=set.union(*bindings.values())
 ignored={'Add','SetUpdate','ClearUpdate','SetText','SetHide','SetDisabled','SetSizeX','SetToolTipString','RegisterCallback','CalculateSize','ReprocessAnchoring','CalculateInternalSize','LookUpControl','IsHidden','ResetInstances','GetInstance','SetInputHandler','new'}
 used=set()
 for path in V.rglob('*.lua'):
  for name in re.findall(r':([A-Z]\w+)\(',path.read_text(encoding='utf-8')):
   if name not in ignored:assert name in unions,('Unverified native Lua method',name,path);used.add(name)
 h=(ref/'CustomMods.h').read_text(encoding='utf-8-sig')
 for name,signature in {'BattleStarted':'iii','BattleJoined':'iiib','BattleFinished':'','BattleDamageDelta':'ii','UnitUpgraded':'iiib','UnitConverted':'iiiib','CityProjectComplete':'iii','BarbariansCampCleared':'iii','UnitCreated':'iiiii','UnitPrekill':'iiiiibi','PlayerDoneTurn':'i'}.items():
  assert re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+signature+'"',h),(name,signature)
 structs=sources.get('CvGameCoreStructs','')
 assert 'GAMEEVENT_BattleDamageDelta, unitType, iDamage' in structs
 assert 'BATTLE_JOINED(unit, unitType, false)' in structs
 assert 'm_pUnits[unitType]->GetCurrHitPoints() - iDamage' in structs,'source-HP positive-delta clamp workaround'
 assert 'GAMEEVENT_BarbariansCampCleared, pPlot->getX(), pPlot->getY(), ePlayer' in sources['CvBarbarians']
 assert sources['CvUnit'].index('GAMEEVENT_UnitConverted')<sources['CvUnit'].index('pUnit->kill(true, NO_PLAYER)',sources['CvUnit'].index('GAMEEVENT_UnitConverted'))
 print('PASS Red CP v151: '+str(len(used))+' native method names, event ABIs, damage role semantics and pre-death conversion order')

def table(lua,values):
 if isinstance(values,dict):return lua.table_from({k:table(lua,v) for k,v in values.items()})
 if isinstance(values,list):return lua.table_from([table(lua,v) for v in values])
 return values

def runtime(d):
 data={t:[dict(r) for r in d.execute('SELECT * FROM '+t)] for t in TABLES}
 for test in ['red_scenarios.lua','red_edge_cases.lua','red_abilities.lua','red_ui.lua']:
  lua=LuaRuntime(unpack_returned_tuples=True)
  lua.globals().RED_DATABASE=table(lua,data)
  def include(name):
   if name in ['IconSupport','InstanceManager']:return
   paths=list(V.rglob(name+'.lua'));assert len(paths)==1,name
   lua.execute(paths[0].read_text(encoding='utf-8'))
  lua.globals().include=include
  lua.execute((R/'tools/tests/red_mock.lua').read_text(encoding='utf-8'))
  include('RED_Core')
  lua.globals().TEST.LoadPanel=lambda:lua.execute((V/'UI/RED_TeamPanel.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests'/test).read_text(encoding='utf-8'))
 print('PASS Red Lua 5.1 simulations (mock engine; not native Civ V gameplay)')
 return lua

def art(d):
 paths={p.name:p for p in (V/'Art').glob('*')}
 for row in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'RED_%'"):
  assert row[0] in paths,row[0]
 for path in paths.values():
  if path.suffix=='.dds':
   raw=path.read_bytes();assert raw[:4]==b'DDS '
   assert struct.unpack_from('<I',raw,28)[0]>1,('missing mipmaps',path)
   with Image.open(path) as im:im.load();assert im.getbbox()
  elif path.suffix=='.xml':ET.parse(path)
 print('PASS Red DDS decode, complete mip chains, scene XML and referenced atlas files')

def validate():
 d=db();sql(d);standalone();source_audit()
 lua=LuaRuntime()
 for path in V.rglob('*.lua'):lua.execute('assert(loadstring(...))',path.read_text(encoding='utf-8'))
 runtime(d);art(d)

def fetch():
 import urllib.request
 from audit_cp import BASE
 for name in ['CvGameCoreStructs.cpp','CvBarbarians.cpp']:
  (R/'tools/reference'/name).write_bytes(urllib.request.urlopen(BASE+name,timeout=30).read())
 print('Fetched supplemental official v151 combat/camp sources')

if __name__=='__main__':
 import sys
 if '--fetch' in sys.argv:fetch()
 validate()
